// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('BackendEpisodeAnalysisService', () {
    test('submit posts backend payload with default force=false', () async {
      late http.Request capturedRequest;

      final client = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode(<String, dynamic>{
            'job_id': 'job-123',
            'status': 'queued',
            'cached': false,
          }),
          202,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = BackendEpisodeAnalysisService(
        client: client,
        baseUrl: 'https://backend.example.com/api',
      );

      final response = await service.submit(
        episode: Episode(
          guid: 'ep-1',
          podcast: 'Podcast',
          contentUrl: 'https://cdn.example.com/episode.mp3',
        ),
      );

      expect(response.jobId, 'job-123');
      expect(response.status, EpisodeAnalysisJobStatus.queued);
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.toString(), 'https://backend.example.com/api/episode-analysis');
      expect(capturedRequest.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(capturedRequest.body), <String, dynamic>{
        'episode_url': 'https://cdn.example.com/episode.mp3',
        'guid': 'ep-1',
        'force': false,
      });
    });

    test('submit includes transcript payload when provided', () async {
      late http.Request capturedRequest;

      final client = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode(<String, dynamic>{
            'job_id': 'job-234',
            'status': 'queued',
            'cached': true,
          }),
          202,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = BackendEpisodeAnalysisService(
        client: client,
        baseUrl: 'https://backend.example.com/api',
      );

      await service.submit(
        episode: Episode(
          guid: 'ep-2',
          podcast: 'Podcast',
          contentUrl: 'https://cdn.example.com/episode-2.mp3',
        ),
        transcript: EpisodeAnalysisTranscriptPayload(
          format: 'srt',
          content: '1\n00:00:00,000 --> 00:00:01,000\nHello',
        ),
      );

      expect(jsonDecode(capturedRequest.body), <String, dynamic>{
        'episode_url': 'https://cdn.example.com/episode-2.mp3',
        'guid': 'ep-2',
        'force': false,
        'transcript': <String, dynamic>{
          'format': 'srt',
          'content': '1\n00:00:00,000 --> 00:00:01,000\nHello',
        },
      });
    });

    test('poll reads completed response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://backend.example.com/api/episode-analysis/job-456');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'job_id': 'job-456',
            'status': 'completed',
            'cached': true,
            'transcript': <String, dynamic>{
              'format': 'srt',
              'content': '1\n00:00:00,000 --> 00:00:01,000\nHello',
            },
            'ad_segments': <Map<String, dynamic>>[
              <String, dynamic>{
                'start_ms': 5000,
                'end_ms': 10000,
                'reason': 'preroll',
                'confidence': 0.7,
                'flags': <String>['music'],
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = BackendEpisodeAnalysisService(
        client: client,
        baseUrl: 'https://backend.example.com/api/',
      );

      final response = await service.poll(jobId: 'job-456');

      expect(response.status, EpisodeAnalysisJobStatus.completed);
      expect(response.cached, isTrue);
      expect(response.transcript!.format, 'srt');
      expect(response.adSegments.single.startMs, 5000);
    });

    test('requires absolute backend url', () {
      expect(
        () => BackendEpisodeAnalysisService(
          client: MockClient((request) async => http.Response('{}', 200)),
          baseUrl: '/relative',
        ),
        throwsArgumentError,
      );
    });
  });
}
