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
    GrokEpisodeAnalysisService? grokService,
  })  : _backendService = backendService,
        _openAiService = openAiService ??
            OpenAIEpisodeAnalysisService(
              secureSecretsService: secureSecretsService,
              modelResolver: () => settingsService.openAiAnalysisModel,
            ),
        _grokService = grokService ??
            GrokEpisodeAnalysisService(
              secureSecretsService: secureSecretsService,
              modelResolver: () => settingsService.grokAnalysisModel,
            );

  final SettingsService settingsService;
  final SecureSecretsService secureSecretsService;
  final EpisodeAnalysisService? _backendService;
  final OpenAIEpisodeAnalysisService _openAiService;
  final GrokEpisodeAnalysisService _grokService;

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
      case TranscriptUploadProvider.grok:
        return _grokService.submit(
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

    if (jobId.startsWith(GrokEpisodeAnalysisService.jobIdPrefix)) {
      return _grokService.poll(jobId: jobId);
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
    _grokService.close();
    _backendService?.close();
  }
}

class OpenAIEpisodeAnalysisService implements EpisodeAnalysisService {
  static final _episodeContextPriorityPattern = RegExp(
    r'\b('
    r'ad|ads|advert|advertisement|commercial|sponsor|sponsored|sponsorship|'
    r'promo|promo code|coupon|archive|archival|historic|historical|radio|'
    r'193\d|194\d|195\d|196\d|197\d|old time'
    r')\b',
    caseSensitive: false,
  );

