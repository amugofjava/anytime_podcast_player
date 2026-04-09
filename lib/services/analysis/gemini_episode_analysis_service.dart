// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/core/utils.dart' as utils;
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/analysis/ad_segment_normalizer.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Single-step, audio-native ad segment detection using the Gemini API.
///
/// Instead of the two-step approach (transcribe → analyze transcript), this
/// service chunks the episode audio into ~5-minute MP3 segments, sends each
/// chunk directly to Gemini as audio + prompt, collects JSON responses with
/// chunk-relative timestamps, offsets them back to episode-absolute time,
/// merges adjacent segments, and filters short false positives.
class GeminiEpisodeAnalysisService implements EpisodeAnalysisService {
  static const jobIdPrefix = 'gemini:';
  static const _chunkDurationSeconds = 300;
  static const _mergeGapMs = 5000;
  static const _minSegmentDurationMs = 10000;
  static const _reevaluationThresholdMs = 90 * 1000;
  static const _requestTimeout = Duration(seconds: 120);
  static const _chunkAudioBitrateKbps = 64;

  final _log = Logger('GeminiEpisodeAnalysisService');
  final SecureSecretsService secureSecretsService;
  final http.Client _client;
  final bool _ownsClient;
  final String _defaultModel;
  final String Function()? _modelResolver;
  final Map<String, _GeminiAnalysisJob> _jobs = <String, _GeminiAnalysisJob>{};

