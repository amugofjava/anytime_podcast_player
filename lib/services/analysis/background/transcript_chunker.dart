// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/transcript.dart';

/// A contiguous time-bounded slice of a transcript fed to one Gemma-4
/// function-call invocation. See spec §4.6.
class TranscriptChunk {
  final int index;
  final int startMs;
  final int endMs;
  final List<Subtitle> subtitles;

  const TranscriptChunk({
    required this.index,
    required this.startMs,
    required this.endMs,
    required this.subtitles,
  });

  /// Subtitle text joined with newlines — the canonical form passed to the
  /// model. Callers that need richer framing can re-read [subtitles].
  String get text => subtitles.map((s) => s.data ?? '').where((s) => s.isNotEmpty).join('\n');

  @override
  String toString() => 'TranscriptChunk(index: $index, startMs: $startMs, endMs: $endMs, subtitles: ${subtitles.length})';
}

/// Splits a transcript into 30-minute chunks with 30-second boundary overlap
/// per spec §4.6. A subtitle is included in a chunk if any portion of its
/// `[start, end]` range overlaps the chunk's effective `[startMs, endMs]`.
class TranscriptChunker {
  static const int chunkDurationMs = 30 * 60 * 1000;
  static const int overlapMs = 30 * 1000;

  const TranscriptChunker._();

  static List<TranscriptChunk> chunk(List<Subtitle> subtitles) {
    if (subtitles.isEmpty) {
      return const <TranscriptChunk>[];
    }

    final sorted = List<Subtitle>.from(subtitles)
      ..sort((a, b) => a.start.inMilliseconds.compareTo(b.start.inMilliseconds));

    var maxEndMs = 0;
    for (final subtitle in sorted) {
      final end = subtitle.end?.inMilliseconds ?? subtitle.start.inMilliseconds;
      if (end > maxEndMs) {
        maxEndMs = end;
      }
    }
    if (maxEndMs <= 0) {
      return const <TranscriptChunk>[];
    }

    if (maxEndMs <= chunkDurationMs) {
      return List<TranscriptChunk>.unmodifiable(<TranscriptChunk>[
        TranscriptChunk(
          index: 0,
          startMs: 0,
          endMs: maxEndMs,
          subtitles: List<Subtitle>.unmodifiable(sorted),
        ),
      ]);
    }

    final chunkCount = (maxEndMs + chunkDurationMs - 1) ~/ chunkDurationMs;
    final chunks = <TranscriptChunk>[];

    for (var i = 0; i < chunkCount; i++) {
      final nominalStart = i * chunkDurationMs;
      final nominalEnd = (i + 1) * chunkDurationMs > maxEndMs ? maxEndMs : (i + 1) * chunkDurationMs;

      final effectiveStart = i == 0 ? 0 : nominalStart - overlapMs;
      final effectiveEnd = i == chunkCount - 1
          ? nominalEnd
          : (nominalEnd + overlapMs > maxEndMs ? maxEndMs : nominalEnd + overlapMs);

      final included = <Subtitle>[];
      for (final subtitle in sorted) {
        final startMs = subtitle.start.inMilliseconds;
        final endMs = subtitle.end?.inMilliseconds ?? startMs;
        if (startMs < effectiveEnd && endMs > effectiveStart) {
          included.add(subtitle);
        }
      }

      chunks.add(TranscriptChunk(
        index: i,
        startMs: effectiveStart,
        endMs: effectiveEnd,
        subtitles: List<Subtitle>.unmodifiable(included),
      ));
    }

    return List<TranscriptChunk>.unmodifiable(chunks);
  }
}
