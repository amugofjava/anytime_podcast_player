// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';

/// Merges ad segments returned from overlapping Gemma-4 chunk analyses per
/// spec §4.6.
///
/// Differs from `AdSegmentNormalizer` (which post-processes arbitrary provider
/// output with a 30s merge gap): this merger targets the chunk-boundary case
/// only, with a 5s gap threshold and a 10s minimum-duration filter.
class AdSegmentChunkMerger {
  static const int mergeGapMs = 5 * 1000;
  static const int minDurationMs = 10 * 1000;

  const AdSegmentChunkMerger._();

  /// Returns a new list where overlapping-or-near-adjacent segments have been
  /// merged and final segments shorter than [minDurationMs] have been removed.
  static List<AdSegment> merge(Iterable<AdSegment> segments) {
    final sanitized = <AdSegment>[];
    for (final segment in segments) {
      if (segment.endMs <= segment.startMs) {
        continue;
      }
      sanitized.add(segment);
    }
    if (sanitized.isEmpty) {
      return const <AdSegment>[];
    }

    sanitized.sort((a, b) {
      final byStart = a.startMs.compareTo(b.startMs);
      if (byStart != 0) {
        return byStart;
      }
      return a.endMs.compareTo(b.endMs);
    });

    final merged = <AdSegment>[sanitized.first];
    for (final segment in sanitized.skip(1)) {
      final current = merged.last;
      if (segment.startMs <= current.endMs + mergeGapMs) {
        merged[merged.length - 1] = _mergePair(current, segment);
      } else {
        merged.add(segment);
      }
    }

    return List<AdSegment>.unmodifiable(
      merged.where((s) => s.endMs - s.startMs >= minDurationMs),
    );
  }

  static AdSegment _mergePair(AdSegment left, AdSegment right) {
    final startMs = left.startMs < right.startMs ? left.startMs : right.startMs;
    final endMs = left.endMs > right.endMs ? left.endMs : right.endMs;
    return AdSegment(
      startMs: startMs,
      endMs: endMs,
      reason: _longerReason(left.reason, right.reason),
      confidence: _maxConfidence(left.confidence, right.confidence),
      flags: _mergeFlags(left.flags, right.flags),
    );
  }

  static String? _longerReason(String? left, String? right) {
    if (left == null || left.isEmpty) return right;
    if (right == null || right.isEmpty) return left;
    return right.length > left.length ? right : left;
  }

  static double? _maxConfidence(double? left, double? right) {
    if (left == null) return right;
    if (right == null) return left;
    return left > right ? left : right;
  }

  static List<String> _mergeFlags(List<String> left, List<String> right) {
    final out = <String>[];
    for (final f in left) {
      if (!out.contains(f)) out.add(f);
    }
    for (final f in right) {
      if (!out.contains(f)) out.add(f);
    }
    return List<String>.unmodifiable(out);
  }
}