  GeminiEpisodeAnalysisService({
    required this.secureSecretsService,
    http.Client? client,
    String model = 'gemini-3.1-flash-lite-preview',
    String Function()? modelResolver,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _defaultModel = model,
        _modelResolver = modelResolver;

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    if (!episode.downloaded || episode.filepath == null || episode.filepath!.isEmpty) {
      throw StateError('Episode must be downloaded for Gemini audio analysis.');
    }

    final resolvedPath = await utils.resolvePath(episode);
    final audioFile = File(resolvedPath);
    _log.info('Gemini submit: resolvedPath=$resolvedPath exists=${audioFile.existsSync()}');
    if (!audioFile.existsSync()) {
      throw StateError('Downloaded episode file not found at $resolvedPath.');
    }

    final apiKey = (await secureSecretsService.read(geminiApiKeySecret))?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError('Gemini API key is not configured. Add it in Settings > AI.');
    }

    final model = _currentModel;
    final jobId = '$jobIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final job = _GeminiAnalysisJob(jobId: jobId);
    _jobs[jobId] = job;

    unawaited(_runJob(
      job: job,
      apiKey: apiKey,
      episode: episode,
      audioFile: audioFile,
      model: model,
    ));

    return EpisodeAnalysisSubmitResponse(
      jobId: jobId,
      status: EpisodeAnalysisJobStatus.queued,
      cached: false,
    );
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({
    required String jobId,
  }) async {
    final job = _jobs[jobId];

    if (job == null) {
      return EpisodeAnalysisStatusResponse(
        jobId: jobId,
        status: EpisodeAnalysisJobStatus.unknown,
        error: 'Analysis job $jobId was not found.',
      );
    }

    if (job.result != null) {
      final result = job.result!;

      if (result.status == EpisodeAnalysisJobStatus.completed || result.status == EpisodeAnalysisJobStatus.failed) {
        _jobs.remove(jobId);
      }

      return result;
    }

    return EpisodeAnalysisStatusResponse(
      jobId: jobId,
      status: EpisodeAnalysisJobStatus.processing,
    );
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<void> _runJob({
    required _GeminiAnalysisJob job,
    required String apiKey,
    required Episode episode,
    required File audioFile,
    required String model,
  }) async {
    try {
      final adSegments = await _analyzeAudio(
        episode: episode,
        audioFile: audioFile,
        apiKey: apiKey,
        model: model,
      );

      job.result = EpisodeAnalysisStatusResponse(
        jobId: job.jobId,
        status: EpisodeAnalysisJobStatus.completed,
        adSegments: AdSegmentNormalizer.normalize(adSegments),
      );
    } catch (error, stackTrace) {
      _log.severe('Gemini analysis failed for ${episode.guid}: $error', error, stackTrace);

      job.result = EpisodeAnalysisStatusResponse(
        jobId: job.jobId,
        status: EpisodeAnalysisJobStatus.failed,
        error: error.toString(),
      );
    }
  }

  Future<List<AdSegment>> _analyzeAudio({
    required Episode episode,
    required File audioFile,
    required String apiKey,
    required String model,
  }) async {
    final workingDir = await Directory.systemTemp.createTemp('anytime-gemini-analysis-');

    try {
      final totalDuration = await _probeDuration(audioFile.path);
      final chunks = await _chunkAudio(
        audioFile: audioFile,
        workingDir: workingDir,
        totalDuration: totalDuration,
      );

      _log.fine('Created ${chunks.length} chunks for Gemini analysis of ${episode.guid}');

      final allSegments = <AdSegment>[];

      for (final chunk in chunks) {
        final chunkSegments = await _analyzeChunk(
          chunk: chunk,
          episode: episode,
          apiKey: apiKey,
          model: model,
        );

        // Offset chunk-relative timestamps to episode-absolute time.
        for (final segment in chunkSegments) {
          allSegments.add(AdSegment(
            startMs: segment.startMs + chunk.offsetMs,
            endMs: segment.endMs + chunk.offsetMs,
            reason: segment.reason,
            confidence: segment.confidence,
            flags: segment.flags,
          ));
        }
      }

      // Merge adjacent segments across chunk boundaries.
      final merged = _mergeAdjacentSegments(allSegments);

      // Filter segments shorter than minimum duration.
      final filtered = merged.where((s) => (s.endMs - s.startMs) >= _minSegmentDurationMs).toList();

      _log.fine(
        'Gemini analysis for ${episode.guid}: '
        '${allSegments.length} raw → ${merged.length} merged → ${filtered.length} filtered',
      );

      return filtered;
    } finally {
      if (workingDir.existsSync()) {
        await workingDir.delete(recursive: true);
      }
    }
  }

  Future<List<_AudioChunk>> _chunkAudio({
    required File audioFile,
    required Directory workingDir,
    required Duration? totalDuration,
  }) async {
    final totalSeconds = totalDuration?.inSeconds ?? 0;

    // If the episode is short enough, use a single chunk.
    if (totalSeconds > 0 && totalSeconds <= _chunkDurationSeconds + 30) {
      final chunkPath = path.join(workingDir.path, 'chunk-000.m4a');

      await _runFfmpeg(
        <String>[
          '-y',
          '-i',
          audioFile.path,
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '${_chunkAudioBitrateKbps}k',
          chunkPath,
        ],
        failureMessage: 'Failed to prepare audio for Gemini analysis.',
      );

      final chunkFile = File(chunkPath);
      final chunkDuration = await _probeDuration(chunkPath);

      return [
        _AudioChunk(
          file: chunkFile,
          offsetMs: 0,
          durationSeconds: chunkDuration?.inSeconds ?? totalSeconds,
          index: 0,
        ),
      ];
    }

    // Split into ~5-minute AAC chunks for reliable Gemini uploads across source formats.
    final effectiveSeconds = totalSeconds > 0 ? totalSeconds : 3600;
    final chunkCount = (effectiveSeconds / _chunkDurationSeconds).ceil();

    final chunks = <_AudioChunk>[];

    for (var i = 0; i < chunkCount; i++) {
      final offsetSeconds = i * _chunkDurationSeconds;
      final remaining = effectiveSeconds - offsetSeconds;
      final duration = remaining < _chunkDurationSeconds ? remaining : _chunkDurationSeconds;
      final chunkPath = path.join(
        workingDir.path,
        'chunk-${i.toString().padLeft(3, '0')}.m4a',
      );

      await _runFfmpeg(
        <String>[
          '-y',
          '-ss',
          _formatFfmpegDuration(Duration(seconds: offsetSeconds)),
          '-t',
          _formatFfmpegDuration(Duration(seconds: duration)),
          '-i',
          audioFile.path,
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '${_chunkAudioBitrateKbps}k',
          chunkPath,
        ],
        failureMessage: 'Failed to extract chunk $i for Gemini analysis.',
      );

      final chunkFile = File(chunkPath);
      if (!chunkFile.existsSync() || chunkFile.lengthSync() == 0) {
        continue;
      }

      final chunkDuration = await _probeDuration(chunkPath);
      chunks.add(_AudioChunk(
        file: chunkFile,
        offsetMs: offsetSeconds * 1000,
        durationSeconds: chunkDuration?.inSeconds ?? duration,
        index: i,
      ));
    }

    if (chunks.isEmpty) {
      throw StateError('FFmpeg produced no audio chunks.');
    }

    return chunks;
  }

  Future<List<AdSegment>> _analyzeChunk({
    required _AudioChunk chunk,
    required Episode episode,
    required String apiKey,
    required String model,
  }) async {
    // Determine MIME type from file extension.
    final chunkExt = path.extension(chunk.file.path).toLowerCase();
    final mimeType = chunkExt == '.mp3' ? 'audio/mpeg' : 'audio/mp4';

    // Upload the audio file to Gemini Files API.
    final fileUri = await _uploadFile(
      file: chunk.file,
      apiKey: apiKey,
    );

    try {
      // Build the analysis prompt.
      final prompt = _buildPrompt(
        episodeTitle: episode.title ?? 'Unknown Episode',
        chunkIndex: chunk.index,
        chunkOffsetSeconds: chunk.offsetMs ~/ 1000,
        chunkDurationSeconds: chunk.durationSeconds,
      );

      // Call Gemini generateContent with audio + prompt.
      final response = await _generateContent(
        fileUri: fileUri,
        mimeType: mimeType,
        prompt: prompt,
        apiKey: apiKey,
        model: model,
      );

      final initialSegments = _parseGeminiResponse(response);

      if (initialSegments.isEmpty) {
        return initialSegments;
      }

      return _reevaluateLongSegments(
        segments: initialSegments,
        chunk: chunk,
        episode: episode,
        fileUri: fileUri,
        mimeType: mimeType,
        apiKey: apiKey,
        model: model,
      );
    } catch (error) {
      _log.warning('Gemini chunk ${chunk.index} analysis failed: $error');
      return const <AdSegment>[];
    }
  }

  Future<List<AdSegment>> _reevaluateLongSegments({
    required List<AdSegment> segments,
    required _AudioChunk chunk,
    required Episode episode,
    required String fileUri,
    required String mimeType,
    required String apiKey,
    required String model,
  }) async {
    final reviewed = <AdSegment>[];

    for (final segment in segments) {
      if (!_shouldReevaluateSegment(segment)) {
        reviewed.add(segment);
        continue;
      }

      _log.info(
        'Gemini reevaluating long segment in chunk ${chunk.index}: '
        '${_formatDuration(Duration(milliseconds: segment.startMs))} - '
        '${_formatDuration(Duration(milliseconds: segment.endMs))}',
      );

      final refinedSegments = await _reevaluateLongSegment(
        chunk: chunk,
        episode: episode,
        candidate: segment,
        fileUri: fileUri,
        mimeType: mimeType,
        apiKey: apiKey,
        model: model,
      );

      if (refinedSegments.isEmpty) {
        _log.info('Gemini dropped long candidate segment after reevaluation in chunk ${chunk.index}.');
        continue;
      }

      reviewed.addAll(refinedSegments);
    }

    return reviewed;
  }

  Future<List<AdSegment>> _reevaluateLongSegment({
    required _AudioChunk chunk,
    required Episode episode,
    required AdSegment candidate,
    required String fileUri,
    required String mimeType,
    required String apiKey,
    required String model,
  }) async {
    final prompt = _buildReevaluationPrompt(
      episodeTitle: episode.title ?? 'Unknown Episode',
      chunkIndex: chunk.index,
      chunkOffsetSeconds: chunk.offsetMs ~/ 1000,
      chunkDurationSeconds: chunk.durationSeconds,
      candidate: candidate,
    );

    try {
      final response = await _generateContent(
        fileUri: fileUri,
        mimeType: mimeType,
        prompt: prompt,
        apiKey: apiKey,
        model: model,
      );

      final refined = _parseGeminiResponse(response)
          .map((segment) => _clampToCandidateWindow(segment, candidate))
          .whereType<AdSegment>()
          .toList(growable: false);

      return refined;
    } catch (error) {
      _log.warning('Gemini long-segment reevaluation failed for chunk ${chunk.index}: $error');
      return const <AdSegment>[];
    }
  }

  Future<String> _uploadFile({
    required File file,
    required String apiKey,
  }) async {
    final fileBytes = await file.readAsBytes();
    final fileName = path.basename(file.path);
    final ext = path.extension(fileName).toLowerCase();
    final mimeType = ext == '.mp3' ? 'audio/mpeg' : 'audio/mp4';

    // Start resumable upload.
    final initResponse = await _client.post(
      Uri.parse('https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey'),
      headers: <String, String>{
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': '${fileBytes.length}',
        'X-Goog-Upload-Header-Content-Type': mimeType,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'file': <String, dynamic>{
          'display_name': fileName,
        },
      }),
    );

    if (initResponse.statusCode != 200) {
      throw StateError('Gemini file upload init failed (${initResponse.statusCode}): ${initResponse.body}');
    }

    final uploadUrl = initResponse.headers['x-goog-upload-url'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw StateError('Gemini file upload did not return an upload URL.');
    }

    // Upload the file bytes.
    final uploadRequest = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Length'] = '${fileBytes.length}'
      ..headers['X-Goog-Upload-Offset'] = '0'
      ..headers['X-Goog-Upload-Command'] = 'upload, finalize'
      ..bodyBytes = fileBytes;

    final uploadResponse = await _client.send(uploadRequest).timeout(_requestTimeout);
    final uploadBody = await uploadResponse.stream.bytesToString();

    if (uploadResponse.statusCode != 200) {
      throw StateError('Gemini file upload failed (${uploadResponse.statusCode}): $uploadBody');
    }

    final uploadData = jsonDecode(uploadBody) as Map<String, dynamic>;
    final fileData = uploadData['file'] as Map<String, dynamic>?;
    final fileUri = fileData?['uri'] as String?;

    if (fileUri == null || fileUri.isEmpty) {
      throw StateError('Gemini file upload did not return a file URI.');
    }

    // Wait for file to be ACTIVE.
    final fileName2 = fileData?['name'] as String?;
    if (fileName2 != null) {
      await _waitForFileActive(fileName: fileName2, apiKey: apiKey);
    }

    return fileUri;
  }

  Future<void> _waitForFileActive({
    required String fileName,
    required String apiKey,
  }) async {
    for (var i = 0; i < 30; i++) {
      final response = await _client.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/$fileName?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final state = data['state'] as String?;

        if (state == 'ACTIVE') {
          return;
        }

        if (state == 'FAILED') {
          throw StateError('Gemini file processing failed.');
        }
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw StateError('Gemini file processing timed out.');
  }

  Future<Map<String, dynamic>> _generateContent({
    required String fileUri,
    required String mimeType,
    required String prompt,
    required String apiKey,
    required String model,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final body = jsonEncode(<String, dynamic>{
      'contents': [
        <String, dynamic>{
          'parts': [
            <String, dynamic>{
              'fileData': <String, dynamic>{
                'mimeType': mimeType,
                'fileUri': fileUri,
              },
            },
            <String, dynamic>{
              'text': prompt,
            },
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0,
        'responseMimeType': 'application/json',
        'responseSchema': <String, dynamic>{
          'type': 'OBJECT',
          'properties': <String, dynamic>{
            'segments': <String, dynamic>{
              'type': 'ARRAY',
              'items': <String, dynamic>{
                'type': 'OBJECT',
                'properties': <String, dynamic>{
                  'start_time': <String, dynamic>{'type': 'STRING'},
                  'end_time': <String, dynamic>{'type': 'STRING'},
                  'category': <String, dynamic>{'type': 'STRING'},
                  'confidence': <String, dynamic>{'type': 'NUMBER'},
                  'reasoning': <String, dynamic>{'type': 'STRING'},
                },
                'required': ['start_time', 'end_time', 'category', 'confidence', 'reasoning'],
              },
            },
          },
          'required': ['segments'],
        },
      },
    });

    final response = await _client
        .post(uri, headers: <String, String>{'Content-Type': 'application/json'}, body: body)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw StateError('Gemini generateContent failed (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<AdSegment> _parseGeminiResponse(Map<String, dynamic> response) {
    // Extract text from the response.
    final candidates = response['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return const <AdSegment>[];
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      return const <AdSegment>[];
    }

    final text = parts[0]['text'] as String?;
    if (text == null || text.isEmpty) {
      return const <AdSegment>[];
    }

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    final segments = parsed['segments'] as List?;
    if (segments == null || segments.isEmpty) {
      return const <AdSegment>[];
    }

    return segments
        .whereType<Map<String, dynamic>>()
        .map((seg) {
          final startMs = _parseTimestamp(seg['start_time'] as String?);
          final endMs = _parseTimestamp(seg['end_time'] as String?);
          final confidence = (seg['confidence'] as num?)?.toDouble();
          final category = seg['category'] as String?;
          final reasoning = seg['reasoning'] as String?;

          return AdSegment(
            startMs: startMs,
            endMs: endMs,
            reason: [if (category != null) category, if (reasoning != null) reasoning].join(': '),
            confidence: confidence,
          );
        })
        .where((s) => s.endMs > s.startMs)
        .toList();
  }

  /// Parse HH:MM:SS or MM:SS timestamp to milliseconds.
  /// Also handles the known Gemini bug where MM:SS is returned as HH:MM:SS
  /// with an inflated hours field (e.g., 03:10:48 instead of 00:03:10).
  int _parseTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 0;
    }

    final parts = timestamp.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      // Detect the known Gemini bug: if hours > 0 but the chunk is only ~5 min,
      // treat hours as minutes and minutes as seconds.
      if (hours > 0 && hours < 60 && (hours * 3600 + minutes * 60 + seconds) > _chunkDurationSeconds + 60) {
        return (hours * 60 + minutes) * 1000;
      }

      return (hours * 3600 + minutes * 60 + seconds) * 1000;
    }

    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60 + seconds) * 1000;
    }

    return 0;
  }

  List<AdSegment> _mergeAdjacentSegments(List<AdSegment> segments) {
    if (segments.isEmpty) {
      return const <AdSegment>[];
    }

    final sorted = List<AdSegment>.from(segments)..sort((a, b) => a.startMs.compareTo(b.startMs));

    final merged = <AdSegment>[sorted.first];

    for (final segment in sorted.skip(1)) {
      final current = merged.last;

      if (segment.startMs <= current.endMs + _mergeGapMs) {
        merged[merged.length - 1] = AdSegment(
          startMs: current.startMs,
          endMs: segment.endMs > current.endMs ? segment.endMs : current.endMs,
          reason: [if (current.reason != null) current.reason!, if (segment.reason != null) segment.reason!]
              .toSet()
              .join(' | '),
          confidence: _maxConfidence(current.confidence, segment.confidence),
          flags: {...current.flags, ...segment.flags}.toList(),
        );
      } else {
        merged.add(segment);
      }
    }

    return merged;
  }

  double? _maxConfidence(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  bool _shouldReevaluateSegment(AdSegment segment) {
    return (segment.endMs - segment.startMs) > _reevaluationThresholdMs;
  }

  AdSegment? _clampToCandidateWindow(AdSegment segment, AdSegment candidate) {
    final startMs = segment.startMs < candidate.startMs ? candidate.startMs : segment.startMs;
    final endMs = segment.endMs > candidate.endMs ? candidate.endMs : segment.endMs;

    if (endMs <= startMs) {
      return null;
    }

    return AdSegment(
      startMs: startMs,
      endMs: endMs,
      reason: segment.reason,
      confidence: segment.confidence,
      flags: segment.flags,
    );
  }

  String _buildPrompt({
    required String episodeTitle,
    required int chunkIndex,
    required int chunkOffsetSeconds,
    required int chunkDurationSeconds,
  }) {
    final maxTime = _formatDuration(Duration(seconds: chunkDurationSeconds));
    return '''
You are an expert audio analyst specializing in podcast ad detection.

EPISODE: "$episodeTitle"
CHUNK: #$chunkIndex (starts at ${_formatDuration(Duration(seconds: chunkOffsetSeconds))} in the full episode)
CHUNK DURATION: ~${chunkDurationSeconds}s

Listen to this audio chunk and identify any skippable segments. All timestamps must be relative to THIS chunk (starting from 00:00:00) and must not exceed $maxTime.

SKIPPABLE CATEGORIES:
- "advertisement": Paid ads, sponsor reads, promo codes, product placements
- "housekeeping_promo": Host self-promotion, cross-promotion of other shows, Patreon/subscription pitches, social media plugs
- "boilerplate_credits": Formulaic intros/outros, legal disclaimers, production credits that repeat every episode

IMPORTANT RULES:
1. ~75% of chunks contain NO skippable content. Default to returning an empty segments array.
2. Do NOT flag organic conversation, interviews, or editorial content even if it mentions products.
3. Be conservative: prefer zero segments over weak detections.
4. Maximum 3 segments per chunk.
5. Listen for audio cues: tone shifts, music beds, jingles, and production transitions that signal ad boundaries.

Return JSON with a "segments" array. Each segment needs: start_time (HH:MM:SS), end_time (HH:MM:SS), category, confidence (0-1), reasoning.
''';
  }

  String _buildReevaluationPrompt({
    required String episodeTitle,
    required int chunkIndex,
    required int chunkOffsetSeconds,
    required int chunkDurationSeconds,
    required AdSegment candidate,
  }) {
    final chunkMaxTime = _formatDuration(Duration(seconds: chunkDurationSeconds));
    final candidateStart = _formatDuration(Duration(milliseconds: candidate.startMs));
    final candidateEnd = _formatDuration(Duration(milliseconds: candidate.endMs));
    final candidateDurationSeconds = ((candidate.endMs - candidate.startMs) / 1000).toStringAsFixed(0);

    return '''
You are re-reviewing one suspiciously long candidate ad segment from a podcast audio chunk.

EPISODE: "$episodeTitle"
CHUNK: #$chunkIndex (starts at ${_formatDuration(Duration(seconds: chunkOffsetSeconds))} in the full episode)
CHUNK DURATION: ~${chunkDurationSeconds}s
CANDIDATE WINDOW TO REVIEW: $candidateStart to $candidateEnd within this chunk
CANDIDATE LENGTH: ${candidateDurationSeconds}s

This candidate is unusually long. Long ad segments are usually false positives caused by organic conversation, story content, or loose boundaries.

Review ONLY the audio inside the candidate window. Return:
- a smaller set of precise skippable sub-segments fully contained within that window, or
- an empty segments array if the candidate is not clearly skippable.

STRICT RULES:
1. Be more conservative than the first pass.
2. Prefer an empty array over a broad or uncertain segment.
3. Do not return commentary, interviews, narrative content, or product discussion unless it is clearly a direct ad/promo addressed to the listener.
4. Every returned segment must stay fully inside $candidateStart to $candidateEnd.
5. If the audio contains a real ad but only part of this window is skippable, return only that narrower part.
6. Maximum 3 segments.
7. All timestamps must be chunk-relative HH:MM:SS and must not exceed $chunkMaxTime.

Return JSON with a "segments" array. Each segment needs: start_time (HH:MM:SS), end_time (HH:MM:SS), category, confidence (0-1), reasoning.
''';
  }

  String _formatFfmpegDuration(Duration duration) {
    return (duration.inMilliseconds / 1000).toStringAsFixed(3);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<Duration?> _probeDuration(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final durationSeconds = double.tryParse(session.getMediaInformation()?.getDuration()?.trim() ?? '');

    if (durationSeconds == null || durationSeconds <= 0) {
      return null;
    }

    return Duration(milliseconds: (durationSeconds * 1000).round());
  }

  Future<void> _runFfmpeg(
    List<String> commandArguments, {
    required String failureMessage,
  }) async {
    final session = await FFmpegKit.executeWithArguments(commandArguments);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return;
    }

    final output = (await session.getOutput())?.trim();
    _log.warning('FFmpeg command failed: ${commandArguments.join(' ')}');

    if (output != null && output.isNotEmpty) {
      throw StateError('$failureMessage $output');
    }

    throw StateError(failureMessage);
  }

  String get _currentModel {
    final resolved = _modelResolver?.call().trim() ?? '';
    return resolved.isEmpty ? _defaultModel : resolved;
  }
}

class _GeminiAnalysisJob {
  final String jobId;
  EpisodeAnalysisStatusResponse? result;

  _GeminiAnalysisJob({required this.jobId});
}

class _AudioChunk {
  final File file;
  final int offsetMs;
  final int durationSeconds;
  final int index;

  _AudioChunk({
    required this.file,
    required this.offsetMs,
    required this.durationSeconds,
    required this.index,
  });
}
