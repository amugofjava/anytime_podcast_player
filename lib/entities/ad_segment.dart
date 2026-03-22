// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Persisted analysis metadata describing a detected ad segment.
class AdSegment {
  final int startMs;
  final int endMs;
  final String? reason;
  final double? confidence;
  final List<String> flags;

  const AdSegment({
    required this.startMs,
    required this.endMs,
    this.reason,
    this.confidence,
    this.flags = const <String>[],
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startMs': startMs.toString(),
      'endMs': endMs.toString(),
      'reason': reason,
      'confidence': confidence?.toString(),
      'flags': flags,
    };
  }

  static AdSegment fromMap(Map<String, dynamic> adSegment) {
    return AdSegment(
      startMs: _parseInt(adSegment['startMs']),
      endMs: _parseInt(adSegment['endMs']),
      reason: adSegment['reason'] as String?,
      confidence: _parseDouble(adSegment['confidence']),
      flags: (adSegment['flags'] as List?)?.map((flag) => flag.toString()).toList(growable: false) ?? const <String>[],
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is String && value.isNotEmpty && value != 'null') {
      return int.parse(value);
    }

    return 0;
  }

  static double? _parseDouble(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String && value.isNotEmpty && value != 'null') {
      return double.parse(value);
    }

    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdSegment &&
          runtimeType == other.runtimeType &&
          startMs == other.startMs &&
          endMs == other.endMs &&
          reason == other.reason &&
          confidence == other.confidence &&
          _listEquals(flags, other.flags);

  @override
  int get hashCode => startMs.hashCode ^ endMs.hashCode ^ reason.hashCode ^ confidence.hashCode ^ flags.hashCode;

  static bool _listEquals(List<String> left, List<String> right) {
    if (identical(left, right)) {
      return true;
    }

    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }

    return true;
  }
}
