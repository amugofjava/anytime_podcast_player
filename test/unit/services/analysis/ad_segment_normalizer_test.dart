// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/services/analysis/ad_segment_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdSegmentNormalizer', () {
    test('clamps negatives, discards invalid ranges, merges overlaps, and flags suspicious duration', () {
      final normalized = AdSegmentNormalizer.normalize([
        const AdSegment(
          startMs: -5000,
          endMs: 10000,
          reason: 'preroll',
          confidence: 0.4,
          flags: <String>['music'],
        ),
        const AdSegment(
          startMs: 8000,
          endMs: 700000,
          reason: 'midroll',
          confidence: 0.8,
          flags: <String>['cta'],
        ),
        const AdSegment(
          startMs: 15000,
          endMs: 15000,
          reason: 'invalid',
          confidence: 0.2,
        ),
        const AdSegment(
          startMs: -1000,
          endMs: -10,
          reason: 'invalid-negative',
          confidence: 0.2,
        ),
      ]);

      expect(normalized, hasLength(1));
      expect(normalized.single.startMs, 0);
      expect(normalized.single.endMs, 700000);
      expect(normalized.single.reason, 'preroll | midroll');
      expect(normalized.single.confidence, 0.8);
      expect(
          normalized.single.flags, containsAll(<String>['music', 'cta', AdSegmentNormalizer.suspiciousDurationFlag]));
    });

    test('keeps non-overlapping ranges separate and sorted', () {
      final normalized = AdSegmentNormalizer.normalize([
        const AdSegment(startMs: 90000, endMs: 100000, reason: 'later'),
        const AdSegment(startMs: 1000, endMs: 5000, reason: 'first'),
      ]);

      expect(normalized, hasLength(2));
      expect(normalized.first.reason, 'first');
      expect(normalized.last.reason, 'later');
    });

    test('merges touching boundaries and deduplicates flags', () {
      final normalized = AdSegmentNormalizer.normalize([
        const AdSegment(
          startMs: 1000,
          endMs: 5000,
          reason: 'first',
          confidence: 0.5,
          flags: <String>['music', 'cta'],
        ),
        const AdSegment(
          startMs: 5000,
          endMs: 9000,
          reason: 'second',
          confidence: 0.8,
          flags: <String>['cta', 'brand'],
        ),
      ]);

      expect(normalized, hasLength(1));
      expect(normalized.single.startMs, 1000);
      expect(normalized.single.endMs, 9000);
      expect(normalized.single.reason, 'first | second');
      expect(normalized.single.confidence, 0.8);
      expect(normalized.single.flags, <String>['music', 'cta', 'brand']);
    });

    test('merges ad segments separated by short gaps into one skip block', () {
      final normalized = AdSegmentNormalizer.normalize([
        const AdSegment(
          startMs: 3 * 60 * 1000 + 41 * 1000,
          endMs: 4 * 60 * 1000 + 19 * 1000,
          reason: 'first',
        ),
        const AdSegment(
          startMs: 4 * 60 * 1000 + 30 * 1000,
          endMs: 4 * 60 * 1000 + 48 * 1000,
          reason: 'second',
        ),
        const AdSegment(
          startMs: 4 * 60 * 1000 + 51 * 1000,
          endMs: 5 * 60 * 1000 + 18 * 1000,
          reason: 'third',
        ),
      ]);

      expect(normalized, hasLength(1));
      expect(normalized.single.startMs, 3 * 60 * 1000 + 41 * 1000);
      expect(normalized.single.endMs, 5 * 60 * 1000 + 18 * 1000);
      expect(normalized.single.reason, 'first | second | third');
    });

    test('keeps segments separate when the gap is at least 30 seconds', () {
      final normalized = AdSegmentNormalizer.normalize([
        const AdSegment(
          startMs: 1000,
          endMs: 5000,
          reason: 'first',
        ),
        const AdSegment(
          startMs: 35000,
          endMs: 45000,
          reason: 'second',
        ),
      ]);

      expect(normalized, hasLength(2));
      expect(normalized.first.reason, 'first');
      expect(normalized.last.reason, 'second');
    });
  });
}
