// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/analysis/background/background_analysis_progress.dart';
import 'package:anytime/services/analysis/background/background_analysis_service.dart';
import 'package:anytime/services/analysis/background/background_analysis_worker.dart';
import 'package:anytime/services/analysis/background/gemma_ad_analyzer.dart';
import 'package:anytime/services/analysis/background/transcript_chunker.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../mocks/mock_path_provider.dart';

class _FakeTranscriptionService implements EpisodeTranscriptionService {
  int callCount = 0;
  Transcript Function(Episode episode)? onTranscribe;
  Object? throwError;

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    callCount++;
    if (throwError != null) {
      throw throwError!;
    }
    onProgress?.call(const EpisodeTranscriptionProgress(
      stage: EpisodeTranscriptionStage.transcribing,
      message: 'Transcribing...',
      progress: 0.5,
    ));
    return (onTranscribe ?? _defaultTranscribe)(episode);
  }

  Transcript _defaultTranscribe(Episode episode) {
    return Transcript(
      guid: episode.guid,
      subtitles: <Subtitle>[
        Subtitle(index: 1, start: const Duration(seconds: 0), end: const Duration(seconds: 30), data: 'first line'),
        Subtitle(index: 2, start: const Duration(seconds: 30), end: const Duration(seconds: 60), data: 'second line'),
      ],
      provenance: TranscriptProvenance.localAi,
      provider: 'whisper',
    );
  }
}

class _FakeGemmaAnalyzer implements GemmaAdAnalyzer {
  int callCount = 0;
  List<AdSegment> Function(TranscriptChunk chunk)? onAnalyze;
  Object? throwError;

  @override
  Future<List<AdSegment>> analyzeChunk({
    required TranscriptChunk chunk,
    required String modelId,
  }) async {
    callCount++;
    if (throwError != null) {
      throw throwError!;
    }
    return (onAnalyze ?? _defaultAnalyze)(chunk);
  }

  List<AdSegment> _defaultAnalyze(TranscriptChunk chunk) {
    return const <AdSegment>[
      AdSegment(startMs: 0, endMs: 20_000, reason: 'preroll'),
    ];
  }

  @override
  Future<void> close() async {}
}

