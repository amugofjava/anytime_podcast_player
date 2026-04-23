// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/services/analysis/background/ad_segment_chunk_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdSegmentChunkMerger.merge', () {
    test('empty input returns empty list', () {
      expect(AdSegmentChunkMerger.merge(const <AdSegment>[]), isEmpty);
    });

    test('sorts out-of-order segments by start time', () {
      const second = AdSegment(startMs: 100_000, endMs: 150_000);
      const first = AdSegment(startMs: 10_000, endMs: 30_000);

      final merged = AdSegmentChunkMerger.merge([second, first]);

      expect(merged, hasLength(2));
      expect(merged[0].startMs, 10_000);
      expect(merged[1].startMs, 100_000);
    });

    test('drops zero-or-negative duration segments', () {
      const bogus = AdSegment(startMs: 50_000, endMs: 50_000);
      const inverted = AdSegment(startMs: 60_000, endMs: 55_000);
      const valid = AdSegment(startMs: 100_000, endMs: 120_000);

      final merged = AdSegmentChunkMerger.merge([bogus, inverted, valid]);

      expect(merged, hasLength(1));
      expect(merged.single.startMs, 100_000);
    });

    test('merges overlapping segments (chunk boundary case)', () {
      // 29:45–30:30 from chunk A and 29:45–30:20 from chunk B → 29:45–30:30.
      const chunkA = AdSegment(startMs: 1_785_000, endMs: 1_830_000, reason: 'ad_read');
      const chunkB = AdSegment(startMs: 1_785_000, endMs: 1_820_000, reason: 'ad');

      final merged = AdSegmentChunkMerger.merge([chunkA, chunkB]);

      expect(merged, hasLength(1));
      expect(merged.single.startMs, 1_785_000);
      expect(merged.single.endMs, 1_830_000);
    });

    test('merges segments within 5s gap', () {
      const a = AdSegment(startMs: 10_000, endMs: 30_000);
      const b = AdSegment(startMs: 34_000, endMs: 50_000); // 4s gap

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged, hasLength(1));
      expect(merged.single.startMs, 10_000);
      expect(merged.single.endMs, 50_000);
    });

    test('does NOT merge segments beyond the 5s gap', () {
      const a = AdSegment(startMs: 10_000, endMs: 30_000);
      const b = AdSegment(startMs: 36_000, endMs: 50_000); // 6s gap

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged, hasLength(2));
    });

    test('merged confidence is the max of inputs', () {
      const a = AdSegment(startMs: 10_000, endMs: 30_000, confidence: 0.6);
      const b = AdSegment(startMs: 12_000, endMs: 28_000, confidence: 0.9);

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged.single.confidence, 0.9);
    });

    test('merged reason is the longer input', () {
      const a = AdSegment(startMs: 10_000, endMs: 30_000, reason: 'ad');
      const b = AdSegment(startMs: 12_000, endMs: 28_000, reason: 'sponsor read for ACME');

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged.single.reason, 'sponsor read for ACME');
    });

    test('merged flags are unioned without duplicates', () {
      const a = AdSegment(startMs: 10_000, endMs: 30_000, flags: <String>['host_read']);
      const b = AdSegment(startMs: 12_000, endMs: 28_000, flags: <String>['host_read', 'preroll']);

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged.single.flags, <String>['host_read', 'preroll']);
    });

    test('segments shorter than 10s are filtered out', () {
      const tooShort = AdSegment(startMs: 0, endMs: 5_000);
      const justEnough = AdSegment(startMs: 100_000, endMs: 110_000);

      final merged = AdSegmentChunkMerger.merge([tooShort, justEnough]);

      expect(merged, hasLength(1));
      expect(merged.single.startMs, 100_000);
    });

    test('long non-adjacent segments survive unchanged', () {
      const a = AdSegment(startMs: 10_000, endMs: 40_000);
      const b = AdSegment(startMs: 100_000, endMs: 140_000);

      final merged = AdSegmentChunkMerger.merge([a, b]);

      expect(merged, hasLength(2));
      expect(merged[0].startMs, 10_000);
      expect(merged[1].startMs, 100_000);
    });

    test('returned list is unmodifiable', () {
      const segment = AdSegment(startMs: 0, endMs: 20_000);
      final merged = AdSegmentChunkMerger.merge([segment]);
      expect(() => merged.add(segment), throwsUnsupportedError);
    });
  });
}
