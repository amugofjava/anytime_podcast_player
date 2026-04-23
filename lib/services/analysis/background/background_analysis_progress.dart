// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Pipeline stages a queued episode can be in. See spec §4.4.
enum BackgroundAnalysisStage {
  queued,
  downloadingModel,
  transcribing,
  analyzing,
  completed,
  failed,
}

/// A progress update emitted by `BackgroundAnalysisService.progress()`.
class BackgroundAnalysisProgress {
  final String episodeId;
  final BackgroundAnalysisStage stage;

  /// 0..1 when the stage reports granular progress; null otherwise.
  final double? fraction;

  /// Optional human-readable detail (e.g. a failure reason).
  final String? message;

  const BackgroundAnalysisProgress({
    required this.episodeId,
    required this.stage,
    this.fraction,
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundAnalysisProgress &&
          runtimeType == other.runtimeType &&
          episodeId == other.episodeId &&
          stage == other.stage &&
          fraction == other.fraction &&
          message == other.message;

  @override
  int get hashCode => episodeId.hashCode ^ stage.hashCode ^ fraction.hashCode ^ message.hashCode;

  @override
  String toString() =>
      'BackgroundAnalysisProgress(episodeId: $episodeId, stage: $stage, fraction: $fraction, message: $message)';
}
