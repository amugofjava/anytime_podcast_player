// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpisodeAnalysisRecord', () {
    test('round-trips through toMap / fromMap', () {
      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 1_714_000_000_000,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 10_000, endMs: 40_000, reason: 'midroll', confidence: 0.91),
          AdSegment(startMs: 180_000, endMs: 210_000, flags: <String>['host_read']),
        ],
        active: true,
        status: 'ok',
      );

      final restored = EpisodeAnalysisRecord.fromMap(record.toMap());

      expect(restored, record);
      expect(restored.provider, AnalysisProvider.whisperGemma4);
      expect(restored.modelId, 'gemma-4-e2b');
      expect(restored.completedAtMs, 1_714_000_000_000);
      expect(restored.active, isTrue);
      expect(restored.status, 'ok');
      expect(restored.adSegments.length, 2);
      expect(restored.adSegments[1].flags, <String>['host_read']);
    });

    test('defaults to legacy-unknown provider when missing', () {
      final restored = EpisodeAnalysisRecord.fromMap(<String, dynamic>{
        'modelId': '',
        'completedAtMs': '0',
        'active': 'false',
        'adSegments': <dynamic>[],
      });

      expect(restored.provider, AnalysisProvider.legacyUnknown);
      expect(restored.modelId, '');
      expect(restored.completedAtMs, 0);
      expect(restored.active, isFalse);
      expect(restored.status, isNull);
      expect(restored.adSegments, isEmpty);
    });

    test('accepts active stored either as bool or string', () {
      final fromBool = EpisodeAnalysisRecord.fromMap(<String, dynamic>{
        'provider': AnalysisProvider.geminiAudio,
        'modelId': 'gemini-3.1-flash-lite-preview',
        'completedAtMs': 1,
        'active': true,
        'adSegments': <dynamic>[],
      });
      final fromString = EpisodeAnalysisRecord.fromMap(<String, dynamic>{
        'provider': AnalysisProvider.geminiAudio,
        'modelId': 'gemini-3.1-flash-lite-preview',
        'completedAtMs': 1,
        'active': 'true',
        'adSegments': <dynamic>[],
      });

      expect(fromBool.active, isTrue);
      expect(fromString.active, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1-flash-lite-preview',
        completedAtMs: 42,
        adSegments: const <AdSegment>[],
        active: true,
      );

      final deactivated = record.copyWith(active: false);

      expect(deactivated.active, isFalse);
      expect(deactivated.provider, record.provider);
      expect(deactivated.modelId, record.modelId);
      expect(deactivated.completedAtMs, record.completedAtMs);
    });
  });
}
