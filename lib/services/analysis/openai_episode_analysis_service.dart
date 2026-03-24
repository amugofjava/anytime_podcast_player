// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/ad_segment_normalizer.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/episode_analysis_transcript_codec.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:http/http.dart' as http;

class ConfigurableEpisodeAnalysisService implements EpisodeAnalysisService {
  ConfigurableEpisodeAnalysisService({
    required this.settingsService,
    required this.secureSecretsService,
    EpisodeAnalysisService? backendService,
    OpenAIEpisodeAnalysisService? openAiService,
  })  : _backendService = backendService,
        _openAiService = openAiService ??
            OpenAIEpisodeAnalysisService(
              secureSecretsService: secureSecretsService,
            );

  final SettingsService settingsService;
  final SecureSecretsService secureSecretsService;
  final EpisodeAnalysisService? _backendService;
  final OpenAIEpisodeAnalysisService _openAiService;

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) {
    switch (settingsService.transcriptUploadProvider) {
      case TranscriptUploadProvider.disabled:
        throw StateError('Ad analysis is disabled. Configure an analysis provider in Settings.');
      case TranscriptUploadProvider.openAi:
        return _openAiService.submit(
          episode: episode,
          force: force,
          transcript: transcript,
        );
      case TranscriptUploadProvider.analysisBackend:
        final backendService = _backendService;

        if (backendService == null) {
          throw StateError('Analysis backend is not configured in this build.');
        }

        return backendService.submit(
          episode: episode,
          force: force,
          transcript: transcript,
        );
    }
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({
    required String jobId,
  }) {
    if (jobId.startsWith(OpenAIEpisodeAnalysisService.jobIdPrefix)) {
      return _openAiService.poll(jobId: jobId);
    }

    final backendService = _backendService;

    if (backendService == null) {
      throw StateError('Analysis backend is not configured in this build.');
    }

    return backendService.poll(jobId: jobId);
  }

  @override
  void close() {
    _openAiService.close();
    _backendService?.close();
  }
}

