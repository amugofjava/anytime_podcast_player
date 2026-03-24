// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/openai_episode_analysis_service.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAIEpisodeAnalysisService', () {
    test('submits and completes an analysis job using the OpenAI provider', () async {
      late http.Request capturedRequest;

      final client = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode(<String, dynamic>{
            'choices': <Map<String, dynamic>>[
              <String, dynamic>{
                'message': <String, dynamic>{
                  'content': jsonEncode(<String, dynamic>{
                    'ad_segments': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'start_ms': 1000,
                        'end_ms': 5000,
                        'reason': 'preroll',
                        'confidence': 0.91,
                        'flags': <String>['music_bed'],
                      },
                    ],
                  }),
                },
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: client,
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-1',
          podcast: 'Podcast',
          title: 'Episode 1',
          contentUrl: 'https://cdn.example.com/episode.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:05,000\nThis episode is sponsored by Example Co.',
        ),
      );

      expect(submit.jobId, startsWith(OpenAIEpisodeAnalysisService.jobIdPrefix));
      expect(submit.status, EpisodeAnalysisJobStatus.queued);

      EpisodeAnalysisStatusResponse? status;

      for (var attempt = 0; attempt < 10; attempt++) {
        status = await service.poll(jobId: submit.jobId);

        if (status.status != EpisodeAnalysisJobStatus.processing && status.status != EpisodeAnalysisJobStatus.queued) {
          break;
        }

        await Future<void>.delayed(Duration.zero);
      }

      expect(status, isNotNull);
      expect(status!.status, EpisodeAnalysisJobStatus.completed);
      expect(status.adSegments, hasLength(1));
      expect(status.adSegments.single.startMs, 1000);
      expect(status.adSegments.single.endMs, 5000);
      expect(capturedRequest.headers['authorization'], 'Bearer sk-test');

      final requestBody = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(requestBody['model'], 'gpt-4.1-mini');
      expect(requestBody['response_format']['type'], 'json_schema');
    });

    test('requires an API key before submission', () async {
      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(),
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        () => service.submit(
          episode: Episode(
            guid: 'ep-2',
            podcast: 'Podcast',
            title: 'Episode 2',
            contentUrl: 'https://cdn.example.com/episode-2.mp3',
          ),
          transcript: EpisodeAnalysisTranscriptPayload(
            format: 'srt',
            provenance: 'localAi',
            content: '1\n00:00:00,000 --> 00:00:01,000\nHello',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('maps 401 failures to a readable API key error', () async {
      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'error': <String, dynamic>{
                'message': 'Incorrect API key provided.',
              },
            }),
            401,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-401',
          podcast: 'Podcast',
          title: 'Episode 401',
          contentUrl: 'https://cdn.example.com/episode-401.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:05,000\nSponsored content.',
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(status.status, EpisodeAnalysisJobStatus.failed);
      expect(status.error, 'OpenAI API key was rejected. Check the key in Settings > AI.');
    });

    test('maps 429 failures to a readable rate limit error', () async {
      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'error': <String, dynamic>{
                'message': 'Rate limit exceeded.',
              },
            }),
            429,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-429',
          podcast: 'Podcast',
          title: 'Episode 429',
          contentUrl: 'https://cdn.example.com/episode-429.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:05,000\nSponsored content.',
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(status.status, EpisodeAnalysisJobStatus.failed);
      expect(status.error, 'OpenAI rate limit reached. Wait a moment and try again.');
    });

    test('maps network timeouts to a readable error', () async {
      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async => throw TimeoutException('request timed out')),
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-timeout',
          podcast: 'Podcast',
          title: 'Episode Timeout',
          contentUrl: 'https://cdn.example.com/episode-timeout.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:05,000\nSponsored content.',
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(status.status, EpisodeAnalysisJobStatus.failed);
      expect(status.error, 'OpenAI analysis timed out. Try again.');
    });

    test('fails closed on malformed structured output', () async {
      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'choices': <Map<String, dynamic>>[
                <String, dynamic>{
                  'message': <String, dynamic>{
                    'content': jsonEncode(<String, dynamic>{
                      'ad_segments': <Object>[
                        'not-a-segment',
                      ],
                    }),
                  },
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-malformed',
          podcast: 'Podcast',
          title: 'Episode Malformed',
          contentUrl: 'https://cdn.example.com/episode-malformed.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:05,000\nSponsored content.',
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(status.status, EpisodeAnalysisJobStatus.failed);
      expect(status.error, 'OpenAI returned malformed structured output. No ad segments were saved.');
      expect(status.adSegments, isEmpty);
    });
  });

  group('transcriptWindowsFromPayload', () {
    test('splits large transcripts into overlapping windows', () {
      final windows = transcriptWindowsFromPayload(
        EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: List<String>.generate(
            8,
            (index) =>
                '${index + 1}\n00:00:0$index,000 --> 00:00:0${index + 1},000\nCue ${index + 1} words words words',
          ).join('\n\n'),
        ),
        maxWindowChars: 160,
        overlapCues: 2,
      );

      expect(windows.length, greaterThan(1));
      expect(windows.every((window) => window.cues.isNotEmpty), isTrue);
      expect(windows.first.startMs, 0);
      expect(windows.last.endMs, greaterThan(windows.first.endMs));
      expect(windows[1].startMs, greaterThanOrEqualTo(windows.first.startMs));
    });
  });
}

Future<EpisodeAnalysisStatusResponse> _awaitFinalStatus(
  OpenAIEpisodeAnalysisService service,
  String jobId,
) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final status = await service.poll(jobId: jobId);

    if (status.status != EpisodeAnalysisJobStatus.processing && status.status != EpisodeAnalysisJobStatus.queued) {
      return status;
    }

    await Future<void>.delayed(Duration.zero);
  }

  fail('Expected OpenAI analysis job $jobId to complete.');
}

class _FakeSecureSecretsService implements SecureSecretsService {
  final String? apiKey;

  _FakeSecureSecretsService({
    this.apiKey,
  });

  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => apiKey;

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {}
}
