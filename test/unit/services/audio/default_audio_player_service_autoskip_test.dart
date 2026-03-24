// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/services/audio/default_audio_player_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findActiveAdSegment', () {
    const segments = <AdSegment>[
      AdSegment(startMs: 1000, endMs: 5000),
      AdSegment(startMs: 8000, endMs: 12000),
    ];

    test('matches a segment when playback enters the boundary', () {
      final match = findActiveAdSegment(
        positionMs: 1000,
        adSegments: segments,
      );

      expect(match, segments.first);
    });

    test('returns null once playback reaches the segment end', () {
      final match = findActiveAdSegment(
        positionMs: 5000,
        adSegments: segments,
      );

      expect(match, isNull);
    });

    test('handles short gaps without selecting the wrong segment', () {
      final match = findActiveAdSegment(
        positionMs: 7000,
        adSegments: segments,
      );

      expect(match, isNull);
    });
  });

  group('resolveAdSkipTargetMs', () {
    test('seeks slightly past the ad segment end', () {
      final target = resolveAdSkipTargetMs(
        segment: const AdSegment(startMs: 1000, endMs: 5000),
        durationMs: 20000,
      );

      expect(target, 5500);
    });

    test('clamps the seek target to the episode duration', () {
      final target = resolveAdSkipTargetMs(
        segment: const AdSegment(startMs: 17000, endMs: 19800),
        durationMs: 20000,
      );

      expect(target, 20000);
    });
  });

  group('hasExitedSkippedAdSegment', () {
    const segment = AdSegment(startMs: 1000, endMs: 5000);

    test('treats positions near the segment end as cleared', () {
      final cleared = hasExitedSkippedAdSegment(
        positionMs: 4800,
        segment: segment,
      );

      expect(cleared, isTrue);
    });

    test('does not treat positions well inside the segment as cleared', () {
      final cleared = hasExitedSkippedAdSegment(
        positionMs: 4300,
        segment: segment,
      );

      expect(cleared, isFalse);
    });
  });
}
