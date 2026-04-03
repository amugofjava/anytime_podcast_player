// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/openai_episode_analysis_service.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAIEpisodeAnalysisService', () {
    test('submits and completes an analysis job using the OpenAI provider', () async {
      final capturedRequests = <http.Request>[];

      final client = MockClient((request) async {
        capturedRequests.add(request);
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        final schemaName = requestBody['response_format']['json_schema']['name'] as String;

        switch (schemaName) {
          case 'episode_narrative_context':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'summary': 'Standard podcast episode with a present-day sponsorship read.',
                        'guidance': 'Treat direct sponsor reads as ads.',
                        'historical_ads_are_part_of_story': false,
                        'current_podcast_sponsorship_likely': true,
                        'narrative_flags': <String>['present_day_sponsorship'],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          case 'ad_segment_analysis':
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
          case 'ad_segment_review':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'decisions': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'candidate_id': 'candidate_0',
                            'keep': true,
                            'reason': 'Clear present-day sponsorship read.',
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
          default:
            fail('Unexpected schema name: $schemaName');
        }
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
      expect(capturedRequests, hasLength(3));
      expect(capturedRequests.first.headers['authorization'], 'Bearer sk-test');

      final firstRequestBody = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
      expect(firstRequestBody['model'], 'gpt-4.1-mini');
      expect(firstRequestBody['response_format']['type'], 'json_schema');

      final analysisRequest = capturedRequests.singleWhere((request) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return body['response_format']['json_schema']['name'] == 'ad_segment_analysis';
      });
      final analysisRequestBody = jsonDecode(analysisRequest.body) as Map<String, dynamic>;
      final analysisUserPayload =
          jsonDecode((analysisRequestBody['messages'] as List).last['content'] as String) as Map<String, dynamic>;

      expect(
        analysisUserPayload['episode_context']['summary'],
        'Standard podcast episode with a present-day sponsorship read.',
      );
      expect(analysisUserPayload['episode_context']['historical_ads_are_part_of_story'], isFalse);
    });

    test('filters archival commercials that are part of the episode narrative', () async {
      final capturedRequests = <http.Request>[];

      final client = MockClient((request) async {
        capturedRequests.add(request);
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        final schemaName = requestBody['response_format']['json_schema']['name'] as String;

        switch (schemaName) {
          case 'episode_narrative_context':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'summary': 'Documentary episode about 1950s radio that plays archival commercials.',
                        'guidance':
                            'Preserve vintage commercials when they are presented as historical source material.',
                        'historical_ads_are_part_of_story': true,
                        'current_podcast_sponsorship_likely': false,
                        'narrative_flags': <String>['archival_audio', 'historical_ads'],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          case 'ad_segment_analysis':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'ad_segments': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'start_ms': 60000,
                            'end_ms': 90000,
                            'reason': 'vintage radio spot',
                            'confidence': 0.74,
                            'flags': <String>['commercial_music'],
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
          case 'ad_segment_review':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'decisions': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'candidate_id': 'candidate_0',
                            'keep': false,
                            'reason': 'Archival commercial used as documentary source audio.',
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
          default:
            fail('Unexpected schema name: $schemaName');
        }
      });

      final service = OpenAIEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: client,
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-archive',
          podcast: 'Podcast',
          title: 'The 1957 Broadcast',
          contentUrl: 'https://cdn.example.com/episode-archive.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: [
            '1',
            '00:00:00,000 --> 00:00:05,000',
            'Today we are listening to a 1957 radio broadcast and its original sponsor spots.',
            '',
            '2',
            '00:01:00,000 --> 00:01:30,000',
            'Buy Silver Soap today at your neighborhood grocer.',
          ].join('\n'),
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(status.status, EpisodeAnalysisJobStatus.completed);
      expect(status.adSegments, isEmpty);

      final analysisRequest = capturedRequests.singleWhere((request) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return body['response_format']['json_schema']['name'] == 'ad_segment_analysis';
      });
      final analysisRequestBody = jsonDecode(analysisRequest.body) as Map<String, dynamic>;
      final analysisUserPayload =
          jsonDecode((analysisRequestBody['messages'] as List).last['content'] as String) as Map<String, dynamic>;

      expect(analysisUserPayload['episode_context']['historical_ads_are_part_of_story'], isTrue);
      expect(
        (analysisUserPayload['instructions'] as List<dynamic>).cast<String>(),
        contains(
          'Do not mark archival, historical, fictional, or example commercials that are part of the story or being discussed as content.',
        ),
      );
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

    test('uses the resolved model from settings at submit time', () async {
      final capturedRequests = <http.Request>[];
      final settingsService = _FakeAnalysisSettingsService(
        TranscriptUploadProvider.openAi,
        openAiAnalysisModel: 'gpt-4.1',
      );

      final client = MockClient((request) async {
        capturedRequests.add(request);
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        final schemaName = requestBody['response_format']['json_schema']['name'] as String;

        switch (schemaName) {
          case 'episode_narrative_context':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'summary': 'Episode with a sponsor read.',
                        'guidance': 'Keep sponsor reads.',
                        'historical_ads_are_part_of_story': false,
                        'current_podcast_sponsorship_likely': true,
                        'narrative_flags': <String>[],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          case 'ad_segment_analysis':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'ad_segments': <Map<String, dynamic>>[],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          default:
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'decisions': <Map<String, dynamic>>[],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
        }
      });

      final service = ConfigurableEpisodeAnalysisService(
        settingsService: settingsService,
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        openAiService: OpenAIEpisodeAnalysisService(
          secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
          client: client,
          modelResolver: () => settingsService.openAiAnalysisModel,
        ),
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-model',
          podcast: 'Podcast',
          title: 'Episode Model',
          contentUrl: 'https://cdn.example.com/model.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:00,000 --> 00:00:01,000\nHello',
        ),
      );
      await _awaitFinalStatus(service, submit.jobId);

      final firstRequestBody = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
      expect(firstRequestBody['model'], 'gpt-4.1');
    });
  });

  group('GrokEpisodeAnalysisService', () {
    test('submits against the xAI endpoint and completes with a Grok job id', () async {
      final capturedRequests = <http.Request>[];

      final client = MockClient((request) async {
        capturedRequests.add(request);
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        final schemaName = requestBody['response_format']['json_schema']['name'] as String;

        switch (schemaName) {
          case 'episode_narrative_context':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'summary': 'Narrative podcast with a modern sponsor read.',
                        'guidance': 'Keep direct sponsor reads.',
                        'historical_ads_are_part_of_story': false,
                        'current_podcast_sponsorship_likely': true,
                        'narrative_flags': <String>['present_day_sponsorship'],
                      }),
                    },
                  },
                ],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          case 'ad_segment_analysis':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'ad_segments': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'start_ms': 1000,
                            'end_ms': 3000,
                            'reason': 'host_read',
                            'confidence': 0.83,
                            'flags': <String>['cta'],
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
          case 'ad_segment_review':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'choices': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': <String, dynamic>{
                      'content': jsonEncode(<String, dynamic>{
                        'decisions': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'candidate_id': 'candidate_0',
                            'keep': true,
                            'reason': 'Direct sponsor read for the listener.',
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
          default:
            fail('Unexpected schema name: $schemaName');
        }
      });

      final service = GrokEpisodeAnalysisService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'xai-test'),
        client: client,
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-grok',
          podcast: 'Podcast',
          title: 'Episode Grok',
          contentUrl: 'https://cdn.example.com/episode-grok.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:01,000 --> 00:00:03,000\nUse code EXAMPLE to save today.',
        ),
      );

      final status = await _awaitFinalStatus(service, submit.jobId);

      expect(submit.jobId, startsWith(GrokEpisodeAnalysisService.jobIdPrefix));
      expect(status.status, EpisodeAnalysisJobStatus.completed);
      expect(status.adSegments, hasLength(1));
      expect(capturedRequests.first.url.toString(), 'https://api.x.ai/v1/chat/completions');

      final firstRequestBody = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
      expect(firstRequestBody['model'], 'grok-3');
      expect(capturedRequests.first.headers['authorization'], 'Bearer xai-test');
    });
  });

  group('ConfigurableEpisodeAnalysisService', () {
    test('routes Grok jobs to the Grok provider', () async {
      final openAiService = _SpyOpenAIEpisodeAnalysisService();
      final grokService = _SpyGrokEpisodeAnalysisService();
      final service = ConfigurableEpisodeAnalysisService(
        settingsService: _FakeAnalysisSettingsService(TranscriptUploadProvider.grok),
        secureSecretsService: _FakeSecureSecretsService(),
        openAiService: openAiService,
        grokService: grokService,
      );

      final submit = await service.submit(
        episode: Episode(
          guid: 'ep-router',
          podcast: 'Podcast',
          title: 'Router Episode',
          contentUrl: 'https://cdn.example.com/router.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          provenance: 'localAi',
          content: '1\n00:00:00,000 --> 00:00:01,000\nHello',
        ),
      );
      final status = await service.poll(jobId: submit.jobId);

      expect(submit.jobId, 'grok:job');
      expect(status.jobId, 'grok:job');
      expect(openAiService.submitCount, 0);
      expect(openAiService.pollCount, 0);
      expect(grokService.submitCount, 1);
      expect(grokService.pollCount, 1);
    });
  });

  group('EpisodeAnalysisModelCatalogService', () {
    test('lists OpenAI models from the provider endpoint', () async {
      final service = EpisodeAnalysisModelCatalogService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.openai.com/v1/models');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'gpt-4.1-mini'},
                <String, dynamic>{'id': 'gpt-4.1'},
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final models = await service.listModels(provider: TranscriptUploadProvider.openAi);

      expect(models, <String>['gpt-4.1', 'gpt-4.1-mini']);
    });

    test('lists Grok models from the provider endpoint', () async {
      final service = EpisodeAnalysisModelCatalogService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'xai-test'),
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.x.ai/v1/models');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'grok-4-1-fast-non-reasoning'},
                <String, dynamic>{'id': 'grok-4-1-fast-reasoning'},
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final models = await service.listModels(provider: TranscriptUploadProvider.grok);

      expect(models, <String>['grok-4-1-fast-non-reasoning', 'grok-4-1-fast-reasoning']);
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
  EpisodeAnalysisService service,
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

class _FakeAnalysisSettingsService implements SettingsService {
  final TranscriptUploadProvider _provider;
  final String _openAiAnalysisModel;
  final String _grokAnalysisModel;

  _FakeAnalysisSettingsService(
    this._provider, {
    String openAiAnalysisModel = 'gpt-4.1-mini',
    String grokAnalysisModel = 'grok-3',
  })  : _openAiAnalysisModel = openAiAnalysisModel,
        _grokAnalysisModel = grokAnalysisModel;

  @override
  TranscriptUploadProvider get transcriptUploadProvider => _provider;

  @override
  String get openAiAnalysisModel => _openAiAnalysisModel;

  @override
  String get grokAnalysisModel => _grokAnalysisModel;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyOpenAIEpisodeAnalysisService extends OpenAIEpisodeAnalysisService {
  int submitCount = 0;
  int pollCount = 0;

  _SpyOpenAIEpisodeAnalysisService()
      : super(
          secureSecretsService: _FakeSecureSecretsService(),
          client: MockClient((request) async => http.Response('{}', 500)),
        );

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    submitCount++;
    return EpisodeAnalysisSubmitResponse(jobId: 'openai:job');
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({required String jobId}) async {
    pollCount++;
    return EpisodeAnalysisStatusResponse(
      jobId: jobId,
      status: EpisodeAnalysisJobStatus.completed,
    );
  }

  @override
  void close() {}
}

class _SpyGrokEpisodeAnalysisService extends GrokEpisodeAnalysisService {
  int submitCount = 0;
  int pollCount = 0;

  _SpyGrokEpisodeAnalysisService()
      : super(
          secureSecretsService: _FakeSecureSecretsService(),
          client: MockClient((request) async => http.Response('{}', 500)),
        );

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    submitCount++;
    return EpisodeAnalysisSubmitResponse(jobId: 'grok:job');
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({required String jobId}) async {
    pollCount++;
    return EpisodeAnalysisStatusResponse(
      jobId: jobId,
      status: EpisodeAnalysisJobStatus.completed,
    );
  }

  @override
  void close() {}
}