void main() {
  const dbName = 'anytime-bg-worker-test.db';
  SembastRepository? repository;
  DefaultBackgroundAnalysisService? service;
  _FakeTranscriptionService? transcriber;
  _FakeGemmaAnalyzer? analyzer;
  BackgroundAnalysisWorker? worker;
  var nowMs = 1_714_000_000_000;

  setUp(() async {
    PathProviderPlatform.instance = MockPathProvder();
    repository = SembastRepository(cleanup: false, databaseName: dbName);
    service = DefaultBackgroundAnalysisService(repository!);
    transcriber = _FakeTranscriptionService();
    analyzer = _FakeGemmaAnalyzer();
    worker = BackgroundAnalysisWorker(
      repository: repository!,
      transcriptionService: transcriber!,
      gemmaAnalyzer: analyzer!,
      service: service!,
      modelId: 'gemma-4-e2b',
      clock: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
    );
  });

  tearDown(() async {
    await service!.dispose();
    await repository!.close();
    worker = null;
    analyzer = null;
    transcriber = null;
    service = null;
    repository = null;

    final f = File('${Directory.systemTemp.path}/$dbName');
    if (f.existsSync()) {
      f.deleteSync();
    }
  });

  Future<Episode> seedEpisode(String guid) async {
    final episode = Episode(
      guid: guid,
      pguid: 'POD',
      podcast: 'Podcast',
      title: 'Worker test $guid',
    );
    return repository!.saveEpisode(episode);
  }

  group('runNext', () {
    test('returns null on empty queue', () async {
      expect(await worker!.runNext(), isNull);
    });

    test('picks the first queued episode and runs it', () async {
      await seedEpisode('EP-A');
      await seedEpisode('EP-B');
      await service!.enqueue('EP-A');
      await service!.enqueue('EP-B');

      final processed = await worker!.runNext();

      expect(processed, 'EP-A');
      expect(await service!.listQueued(), ['EP-B']);
    });
  });

  group('runOne happy path', () {
    test('transcribes, analyzes, commits an active whisper+gemma4 record', () async {
      await seedEpisode('EP-1');
      await service!.enqueue('EP-1');

      await worker!.runOne('EP-1');

      expect(transcriber!.callCount, 1);
      expect(analyzer!.callCount, 1);

      final history = await repository!.findAnalysisHistory('EP-1');
      expect(history, hasLength(1));
      expect(history.single.provider, AnalysisProvider.whisperGemma4);
      expect(history.single.active, isTrue);
      expect(history.single.modelId, 'gemma-4-e2b');
      expect(history.single.completedAtMs, nowMs);
      expect(history.single.adSegments, hasLength(1));

      final episode = await repository!.findEpisodeByGuid('EP-1');
      expect(episode!.adSegments, hasLength(1));
      expect(episode.adSegments.single.reason, 'preroll');
      expect(episode.transcriptId, isNotNull);
      expect(episode.transcriptId! > 0, isTrue);

      expect(await service!.listQueued(), isEmpty);
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-1'), isNull);
    });

    test('publishes queued/transcribing/analyzing/completed progress events', () async {
      await seedEpisode('EP-2');
      final received = <BackgroundAnalysisStage>[];
      final sub = service!.progress().listen((p) {
        if (p.episodeId == 'EP-2') received.add(p.stage);
      });

      await service!.enqueue('EP-2');
      await worker!.runOne('EP-2');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, containsAllInOrder(<BackgroundAnalysisStage>[
        BackgroundAnalysisStage.queued,
        BackgroundAnalysisStage.transcribing,
        BackgroundAnalysisStage.analyzing,
        BackgroundAnalysisStage.completed,
      ]));
    });
  });

  group('AC-004 resumption', () {
    test('with transcribe checkpoint and existing transcript, skips Whisper', () async {
      final episode = await seedEpisode('EP-R1');

      final transcript = await repository!.saveTranscript(Transcript(
        guid: 'EP-R1',
        subtitles: <Subtitle>[
          Subtitle(index: 1, start: const Duration(seconds: 0), end: const Duration(seconds: 45), data: 'persisted'),
        ],
        provenance: TranscriptProvenance.localAi,
        provider: 'whisper',
      ));
      episode.transcriptId = transcript.id;
      await repository!.saveEpisode(episode);

      await repository!.recordBackgroundAnalysisCheckpoint('EP-R1', checkpointTranscribeComplete);
      await service!.enqueue('EP-R1');

      await worker!.runOne('EP-R1');

      expect(transcriber!.callCount, 0, reason: 'transcribe stage skipped on resume');
      expect(analyzer!.callCount, 1);
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-R1'), isNull);
      expect(await service!.listQueued(), isEmpty);
    });

    test('stale checkpoint without transcript falls back to re-transcribe', () async {
      await seedEpisode('EP-R2');
      await repository!.recordBackgroundAnalysisCheckpoint('EP-R2', checkpointTranscribeComplete);
      await service!.enqueue('EP-R2');

      await worker!.runOne('EP-R2');

      expect(transcriber!.callCount, 1, reason: 'no transcript on disk ⇒ must re-transcribe');
      expect(analyzer!.callCount, 1);
      expect(await service!.listQueued(), isEmpty);
    });
  });

  group('failure handling (AC-009)', () {
    test('analyze failure preserves queue, checkpoint, and emits failed', () async {
      await seedEpisode('EP-F1');
      await service!.enqueue('EP-F1');
      analyzer!.throwError = const GemmaAdAnalyzerException('malformed');

      final received = <BackgroundAnalysisProgress>[];
      final sub = service!.progress().listen((p) {
        if (p.episodeId == 'EP-F1') received.add(p);
      });

      await worker!.runOne('EP-F1');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received.any((p) => p.stage == BackgroundAnalysisStage.failed), isTrue);
      expect(await service!.listQueued(), ['EP-F1'], reason: 'remains queued for retry');
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-F1'), checkpointTranscribeComplete,
          reason: 'checkpoint preserved so next run resumes at analyze');
      expect(await repository!.findAnalysisHistory('EP-F1'), isEmpty);

      final episode = await repository!.findEpisodeByGuid('EP-F1');
      expect(episode!.adSegments, isEmpty, reason: 'no partial ad segments persisted');
    });

    test('transcribe failure preserves queue, records no checkpoint, emits failed', () async {
      await seedEpisode('EP-F2');
      await service!.enqueue('EP-F2');
      transcriber!.throwError = const EpisodeTranscriptionException('boom');

      await worker!.runOne('EP-F2');

      expect(analyzer!.callCount, 0);
      expect(await service!.listQueued(), ['EP-F2']);
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-F2'), isNull);
      expect(await repository!.findAnalysisHistory('EP-F2'), isEmpty);
    });
  });

  group('edge cases', () {
    test('missing episode row dequeues and clears any checkpoint', () async {
      await service!.enqueue('EP-GONE');
      await repository!.recordBackgroundAnalysisCheckpoint('EP-GONE', checkpointTranscribeComplete);

      await worker!.runOne('EP-GONE');

      expect(transcriber!.callCount, 0);
      expect(analyzer!.callCount, 0);
      expect(await service!.listQueued(), isEmpty);
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-GONE'), isNull);
    });
  });
}