class OpenAIEpisodeAnalysisService implements EpisodeAnalysisService {
  OpenAIEpisodeAnalysisService({
    required this.secureSecretsService,
    http.Client? client,
    String model = 'gpt-4.1-mini',
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _model = model,
        _baseUri = baseUri ?? Uri.parse('https://api.openai.com/v1/');

  static const jobIdPrefix = 'openai:';
  static const _maxWindowChars = 12000;
  static const _windowOverlapCues = 4;
  static const _requestTimeout = Duration(seconds: 45);

  final SecureSecretsService secureSecretsService;
  final http.Client _client;
  final bool _ownsClient;
  final String _model;
  final Uri _baseUri;
  final Map<String, _OpenAiAnalysisJob> _jobs = <String, _OpenAiAnalysisJob>{};

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    if (transcript == null || transcript.content.trim().isEmpty) {
      throw StateError('Transcript content is required for OpenAI analysis.');
    }

    final apiKey = (await secureSecretsService.read(openAiApiKeySecret))?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw StateError('OpenAI API key is not configured. Add it in Settings > AI.');
    }

    final jobId = '$jobIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final job = _OpenAiAnalysisJob(jobId: jobId);
    _jobs[jobId] = job;

    unawaited(_runJob(
      job: job,
      apiKey: apiKey,
      episode: episode,
      transcript: transcript,
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

  Future<void> _runJob({
    required _OpenAiAnalysisJob job,
    required String apiKey,
    required Episode episode,
    required EpisodeAnalysisTranscriptPayload transcript,
  }) async {
    try {
      final adSegments = await _analyzeTranscript(
        episode: episode,
        transcript: transcript,
        apiKey: apiKey,
      );

      job.result = EpisodeAnalysisStatusResponse(
        jobId: job.jobId,
        status: EpisodeAnalysisJobStatus.completed,
        adSegments: adSegments,
        cached: false,
      );
    } catch (error) {
      job.result = EpisodeAnalysisStatusResponse(
        jobId: job.jobId,
        status: EpisodeAnalysisJobStatus.failed,
        error: _analysisFailureMessage(error),
      );
    }
  }

  Future<List<AdSegment>> _analyzeTranscript({
    required Episode episode,
    required EpisodeAnalysisTranscriptPayload transcript,
    required String apiKey,
  }) async {
    final windows = transcriptWindowsFromPayload(
      transcript,
      maxWindowChars: _maxWindowChars,
      overlapCues: _windowOverlapCues,
    );

    if (windows.isEmpty) {
      throw StateError('Transcript did not contain any usable timestamped cues for analysis.');
    }

    final segments = <AdSegment>[];

    for (final window in windows) {
      segments.addAll(await _analyzeWindow(
        episode: episode,
        window: window,
        apiKey: apiKey,
      ));
    }

    return AdSegmentNormalizer.normalize(segments);
  }

  Future<List<AdSegment>> _analyzeWindow({
    required Episode episode,
    required EpisodeAnalysisTranscriptWindow window,
    required String apiKey,
  }) async {
    final uri = _baseUri.resolve('chat/completions');
    late final http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $apiKey',
              'content-type': 'application/json',
              'accept': 'application/json',
              'user-agent': Environment.userAgent(),
            },
            body: jsonEncode(<String, dynamic>{
              'model': _model,
              'temperature': 0,
              'messages': <Map<String, String>>[
                <String, String>{
                  'role': 'system',
                  'content':
                      'You analyze podcast transcript windows and identify only clear ad or sponsorship segments. '
                          'Use the provided absolute cue timestamps. Return no commentary. '
                          'If a segment is uncertain, omit it instead of guessing.',
                },
                <String, String>{
                  'role': 'user',
                  'content': _buildPrompt(
                    episode: episode,
                    window: window,
                  ),
                },
              ],
              'response_format': <String, dynamic>{
                'type': 'json_schema',
                'json_schema': <String, dynamic>{
                  'name': 'ad_segment_analysis',
                  'strict': true,
                  'schema': <String, dynamic>{
                    'type': 'object',
                    'additionalProperties': false,
                    'required': <String>['ad_segments'],
                    'properties': <String, dynamic>{
                      'ad_segments': <String, dynamic>{
                        'type': 'array',
                        'items': <String, dynamic>{
                          'type': 'object',
                          'additionalProperties': false,
                          'required': <String>['start_ms', 'end_ms', 'reason', 'confidence', 'flags'],
                          'properties': <String, dynamic>{
                            'start_ms': <String, dynamic>{'type': 'integer'},
                            'end_ms': <String, dynamic>{'type': 'integer'},
                            'reason': <String, dynamic>{'type': 'string'},
                            'confidence': <String, dynamic>{'type': 'number'},
                            'flags': <String, dynamic>{
                              'type': 'array',
                              'items': <String, dynamic>{'type': 'string'},
                            },
                          },
                        },
                      },
                    },
                  },
                },
              },
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw TimeoutException('OpenAI analysis timed out.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EpisodeAnalysisHttpException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('OpenAI analysis response was not a JSON object.');
    }

    final jsonContent = _extractJsonContent(decoded);
    final payload = jsonDecode(jsonContent);

    if (payload is! Map<String, dynamic>) {
      throw const FormatException('OpenAI analysis payload was not a JSON object.');
    }

    final adSegments = payload['ad_segments'];

    if (adSegments is! List) {
      throw const FormatException('OpenAI analysis payload did not contain an ad_segments array.');
    }

    if (adSegments.any((segment) => segment is! Map)) {
      throw const FormatException('OpenAI analysis payload contained an invalid ad segment.');
    }

    return AdSegmentNormalizer.normalize(
      adSegments.cast<Map>().map((rawSegment) {
        final segment = Map<String, dynamic>.from(rawSegment);
        final startMs = _clampWindowTimestamp(_requireInt(segment['start_ms'], field: 'start_ms'), window);
        final endMs = _clampWindowTimestamp(_requireInt(segment['end_ms'], field: 'end_ms'), window);
        final flags = segment['flags'];

        if (flags is! List) {
          throw const FormatException('OpenAI analysis payload contained invalid flags.');
        }

        return AdSegment(
          startMs: startMs,
          endMs: endMs,
          reason: _requireString(segment['reason'], field: 'reason'),
          confidence: _requireDouble(segment['confidence'], field: 'confidence'),
          flags: flags.map((flag) => flag.toString()).toList(growable: false),
        );
      }).toList(growable: false),
    );
  }

  String _buildPrompt({
    required Episode episode,
    required EpisodeAnalysisTranscriptWindow window,
  }) {
    return jsonEncode(<String, dynamic>{
      'task': 'Detect ad or sponsorship segments in this podcast transcript window.',
      'instructions': <String>[
        'Mark only explicit ads, sponsorship reads, host-read promotions, promo codes, dynamic insertions, or cross-promotions.',
        'Do not mark ordinary editorial discussion, show banter, or topic transitions unless they are clearly promotional.',
        'Return absolute timestamps in milliseconds using only the cue range provided.',
        'Return an empty array if there are no clear ad segments in this window.',
      ],
      'episode': <String, dynamic>{
        'guid': episode.guid,
        'title': episode.title,
        'podcast': episode.podcast,
      },
      'window': <String, dynamic>{
        'index': window.index,
        'start_ms': window.startMs,
        'end_ms': window.endMs,
        'cues': window.cues
            .map((cue) => <String, dynamic>{
                  'start_ms': cue.start.inMilliseconds,
                  'end_ms': cue.end?.inMilliseconds ?? cue.start.inMilliseconds,
                  'text': cue.data?.trim() ?? '',
                })
            .toList(growable: false),
      },
    });
  }

  String _extractJsonContent(Map<String, dynamic> response) {
    final choices = response['choices'];

    if (choices is! List || choices.isEmpty) {
      throw const FormatException('OpenAI response did not contain any choices.');
    }

    final choice = choices.first;

    if (choice is! Map<String, dynamic>) {
      throw const FormatException('OpenAI response choice was invalid.');
    }

    final message = choice['message'];

    if (message is! Map<String, dynamic>) {
      throw const FormatException('OpenAI response message was invalid.');
    }

    final content = message['content'];

    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();

      for (final item in content) {
        if (item is! Map) {
          continue;
        }

        final text = item['text'];

        if (text is String && text.trim().isNotEmpty) {
          buffer.write(text);
        }
      }

      if (buffer.toString().trim().isNotEmpty) {
        return buffer.toString();
      }
    }

    throw const FormatException('OpenAI response message did not contain JSON content.');
  }

  int _clampWindowTimestamp(int timestamp, EpisodeAnalysisTranscriptWindow window) {
    if (timestamp < window.startMs) {
      return window.startMs;
    }

    if (timestamp > window.endMs) {
      return window.endMs;
    }

    return timestamp;
  }

  String _analysisFailureMessage(Object error) {
    if (error is TimeoutException) {
      return 'OpenAI analysis timed out. Try again.';
    }

    if (error is SocketException || error is http.ClientException) {
      return 'OpenAI analysis could not reach OpenAI. Check your connection and try again.';
    }

    if (error is EpisodeAnalysisHttpException) {
      return _httpErrorMessage(error);
    }

    if (error is FormatException) {
      return 'OpenAI returned malformed structured output. No ad segments were saved.';
    }

    final description = error.toString();

    if (description.startsWith('StateError: ')) {
      return description.substring('StateError: '.length);
    }

    if (description.startsWith('Exception: ')) {
      return description.substring('Exception: '.length);
    }

    return 'OpenAI analysis failed. Try again.';
  }

  String _httpErrorMessage(EpisodeAnalysisHttpException error) {
    final apiMessage = _extractOpenAiErrorMessage(error.body);

    switch (error.statusCode) {
      case 400:
        return apiMessage == null || apiMessage.isEmpty
            ? 'OpenAI rejected the analysis request. Try again later.'
            : 'OpenAI rejected the analysis request: $apiMessage';
      case 401:
        return 'OpenAI API key was rejected. Check the key in Settings > AI.';
      case 408:
        return 'OpenAI analysis timed out. Try again.';
      case 429:
        return 'OpenAI rate limit reached. Wait a moment and try again.';
      default:
        if (error.statusCode >= 500) {
          return 'OpenAI is temporarily unavailable. Try again.';
        }

        if (apiMessage == null || apiMessage.isEmpty) {
          return 'OpenAI analysis request failed with status ${error.statusCode}.';
        }

        return 'OpenAI analysis request failed: $apiMessage';
    }
  }

  String? _extractOpenAiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return null;
      }

      final error = decoded['error'];

      if (error is! Map) {
        return null;
      }

      final message = error['message'];
      return message is String && message.trim().isNotEmpty ? message.trim() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class EpisodeAnalysisTranscriptWindow {
  final int index;
  final List<Subtitle> cues;
  final int startMs;
  final int endMs;

  const EpisodeAnalysisTranscriptWindow({
    required this.index,
    required this.cues,
    required this.startMs,
    required this.endMs,
  });
}

class _OpenAiAnalysisJob {
  final String jobId;
  EpisodeAnalysisStatusResponse? result;

  _OpenAiAnalysisJob({
    required this.jobId,
  });
}

List<EpisodeAnalysisTranscriptWindow> transcriptWindowsFromPayload(
  EpisodeAnalysisTranscriptPayload payload, {
  int maxWindowChars = 12000,
  int overlapCues = 4,
}) {
  final transcript = EpisodeAnalysisTranscriptCodec.fromDto(
    EpisodeAnalysisTranscriptDto(
      format: payload.format,
      content: payload.content,
    ),
  );
  final cues = transcript.subtitles;

  if (cues.isEmpty) {
    return const <EpisodeAnalysisTranscriptWindow>[];
  }

  final windows = <EpisodeAnalysisTranscriptWindow>[];
  var startIndex = 0;
  var windowIndex = 0;

  while (startIndex < cues.length) {
    var endIndex = startIndex;
    var currentChars = 0;

    while (endIndex < cues.length) {
      final cue = cues[endIndex];
      final cueChars = (cue.data?.length ?? 0) + 32;

      if (endIndex > startIndex && currentChars + cueChars > maxWindowChars) {
        break;
      }

      currentChars += cueChars;
      endIndex++;
    }

    final windowCues = cues.sublist(startIndex, endIndex);
    windows.add(EpisodeAnalysisTranscriptWindow(
      index: windowIndex,
      cues: List<Subtitle>.unmodifiable(windowCues),
      startMs: windowCues.first.start.inMilliseconds,
      endMs: (windowCues.last.end ?? windowCues.last.start).inMilliseconds,
    ));

    if (endIndex >= cues.length) {
      break;
    }

    final nextStart = endIndex - overlapCues;
    startIndex = nextStart > startIndex ? nextStart : endIndex;
    windowIndex++;
  }

  return List<EpisodeAnalysisTranscriptWindow>.unmodifiable(windows);
}

int _requireInt(
  Object? value, {
  required String field,
}) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is String && value.isNotEmpty && value != 'null') {
    return int.parse(value);
  }

  throw FormatException('OpenAI analysis payload contained an invalid $field value.');
}

double _requireDouble(
  Object? value, {
  required String field,
}) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is String && value.isNotEmpty && value != 'null') {
    return double.parse(value);
  }

  throw FormatException('OpenAI analysis payload contained an invalid $field value.');
}

String _requireString(
  Object? value, {
  required String field,
}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  throw FormatException('OpenAI analysis payload contained an invalid $field value.');
}
