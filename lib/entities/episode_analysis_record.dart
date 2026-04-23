// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';

/// Stable provider identifiers for analysis records. See spec §2.
class AnalysisProvider {
  static const String whisperGemma4 = 'whisper+gemma4';
  static const String geminiAudio = 'gemini-audio';
  static const String openAi = 'openai';
  static const String grok = 'grok';
  static const String backend = 'backend';

  /// Migration-only provider used when backfilling pre-phase-1 `adSegments`
  /// into the new history schema.
  static const String legacyUnknown = 'legacy-unknown';

  const AnalysisProvider._();
}

/// A persisted result of one ad-analysis run for one episode. See spec §4.2.
class EpisodeAnalysisRecord {
  /// Stable identifier for the analysis provider that produced this record.
  final String provider;

  /// Model variant or identifier the provider used (e.g. 'gemma-4-e2b').
  final String modelId;

  /// Epoch milliseconds when the record was completed.
  final int completedAtMs;

  /// The ad segments produced by this analysis.
  final List<AdSegment> adSegments;

  /// True iff this record is the active analysis for the episode.
  final bool active;

  /// Optional free-form status notes ('partial', 'degraded', 'ok').
  final String? status;

  const EpisodeAnalysisRecord({
    required this.provider,
    required this.modelId,
    required this.completedAtMs,
    required this.adSegments,
    required this.active,
    this.status,
  });

  EpisodeAnalysisRecord copyWith({
    String? provider,
    String? modelId,
    int? completedAtMs,
    List<AdSegment>? adSegments,
    bool? active,
    String? status,
  }) {
    return EpisodeAnalysisRecord(
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      adSegments: adSegments ?? this.adSegments,
      active: active ?? this.active,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provider': provider,
      'modelId': modelId,
      'completedAtMs': completedAtMs.toString(),
      'active': active ? 'true' : 'false',
      'status': status,
      'adSegments': adSegments.map((s) => s.toMap()).toList(growable: false),
    };
  }

  static EpisodeAnalysisRecord fromMap(Map<String, dynamic> map) {
    final segments = <AdSegment>[];

    final rawSegments = map['adSegments'];
    if (rawSegments is List) {
      for (var segment in rawSegments) {
        if (segment is Map) {
          segments.add(AdSegment.fromMap(Map<String, dynamic>.from(segment)));
        }
      }
    }

    return EpisodeAnalysisRecord(
      provider: map['provider'] as String? ?? AnalysisProvider.legacyUnknown,
      modelId: map['modelId'] as String? ?? '',
      completedAtMs: _parseInt(map['completedAtMs']),
      adSegments: segments,
      active: map['active'] == 'true' || map['active'] == true,
      status: map['status'] as String?,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeAnalysisRecord &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          modelId == other.modelId &&
          completedAtMs == other.completedAtMs &&
          active == other.active &&
          status == other.status &&
          _listEquals(adSegments, other.adSegments);

  @override
  int get hashCode =>
      provider.hashCode ^
      modelId.hashCode ^
      completedAtMs.hashCode ^
      active.hashCode ^
      status.hashCode ^
      adSegments.hashCode;

  static bool _listEquals(List<AdSegment> left, List<AdSegment> right) {
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