  OpenAIEpisodeAnalysisService({
    required this.secureSecretsService,
    http.Client? client,
    String model = 'gpt-4.1-mini',
    Uri? baseUri,
    String jobIdPrefixValue = jobIdPrefix,
    String apiKeySecretValue = openAiApiKeySecret,
    String providerDisplayName = 'OpenAI',
    String Function()? modelResolver,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _defaultModel = model,
        _baseUri = baseUri ?? Uri.parse('https://api.openai.com/v1/'),
        _jobIdPrefix = jobIdPrefixValue,
        _apiKeySecret = apiKeySecretValue,
        _providerDisplayName = providerDisplayName,
        _modelResolver = modelResolver;

  static const jobIdPrefix = 'openai:';
  static const _maxWindowChars = 12000;
  static const _windowOverlapCues = 4;
  static const _episodeContextMaxChars = 9000;
  static const _episodeContextBoundaryCueCount = 12;
  static const _episodeContextDistributedCueCount = 24;
  static const _candidateReviewExcerptRadius = 3;
  static const _requestTimeout = Duration(seconds: 45);

  final SecureSecretsService secureSecretsService;
  final http.Client _client;
  final bool _ownsClient;
  final String _defaultModel;
  final Uri _baseUri;
  final String _jobIdPrefix;
  final String _apiKeySecret;
  final String _providerDisplayName;
  final String Function()? _modelResolver;
  final Map<String, _OpenAiAnalysisJob> _jobs = <String, _OpenAiAnalysisJob>{};

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    if (transcript == null || transcript.content.trim().isEmpty) {
      throw StateError('Transcript content is required for $_providerDisplayName analysis.');
    }

    final apiKey = (await secureSecretsService.read(_apiKeySecret))?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw StateError('$_providerDisplayName API key is not configured. Add it in Settings > AI.');
    }

    final model = _currentModel;
    final jobId = '$_jobIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final job = _OpenAiAnalysisJob(jobId: jobId);
    _jobs[jobId] = job;

    unawaited(_runJob(
      job: job,
      apiKey: apiKey,
      episode: episode,
      transcript: transcript,
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

  Future<void> _runJob({
    required _OpenAiAnalysisJob job,
    required String apiKey,
    required Episode episode,
    required EpisodeAnalysisTranscriptPayload transcript,
    required String model,
  }) async {
    try {
      final adSegments = await _analyzeTranscript(
        episode: episode,
        transcript: transcript,
        apiKey: apiKey,
        model: model,
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
    required String model,
  }) async {
    final cues = transcriptCuesFromPayload(transcript);

    if (cues.isEmpty) {
      throw StateError('Transcript did not contain any usable timestamped cues for analysis.');
    }

    final narrativeContext = await _analyzeEpisodeNarrativeContext(
      episode: episode,
      cues: cues,
      apiKey: apiKey,
      model: model,
    );
    final windows = transcriptWindowsFromCues(
      cues,
      maxWindowChars: _maxWindowChars,
      overlapCues: _windowOverlapCues,
    );
    final segments = <AdSegment>[];

    for (final window in windows) {
      segments.addAll(await _analyzeWindow(
        episode: episode,
        window: window,
        narrativeContext: narrativeContext,
        apiKey: apiKey,
        model: model,
      ));
    }

    final normalizedSegments = AdSegmentNormalizer.normalize(segments);

    if (normalizedSegments.isEmpty) {
      return normalizedSegments;
    }

    return _reviewCandidateSegments(
      episode: episode,
      cues: cues,
      narrativeContext: narrativeContext,
      candidates: normalizedSegments,
      apiKey: apiKey,
      model: model,
    );
  }

  Future<_EpisodeNarrativeContext> _analyzeEpisodeNarrativeContext({
    required Episode episode,
    required List<Subtitle> cues,
    required String apiKey,
    required String model,
  }) async {
    final payload = await _requestStructuredPayload(
      apiKey: apiKey,
      model: model,
      systemPrompt: 'You analyze podcast episodes at the narrative level before any ad skipping decisions are made. '
          'Distinguish real podcast sponsorship from archival, fictional, documentary, or illustrative ads that are '
          'part of the story itself. If uncertain, bias toward preserving editorial audio instead of skipping it.',
      userPayload: <String, dynamic>{
        'task': 'Summarize episode-wide narrative context relevant to ad detection.',
        'instructions': <String>[
          'Determine whether the episode likely includes historical, archival, fictional, or illustrative ads as part of the editorial narrative.',
          'Determine whether the episode likely contains real sponsorship or promotional reads addressed to the podcast listener.',
          'Write guidance for a later window-level classifier that should fail closed on narrative material.',
        ],
        'episode': <String, dynamic>{
          'guid': episode.guid,
          'title': episode.title,
          'podcast': episode.podcast,
        },
        'sampled_cues': _sampleEpisodeContextCues(cues).map((cue) => _cueToMap(cue)).toList(growable: false),
      },
      schemaName: 'episode_narrative_context',
      schema: <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>[
          'summary',
          'guidance',
          'historical_ads_are_part_of_story',
          'current_podcast_sponsorship_likely',
          'narrative_flags',
        ],
        'properties': <String, dynamic>{
          'summary': <String, dynamic>{'type': 'string'},
          'guidance': <String, dynamic>{'type': 'string'},
          'historical_ads_are_part_of_story': <String, dynamic>{'type': 'boolean'},
          'current_podcast_sponsorship_likely': <String, dynamic>{'type': 'boolean'},
          'narrative_flags': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{'type': 'string'},
          },
        },
      },
    );

    final narrativeFlags = payload['narrative_flags'];

    if (narrativeFlags is! List) {
      throw const FormatException('OpenAI narrative context payload contained invalid narrative_flags.');
    }

    return _EpisodeNarrativeContext(
      summary: _requireString(payload['summary'], field: 'summary'),
      guidance: _requireString(payload['guidance'], field: 'guidance'),
      historicalAdsArePartOfStory:
          _requireBool(payload['historical_ads_are_part_of_story'], field: 'historical_ads_are_part_of_story'),
      currentPodcastSponsorshipLikely:
          _requireBool(payload['current_podcast_sponsorship_likely'], field: 'current_podcast_sponsorship_likely'),
      narrativeFlags: narrativeFlags.map((flag) => flag.toString()).toList(growable: false),
    );
  }

  Future<List<AdSegment>> _analyzeWindow({
    required Episode episode,
    required EpisodeAnalysisTranscriptWindow window,
    required _EpisodeNarrativeContext narrativeContext,
    required String apiKey,
    required String model,
  }) async {
    final payload = await _requestStructuredPayload(
      apiKey: apiKey,
      model: model,
      systemPrompt: 'You analyze podcast transcript windows and identify only clear ad or sponsorship segments. '
          'Use the provided absolute cue timestamps. Treat archival, historical, fictional, or example commercials '
          'that are part of the episode narrative as editorial content, not skippable ads. Return no commentary. '
          'If a segment is uncertain, omit it instead of guessing.',
      userPayload: _buildPrompt(
        episode: episode,
        window: window,
        narrativeContext: narrativeContext,
      ),
      schemaName: 'ad_segment_analysis',
      schema: <String, dynamic>{
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
    );
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

  Future<List<AdSegment>> _reviewCandidateSegments({
    required Episode episode,
    required List<Subtitle> cues,
    required _EpisodeNarrativeContext narrativeContext,
    required List<AdSegment> candidates,
    required String apiKey,
    required String model,
  }) async {
    final payload = await _requestStructuredPayload(
      apiKey: apiKey,
      model: model,
      systemPrompt: 'You review candidate podcast ad segments using episode-wide narrative context. '
          'Keep only segments that are likely real sponsorship or promotional content addressed to the listener. '
          'Reject archival, historical, fictional, documentary-example, or in-story commercials. '
          'If uncertain, reject the segment.',
      userPayload: <String, dynamic>{
        'task': 'Review candidate ad segments against the episode narrative as a whole.',
        'instructions': <String>[
          'Keep only segments that are likely real sponsorship or promo content for this podcast episode.',
          'Reject segments that are better explained as archival, historical, fictional, or illustrative commercials inside the story.',
          'Reject uncertain segments.',
        ],
        'episode': <String, dynamic>{
          'guid': episode.guid,
          'title': episode.title,
          'podcast': episode.podcast,
        },
        'episode_context': narrativeContext.toMap(),
        'candidates': List<Map<String, dynamic>>.generate(
          candidates.length,
          (index) {
            final candidate = candidates[index];

            return <String, dynamic>{
              'candidate_id': 'candidate_$index',
              'start_ms': candidate.startMs,
              'end_ms': candidate.endMs,
              'reason': candidate.reason ?? '',
              'confidence': candidate.confidence ?? 0,
              'flags': candidate.flags,
              'excerpt_cues': _excerptCuesForSegment(
                cues,
                candidate,
              ).map((cue) => _cueToMap(cue)).toList(growable: false),
            };
          },
          growable: false,
        ),
      },
      schemaName: 'ad_segment_review',
      schema: <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>['decisions'],
        'properties': <String, dynamic>{
          'decisions': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{
              'type': 'object',
              'additionalProperties': false,
              'required': <String>['candidate_id', 'keep', 'reason'],
              'properties': <String, dynamic>{
                'candidate_id': <String, dynamic>{'type': 'string'},
                'keep': <String, dynamic>{'type': 'boolean'},
                'reason': <String, dynamic>{'type': 'string'},
              },
            },
          },
        },
      },
    );

    final decisions = payload['decisions'];

    if (decisions is! List) {
      throw const FormatException('OpenAI review payload did not contain a decisions array.');
    }

    final keptCandidateIds = <String>{};

    for (final rawDecision in decisions) {
      if (rawDecision is! Map) {
        throw const FormatException('OpenAI review payload contained an invalid decision.');
      }

      final decision = Map<String, dynamic>.from(rawDecision);

      if (_requireBool(decision['keep'], field: 'keep')) {
        keptCandidateIds.add(_requireString(decision['candidate_id'], field: 'candidate_id'));
      }
    }

    final keptSegments = <AdSegment>[];

    for (var index = 0; index < candidates.length; index++) {
      if (keptCandidateIds.contains('candidate_$index')) {
        keptSegments.add(candidates[index]);
      }
    }

    return AdSegmentNormalizer.normalize(keptSegments);
  }

  Future<Map<String, dynamic>> _requestStructuredPayload({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required Map<String, dynamic> userPayload,
    required String schemaName,
    required Map<String, dynamic> schema,
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
              'model': model,
              'temperature': 0,
              'messages': <Map<String, String>>[
                <String, String>{
                  'role': 'system',
                  'content': systemPrompt,
                },
                <String, String>{
                  'role': 'user',
                  'content': jsonEncode(userPayload),
                },
              ],
              'response_format': <String, dynamic>{
                'type': 'json_schema',
                'json_schema': <String, dynamic>{
                  'name': schemaName,
                  'strict': true,
                  'schema': schema,
                },
              },
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw TimeoutException('$_providerDisplayName analysis timed out.');
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

    return payload;
  }

  Map<String, dynamic> _buildPrompt({
    required Episode episode,
    required EpisodeAnalysisTranscriptWindow window,
    required _EpisodeNarrativeContext narrativeContext,
  }) {
    return <String, dynamic>{
      'task': 'Detect ad or sponsorship segments in this podcast transcript window.',
      'instructions': <String>[
        'Mark only explicit ads, sponsorship reads, host-read promotions, promo codes, dynamic insertions, or cross-promotions.',
        'Do not mark ordinary editorial discussion, show banter, or topic transitions unless they are clearly promotional.',
        'Do not mark archival, historical, fictional, or example commercials that are part of the story or being discussed as content.',
        'If the episode context suggests ads are part of the narrative, require direct evidence that the segment is a real sponsorship for this podcast before marking it.',
        'Return absolute timestamps in milliseconds using only the cue range provided.',
        'Return an empty array if there are no clear ad segments in this window.',
      ],
      'episode': <String, dynamic>{
        'guid': episode.guid,
        'title': episode.title,
        'podcast': episode.podcast,
      },
      'episode_context': narrativeContext.toMap(),
      'window': <String, dynamic>{
        'index': window.index,
        'start_ms': window.startMs,
        'end_ms': window.endMs,
        'cues': window.cues.map((cue) => _cueToMap(cue)).toList(growable: false),
      },
    };
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
      return '$_providerDisplayName analysis timed out. Try again.';
    }

    if (error is SocketException || error is http.ClientException) {
      return '$_providerDisplayName analysis could not reach $_providerDisplayName. Check your connection and try again.';
    }

    if (error is EpisodeAnalysisHttpException) {
      return _httpErrorMessage(error);
    }

    if (error is FormatException) {
      return '$_providerDisplayName returned malformed structured output. No ad segments were saved.';
    }

    final description = error.toString();

    if (description.startsWith('StateError: ')) {
      return description.substring('StateError: '.length);
    }

    if (description.startsWith('Exception: ')) {
      return description.substring('Exception: '.length);
    }

    return '$_providerDisplayName analysis failed. Try again.';
  }

  String _httpErrorMessage(EpisodeAnalysisHttpException error) {
    final apiMessage = _extractOpenAiErrorMessage(error.body);

    switch (error.statusCode) {
      case 400:
        return apiMessage == null || apiMessage.isEmpty
            ? '$_providerDisplayName rejected the analysis request. Try again later.'
            : '$_providerDisplayName rejected the analysis request: $apiMessage';
      case 401:
        return '$_providerDisplayName API key was rejected. Check the key in Settings > AI.';
      case 408:
        return '$_providerDisplayName analysis timed out. Try again.';
      case 429:
        return '$_providerDisplayName rate limit reached. Wait a moment and try again.';
      default:
        if (error.statusCode >= 500) {
          return '$_providerDisplayName is temporarily unavailable. Try again.';
        }

        if (apiMessage == null || apiMessage.isEmpty) {
          return '$_providerDisplayName analysis request failed with status ${error.statusCode}.';
        }

        return '$_providerDisplayName analysis request failed: $apiMessage';
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

  String get _currentModel {
    final resolved = _modelResolver?.call().trim() ?? '';
    return resolved.isEmpty ? _defaultModel : resolved;
  }
}

class GrokEpisodeAnalysisService extends OpenAIEpisodeAnalysisService {
  static const jobIdPrefix = 'grok:';

  GrokEpisodeAnalysisService({
    required super.secureSecretsService,
    super.client,
    super.model = 'grok-3',
    super.modelResolver,
    Uri? baseUri,
  }) : super(
          baseUri: baseUri ?? Uri.parse('https://api.x.ai/v1/'),
          jobIdPrefixValue: jobIdPrefix,
          apiKeySecretValue: grokApiKeySecret,
          providerDisplayName: 'Grok',
        );
}

class EpisodeAnalysisModelCatalogService {
  EpisodeAnalysisModelCatalogService({
    required this.secureSecretsService,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final SecureSecretsService secureSecretsService;
  final http.Client _client;
  final bool _ownsClient;

  Future<List<String>> listModels({
    required TranscriptUploadProvider provider,
  }) async {
    final config = _providerConfig(provider);

    if (config == null) {
      throw StateError('Model selection is not available for this analysis provider.');
    }

    final apiKey = (await secureSecretsService.read(config.apiKeySecret))?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw StateError('${config.providerDisplayName} API key is not configured. Add it in Settings > AI.');
    }

    final response = await _client.get(
      config.baseUri.resolve('models'),
      headers: <String, String>{
        'authorization': 'Bearer $apiKey',
        'accept': 'application/json',
        'user-agent': Environment.userAgent(),
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EpisodeAnalysisHttpException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Model list response was not a JSON object.');
    }

    final data = decoded['data'];

    if (data is! List) {
      throw const FormatException('Model list response did not contain a data array.');
    }

    final modelIds = data
        .whereType<Map>()
        .map((rawModel) => rawModel['id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (modelIds.isEmpty) {
      throw StateError('No models were returned by ${config.providerDisplayName}.');
    }

    return List<String>.unmodifiable(modelIds);
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  _EpisodeAnalysisProviderConfig? _providerConfig(TranscriptUploadProvider provider) {
    switch (provider) {
      case TranscriptUploadProvider.openAi:
        return _EpisodeAnalysisProviderConfig(
          providerDisplayName: 'OpenAI',
          apiKeySecret: openAiApiKeySecret,
          baseUri: 'https://api.openai.com/v1/',
        );
      case TranscriptUploadProvider.grok:
        return _EpisodeAnalysisProviderConfig(
          providerDisplayName: 'Grok',
          apiKeySecret: grokApiKeySecret,
          baseUri: 'https://api.x.ai/v1/',
        );
      case TranscriptUploadProvider.disabled:
      case TranscriptUploadProvider.analysisBackend:
        return null;
    }
  }
}

class _EpisodeAnalysisProviderConfig {
  final String providerDisplayName;
  final String apiKeySecret;
  final Uri baseUri;

  _EpisodeAnalysisProviderConfig({
    required this.providerDisplayName,
    required this.apiKeySecret,
    required String baseUri,
  }) : baseUri = Uri.parse(baseUri);
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

class _EpisodeNarrativeContext {
  final String summary;
  final String guidance;
  final bool historicalAdsArePartOfStory;
  final bool currentPodcastSponsorshipLikely;
  final List<String> narrativeFlags;

  const _EpisodeNarrativeContext({
    required this.summary,
    required this.guidance,
    required this.historicalAdsArePartOfStory,
    required this.currentPodcastSponsorshipLikely,
    required this.narrativeFlags,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'summary': summary,
      'guidance': guidance,
      'historical_ads_are_part_of_story': historicalAdsArePartOfStory,
      'current_podcast_sponsorship_likely': currentPodcastSponsorshipLikely,
      'narrative_flags': narrativeFlags,
    };
  }
}

List<EpisodeAnalysisTranscriptWindow> transcriptWindowsFromPayload(
  EpisodeAnalysisTranscriptPayload payload, {
  int maxWindowChars = 12000,
  int overlapCues = 4,
}) {
  return transcriptWindowsFromCues(
    transcriptCuesFromPayload(payload),
    maxWindowChars: maxWindowChars,
    overlapCues: overlapCues,
  );
}

List<Subtitle> transcriptCuesFromPayload(EpisodeAnalysisTranscriptPayload payload) {
  final transcript = EpisodeAnalysisTranscriptCodec.fromDto(
    EpisodeAnalysisTranscriptDto(
      format: payload.format,
      content: payload.content,
    ),
  );
  return List<Subtitle>.unmodifiable(transcript.subtitles);
}

List<EpisodeAnalysisTranscriptWindow> transcriptWindowsFromCues(
  List<Subtitle> cues, {
  int maxWindowChars = 12000,
  int overlapCues = 4,
}) {
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

List<Subtitle> _sampleEpisodeContextCues(List<Subtitle> cues) {
  if (cues.isEmpty) {
    return const <Subtitle>[];
  }

  final orderedIndexes = <int>[
    ...List<int>.generate(
      cues.length < OpenAIEpisodeAnalysisService._episodeContextBoundaryCueCount
          ? cues.length
          : OpenAIEpisodeAnalysisService._episodeContextBoundaryCueCount,
      (index) => index,
      growable: false,
    ),
    ...List<int>.generate(
      cues.length,
      (index) => index,
      growable: false,
    ).where((index) {
      final text = cues[index].data?.trim() ?? '';
      return text.isNotEmpty && OpenAIEpisodeAnalysisService._episodeContextPriorityPattern.hasMatch(text);
    }),
    ..._distributedCueIndexes(
      cues.length,
      OpenAIEpisodeAnalysisService._episodeContextDistributedCueCount,
    ),
    ...List<int>.generate(
      cues.length < OpenAIEpisodeAnalysisService._episodeContextBoundaryCueCount
          ? 0
          : OpenAIEpisodeAnalysisService._episodeContextBoundaryCueCount,
      (index) => cues.length - OpenAIEpisodeAnalysisService._episodeContextBoundaryCueCount + index,
      growable: false,
    ),
  ];
  final selectedIndexes = <int>{};
  var currentChars = 0;

  for (final index in orderedIndexes) {
    if (selectedIndexes.contains(index) || index < 0 || index >= cues.length) {
      continue;
    }

    final cue = cues[index];
    final cueChars = (cue.data?.length ?? 0) + 32;

    if (selectedIndexes.isNotEmpty && currentChars + cueChars > OpenAIEpisodeAnalysisService._episodeContextMaxChars) {
      continue;
    }

    selectedIndexes.add(index);
    currentChars += cueChars;
  }

  final sortedIndexes = selectedIndexes.toList()..sort();
  return List<Subtitle>.unmodifiable(sortedIndexes.map((index) => cues[index]));
}

Iterable<int> _distributedCueIndexes(int cueCount, int sampleCount) sync* {
  if (cueCount <= 0 || sampleCount <= 0) {
    return;
  }

  if (cueCount <= sampleCount) {
    for (var index = 0; index < cueCount; index++) {
      yield index;
    }

    return;
  }

  for (var sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
    final ratio = sampleCount == 1 ? 0.0 : sampleIndex / (sampleCount - 1);
    yield (ratio * (cueCount - 1)).round();
  }
}

List<Subtitle> _excerptCuesForSegment(
  List<Subtitle> cues,
  AdSegment segment,
) {
  if (cues.isEmpty) {
    return const <Subtitle>[];
  }

  var firstIndex = cues.indexWhere((cue) => (cue.end ?? cue.start).inMilliseconds >= segment.startMs);

  if (firstIndex == -1) {
    firstIndex = 0;
  }

  var lastIndex = firstIndex;

  while (lastIndex + 1 < cues.length && cues[lastIndex + 1].start.inMilliseconds <= segment.endMs) {
    lastIndex++;
  }

  final startIndex = firstIndex - OpenAIEpisodeAnalysisService._candidateReviewExcerptRadius < 0
      ? 0
      : firstIndex - OpenAIEpisodeAnalysisService._candidateReviewExcerptRadius;
  final endIndex = lastIndex + OpenAIEpisodeAnalysisService._candidateReviewExcerptRadius + 1 > cues.length
      ? cues.length
      : lastIndex + OpenAIEpisodeAnalysisService._candidateReviewExcerptRadius + 1;

  return List<Subtitle>.unmodifiable(cues.sublist(startIndex, endIndex));
}

Map<String, dynamic> _cueToMap(Subtitle cue) {
  return <String, dynamic>{
    'start_ms': cue.start.inMilliseconds,
    'end_ms': cue.end?.inMilliseconds ?? cue.start.inMilliseconds,
    'text': cue.data?.trim() ?? '',
  };
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

bool _requireBool(
  Object? value, {
  required String field,
}) {
  if (value is bool) {
    return value;
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
