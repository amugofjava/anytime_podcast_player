// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/analysis/background/ad_segment_chunk_merger.dart';
import 'package:anytime/services/analysis/background/background_analysis_progress.dart';
import 'package:anytime/services/analysis/background/background_analysis_service.dart';
import 'package:anytime/services/analysis/background/gemma_ad_analyzer.dart';
import 'package:anytime/services/analysis/background/transcript_chunker.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:logging/logging.dart';

/// Checkpoint token written after the transcribe stage completes. Spec §4.4
/// uses `transcribe` and `analyze` as the named stages; we record a completion
/// marker for the former so the next run can skip straight to analyze.
const String checkpointTranscribeComplete = 'transcribe';

/// Orchestrates one pass of the background path for one episode:
/// transcribe (via the injected `EpisodeTranscriptionService`) → chunk →
/// analyze (via the injected `GemmaAdAnalyzer`) → merge → commit.
///
/// Stateless between calls — all per-episode state lives in the repository
/// (transcript row + checkpoint store), which is what makes AC-004 resumption
/// possible across process restarts.
class BackgroundAnalysisWorker {
  final Repository _repository;
  final EpisodeTranscriptionService _transcriptionService;
  final GemmaAdAnalyzer _gemmaAnalyzer;
  final DefaultBackgroundAnalysisService _service;
  final String _modelId;
  final DateTime Function() _now;
  final _log = Logger('BackgroundAnalysisWorker');

  BackgroundAnalysisWorker({
    required Repository repository,
    required EpisodeTranscriptionService transcriptionService,
    required GemmaAdAnalyzer gemmaAnalyzer,
    required DefaultBackgroundAnalysisService service,
    required String modelId,
    DateTime Function()? clock,
  })  : _repository = repository,
        _transcriptionService = transcriptionService,
        _gemmaAnalyzer = gemmaAnalyzer,
        _service = service,
        _modelId = modelId,
        _now = clock ?? DateTime.now;

  /// Picks the next queued episode and runs it to completion. Returns the
  /// episode id that was processed, or `null` if the queue was empty.
  ///
  /// Failures are caught and reported as `BackgroundAnalysisStage.failed`; the
  /// episode remains queued and any checkpoint is preserved so the next
  /// invocation resumes at the interrupted stage (AC-004, AC-009).
  Future<String?> runNext() async {
    final queue = await _repository.listBackgroundAnalysisQueue();
    if (queue.isEmpty) {
      return null;
    }

    final episodeId = queue.first;
    await runOne(episodeId);
    return episodeId;
  }

  /// Runs the pipeline for [episodeId]. Callers who catch failures can inspect
  /// progress events via `service.progress()`.
  Future<void> runOne(String episodeId) async {
    final episode = await _repository.findEpisodeByGuid(episodeId);
    if (episode == null) {
      _log.fine('Dequeuing $episodeId: episode no longer exists');
      await _repository.dequeueBackgroundAnalysis(episodeId);
      await _repository.clearBackgroundAnalysisCheckpoint(episodeId);
      return;
    }

    try {
      final transcript = await _ensureTranscript(episode);
      final segments = await _analyze(episodeId: episodeId, transcript: transcript);
      await _commit(episodeId: episodeId, segments: segments);

      await _repository.clearBackgroundAnalysisCheckpoint(episodeId);
      await _repository.dequeueBackgroundAnalysis(episodeId);

      _service.reportProgress(BackgroundAnalysisProgress(
        episodeId: episodeId,
        stage: BackgroundAnalysisStage.completed,
      ));
    } catch (error, stack) {
      _log.warning('Background analysis failed for $episodeId: $error', error, stack);
      _service.reportProgress(BackgroundAnalysisProgress(
        episodeId: episodeId,
        stage: BackgroundAnalysisStage.failed,
        message: error.toString(),
      ));
    }
  }

  Future<Transcript> _ensureTranscript(Episode episode) async {
    final checkpoint = await _repository.findBackgroundAnalysisCheckpoint(episode.guid);
    if (checkpoint == checkpointTranscribeComplete) {
      final existing = await _loadExistingTranscript(episode);
      if (existing != null) {
        _log.fine('Resuming ${episode.guid} at analyze stage');
        return existing;
      }
      // Checkpoint without transcript means stale state — fall through to
      // re-transcribe rather than failing.
      await _repository.clearBackgroundAnalysisCheckpoint(episode.guid);
    }

    _service.reportProgress(BackgroundAnalysisProgress(
      episodeId: episode.guid,
      stage: BackgroundAnalysisStage.transcribing,
    ));

    final transcript = await _transcriptionService.transcribeDownloadedEpisode(
      episode: episode,
      onProgress: (p) => _service.reportProgress(BackgroundAnalysisProgress(
        episodeId: episode.guid,
        stage: _mapTranscriptionStage(p.stage),
        fraction: p.progress,
        message: p.message,
      )),
    );

    final saved = await _repository.saveTranscript(transcript);
    episode.transcriptId = saved.id;
    await _repository.saveEpisode(episode);

    await _repository.recordBackgroundAnalysisCheckpoint(
      episode.guid,
      checkpointTranscribeComplete,
    );

    return saved;
  }

  Future<Transcript?> _loadExistingTranscript(Episode episode) async {
    final id = episode.transcriptId;
    if (id == null || id <= 0) {
      return null;
    }
    return _repository.findTranscriptById(id);
  }

  Future<List<AdSegment>> _analyze({
    required String episodeId,
    required Transcript transcript,
  }) async {
    _service.reportProgress(BackgroundAnalysisProgress(
      episodeId: episodeId,
      stage: BackgroundAnalysisStage.analyzing,
    ));

    final chunks = TranscriptChunker.chunk(transcript.subtitles);
    if (chunks.isEmpty) {
      return const <AdSegment>[];
    }

    final raw = <AdSegment>[];
    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final segments = await _gemmaAnalyzer.analyzeChunk(chunk: chunk, modelId: _modelId);
      raw.addAll(segments);

      _service.reportProgress(BackgroundAnalysisProgress(
        episodeId: episodeId,
        stage: BackgroundAnalysisStage.analyzing,
        fraction: (i + 1) / chunks.length,
      ));
    }

    return AdSegmentChunkMerger.merge(raw);
  }

  Future<void> _commit({
    required String episodeId,
    required List<AdSegment> segments,
  }) async {
    final record = EpisodeAnalysisRecord(
      provider: AnalysisProvider.whisperGemma4,
      modelId: _modelId,
      completedAtMs: _now().millisecondsSinceEpoch,
      adSegments: segments,
      active: false,
      status: 'ok',
    );

    await _service.commitResult(episodeId: episodeId, record: record);
  }

  BackgroundAnalysisStage _mapTranscriptionStage(EpisodeTranscriptionStage stage) {
    switch (stage) {
      case EpisodeTranscriptionStage.downloadingModel:
        return BackgroundAnalysisStage.downloadingModel;
      case EpisodeTranscriptionStage.preparing:
      case EpisodeTranscriptionStage.uploading:
      case EpisodeTranscriptionStage.transcribing:
        return BackgroundAnalysisStage.transcribing;
      case EpisodeTranscriptionStage.completed:
        return BackgroundAnalysisStage.transcribing;
    }
  }
}
