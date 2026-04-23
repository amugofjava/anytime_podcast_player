// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/app_settings.dart';

/// Single source of truth (spec CON-003) for Gemma model download URLs,
/// expected file formats, and approximate sizes. Only `.litertlm` is supported
/// by `flutter_gemma` on Android.
class AnalysisModelCatalog {
  const AnalysisModelCatalog._();

  /// Stable identifier reported back in `EpisodeAnalysisRecord.modelId`.
  static String modelIdFor(BackgroundAnalysisLocalModel variant) {
    switch (variant) {
      case BackgroundAnalysisLocalModel.gemma4E2B:
        return 'gemma-3n-E2B-it-litert-lm';
      case BackgroundAnalysisLocalModel.gemma4E4B:
        return 'gemma-3n-E4B-it-litert-lm';
    }
  }

  /// Hugging Face download URL for the Gemma weights.
  static Uri downloadUrlFor(BackgroundAnalysisLocalModel variant) {
    switch (variant) {
      case BackgroundAnalysisLocalModel.gemma4E2B:
        return Uri.parse(
          'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview'
          '/resolve/main/gemma-3n-E2B-it-int4.task',
        );
      case BackgroundAnalysisLocalModel.gemma4E4B:
        return Uri.parse(
          'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview'
          '/resolve/main/gemma-3n-E4B-it-int4.task',
        );
    }
  }

  /// Approximate on-disk size. Surfaced in the first-launch confirmation
  /// dialog (REQ-007).
  static int approximateSizeBytesFor(BackgroundAnalysisLocalModel variant) {
    switch (variant) {
      case BackgroundAnalysisLocalModel.gemma4E2B:
        return 2400 * 1024 * 1024;
      case BackgroundAnalysisLocalModel.gemma4E4B:
        return 4300 * 1024 * 1024;
    }
  }

  /// Approximate on-disk size of the bundled Whisper model (ggml tiny.en).
  /// Combined with the Gemma variant in the first-launch confirmation dialog
  /// (REQ-007).
  static const int whisperApproximateSizeBytes = 75 * 1024 * 1024;

  /// Total disk cost the user is about to incur — Whisper + selected Gemma.
  static int totalApproximateSizeBytesFor(BackgroundAnalysisLocalModel variant) {
    return whisperApproximateSizeBytes + approximateSizeBytesFor(variant);
  }

  /// Short human-readable format (e.g. `"2.5 GB"`). Rounds to one decimal at
  /// GB-scale and integer at MB-scale.
  static String formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) {
      final gbValue = bytes / gb;
      return '${gbValue.toStringAsFixed(1)} GB';
    }
    if (bytes >= mb) {
      final mbValue = (bytes / mb).round();
      return '$mbValue MB';
    }
    return '$bytes B';
  }
}
