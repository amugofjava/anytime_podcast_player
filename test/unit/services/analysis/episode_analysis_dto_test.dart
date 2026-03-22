// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/services/analysis/ad_segment_normalizer.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpisodeAnalysis DTOs', () {
    test('parses submit response', () {
      final response = EpisodeAnalysisSubmitResponse.fromMap(<String, dynamic>{
        'job_id': 'job-123',
        'status': 'queued',
        'cached': false,
      });

      expect(response.jobId, 'job-123');
      expect(response.status, EpisodeAnalysisJobStatus.queued);
      expect(response.cached, isFalse);
    });

    test('parses completed response and normalizes ad segments', () {
      final response = EpisodeAnalysisStatusResponse.fromMap(<String, dynamic>{
        'job_id': 'job-456',
        'status': 'completed',
        'cached': true,
        'transcript': <String, dynamic>{
          'format': 'srt',
          'content': '1\n00:00:00,000 --> 00:00:01,000\nHello',
        },
        'ad_segments': <Map<String, dynamic>>[
          <String, dynamic>{
            'start_ms': -1000,
            'end_ms': 5000,
            'reason': 'preroll',
            'confidence': 0.4,
            'flags': <String>['music'],
          },
          <String, dynamic>{
            'start_ms': 4000,
            'end_ms': 610500,
            'reason': 'midroll',
            'confidence': '0.9',
            'flags': <String>['cta'],
          },
          <String, dynamic>{
            'start_ms': 2000,
            'end_ms': 2000,
            'reason': 'invalid',
            'confidence': 0.1,
            'flags': <String>[],
          },
        ],
      });

      expect(response.jobId, 'job-456');
      expect(response.status, EpisodeAnalysisJobStatus.completed);
      expect(response.cached, isTrue);
      expect(response.transcript!.format, 'srt');
      expect(response.adSegments, hasLength(1));
      expect(response.adSegments.single.startMs, 0);
      expect(response.adSegments.single.endMs, 610500);
      expect(response.adSegments.single.confidence, 0.9);
      expect(response.adSegments.single.flags, contains(AdSegmentNormalizer.suspiciousDurationFlag));
    });

    test('parses failed response without transcript payload', () {
      final response = EpisodeAnalysisStatusResponse.fromMap(<String, dynamic>{
        'job_id': 'job-789',
        'status': 'failed',
        'error': 'backend timeout',
      });

      expect(response.status, EpisodeAnalysisJobStatus.failed);
      expect(response.error, 'backend timeout');
      expect(response.transcript, isNull);
      expect(response.adSegments, isEmpty);
    });
  });
}
