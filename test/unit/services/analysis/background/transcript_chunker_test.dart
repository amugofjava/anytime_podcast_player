// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/background/transcript_chunker.dart';
import 'package:flutter_test/flutter_test.dart';

Subtitle _sub({required int index, required int startMs, required int endMs, String? text}) {
  return Subtitle(
    index: index,
    start: Duration(milliseconds: startMs),
    end: Duration(milliseconds: endMs),
    data: text ?? 'line $index',
  );
}

const int thirtyMinMs = 30 * 60 * 1000;
const int overlapMs = 30 * 1000;

void main() {
  group('TranscriptChunker.chunk', () {
    test('empty input returns no chunks', () {
      expect(TranscriptChunker.chunk(const <Subtitle>[]), isEmpty);
    });

    test('single short transcript fits in one chunk with no overlap', () {
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 0, endMs: 5_000),
        _sub(index: 2, startMs: 5_000, endMs: 600_000),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks, hasLength(1));
      expect(chunks.single.startMs, 0);
      expect(chunks.single.endMs, 600_000);
      expect(chunks.single.subtitles, hasLength(2));
    });

    test('exactly 30 minutes fits in one chunk', () {
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 0, endMs: thirtyMinMs),
      ];
      final chunks = TranscriptChunker.chunk(subtitles);
      expect(chunks, hasLength(1));
      expect(chunks.single.endMs, thirtyMinMs);
    });

    test('two-chunk split extends each by 30s overlap toward the neighbor', () {
      // 40-minute episode → chunks [0, 30min] and [30min, 40min], each extended
      // 30s into the adjacent chunk. Spec §4.6 + edge case 9.3.
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 0, endMs: 60_000),
        _sub(index: 2, startMs: 1_785_000, endMs: 1_820_000), // 29:45–30:20
        _sub(index: 3, startMs: 2_300_000, endMs: 2_400_000),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks, hasLength(2));
      expect(chunks[0].startMs, 0);
      expect(chunks[0].endMs, thirtyMinMs + overlapMs);
      expect(chunks[1].startMs, thirtyMinMs - overlapMs);
      expect(chunks[1].endMs, 2_400_000);
    });

    test('boundary-straddling subtitle appears in both adjacent chunks', () {
      // Subtitle 29:45–30:20 sits across the 30:00 boundary. With 30s overlap
      // on each side, both chunks must contain it.
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 1_785_000, endMs: 1_820_000), // 29:45–30:20
        _sub(index: 2, startMs: 2_300_000, endMs: 2_400_000),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks, hasLength(2));
      expect(chunks[0].subtitles.any((s) => s.index == 1), isTrue);
      expect(chunks[1].subtitles.any((s) => s.index == 1), isTrue);
    });

    test('subtitle fully inside one chunk only appears in that chunk', () {
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 60_000, endMs: 120_000),
        _sub(index: 2, startMs: 2_200_000, endMs: 2_300_000),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks, hasLength(2));
      expect(chunks[0].subtitles.map((s) => s.index), [1]);
      expect(chunks[1].subtitles.map((s) => s.index), [2]);
    });

    test('three-chunk split: middle chunk has overlap on both sides', () {
      // 70-minute transcript → three chunks: [0,30], [30,60], [60,70].
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 0, endMs: 30_000),
        _sub(index: 2, startMs: thirtyMinMs, endMs: thirtyMinMs + 30_000),
        _sub(index: 3, startMs: 2 * thirtyMinMs, endMs: 2 * thirtyMinMs + 30_000),
        _sub(index: 4, startMs: 4_000_000, endMs: 4_200_000),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks, hasLength(3));
      // Middle chunk: nominal [30min, 60min] → effective [29:30, 60:30].
      expect(chunks[1].startMs, thirtyMinMs - overlapMs);
      expect(chunks[1].endMs, 2 * thirtyMinMs + overlapMs);
      // Last chunk: no tail overlap beyond transcript.
      expect(chunks[2].endMs, 4_200_000);
    });

    test('chunks expose joined text for convenience', () {
      final subtitles = <Subtitle>[
        _sub(index: 1, startMs: 0, endMs: 1_000, text: 'hello'),
        _sub(index: 2, startMs: 1_000, endMs: 2_000, text: 'world'),
      ];

      final chunks = TranscriptChunker.chunk(subtitles);

      expect(chunks.single.text, 'hello\nworld');
    });

    test('returned list is unmodifiable', () {
      final subtitles = <Subtitle>[_sub(index: 1, startMs: 0, endMs: 1_000)];
      final chunks = TranscriptChunker.chunk(subtitles);
      expect(() => chunks.add(chunks.first), throwsUnsupportedError);
    });
  });
}
