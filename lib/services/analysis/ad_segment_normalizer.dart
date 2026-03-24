// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';

class AdSegmentNormalizer {
  static const suspiciousDurationThresholdMs = 10 * 60 * 1000;
  static const suspiciousDurationFlag = 'suspicious_duration';
  static const mergeGapThresholdMs = 30 * 1000;

  static List<AdSegment> normalize(List<AdSegment> segments) {
    final sanitized = segments.map(_sanitize).whereType<AdSegment>().toList()
      ..sort((left, right) {
        final byStart = left.startMs.compareTo(right.startMs);

        if (byStart != 0) {
          return byStart;
        }

        return left.endMs.compareTo(right.endMs);
      });

    if (sanitized.isEmpty) {
      return const <AdSegment>[];
    }

    final merged = <AdSegment>[sanitized.first];

    for (final segment in sanitized.skip(1)) {
      final current = merged.removeLast();

      if (segment.startMs < current.endMs + mergeGapThresholdMs) {
        merged.add(_merge(current, segment));
      } else {
        merged
          ..add(current)
          ..add(segment);
      }
    }

    return List<AdSegment>.unmodifiable(merged.map(_flagSuspiciousDuration));
  }

  static AdSegment? _sanitize(AdSegment segment) {
    final startMs = segment.startMs < 0 ? 0 : segment.startMs;
    final endMs = segment.endMs < 0 ? 0 : segment.endMs;

    if (endMs <= startMs) {
      return null;
    }

    return AdSegment(
      startMs: startMs,
      endMs: endMs,
      reason: segment.reason,
      confidence: segment.confidence,
      flags: List<String>.unmodifiable(segment.flags),
    );
  }

  static AdSegment _merge(AdSegment left, AdSegment right) {
    return _flagSuspiciousDuration(
      AdSegment(
        startMs: left.startMs < right.startMs ? left.startMs : right.startMs,
        endMs: left.endMs > right.endMs ? left.endMs : right.endMs,
        reason: _mergeReason(left.reason, right.reason),
        confidence: _mergeConfidence(left.confidence, right.confidence),
        flags: _mergeFlags(left.flags, right.flags),
      ),
    );
  }

  static String? _mergeReason(String? left, String? right) {
    final reasons = <String>[];

    if (left != null && left.isNotEmpty) {
      reasons.add(left);
    }

    if (right != null && right.isNotEmpty && !reasons.contains(right)) {
      reasons.add(right);
    }

    if (reasons.isEmpty) {
      return null;
    }

    if (reasons.length == 1) {
      return reasons.first;
    }

    return reasons.join(' | ');
  }

  static double? _mergeConfidence(double? left, double? right) {
    if (left == null) {
      return right;
    }

    if (right == null) {
      return left;
    }

    return left > right ? left : right;
  }

  static List<String> _mergeFlags(List<String> left, List<String> right) {
    final flags = <String>[];

    for (final flag in [...left, ...right]) {
      if (!flags.contains(flag)) {
        flags.add(flag);
      }
    }

    return List<String>.unmodifiable(flags);
  }

  static AdSegment _flagSuspiciousDuration(AdSegment segment) {
    final durationMs = segment.endMs - segment.startMs;

    if (durationMs <= suspiciousDurationThresholdMs || segment.flags.contains(suspiciousDurationFlag)) {
      return segment;
    }

    return AdSegment(
      startMs: segment.startMs,
      endMs: segment.endMs,
      reason: segment.reason,
      confidence: segment.confidence,
      flags: List<String>.unmodifiable([...segment.flags, suspiciousDurationFlag]),
    );
  }
}
