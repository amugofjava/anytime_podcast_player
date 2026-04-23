// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode_analysis_record.dart';

/// Implements the supersession precedence in spec §4.3.
///
/// Given the existing `analysisHistory` for an episode and a newly completed
/// record, returns the updated history. Never deletes records (REQ-011); at
/// most one record is marked `active = true` (spec §4.2 invariants).
class SupersessionResolver {
  const SupersessionResolver._();

  /// Provider priority. Higher priority records win ties.
  ///
  /// - `whisper+gemma4`: the background path is the canonical source (2).
  /// - `gemini-audio`: the on-demand path (1).
  /// - `openai` / `grok` / `backend` / `legacy-unknown`: replaceable legacy (0).
  static int _priority(String provider) {
    switch (provider) {
      case AnalysisProvider.whisperGemma4:
        return 2;
      case AnalysisProvider.geminiAudio:
        return 1;
      default:
        return 0;
    }
  }

  /// Returns `true` iff [newRecord] should become the active record given the
  /// currently active record (or null if none).
  static bool shouldActivate(EpisodeAnalysisRecord? currentActive, EpisodeAnalysisRecord newRecord) {
    if (currentActive == null) {
      return true;
    }
    if (currentActive.provider == newRecord.provider) {
      return true;
    }
    return _priority(newRecord.provider) >= _priority(currentActive.provider);
  }

  /// Computes the updated history list after committing [newRecord].
  ///
  /// If [newRecord] wins supersession, all existing records are demoted to
  /// `active = false` and [newRecord] is appended with `active = true`.
  /// Otherwise, existing records are preserved as-is and [newRecord] is
  /// appended with `active = false`.
  ///
  /// The returned list is an unmodifiable snapshot; append-order is
  /// `existing ++ [newRecord]`.
  static List<EpisodeAnalysisRecord> resolve({
    required List<EpisodeAnalysisRecord> existing,
    required EpisodeAnalysisRecord newRecord,
  }) {
    final currentActive = _findActive(existing);
    final activate = shouldActivate(currentActive, newRecord);

    final result = <EpisodeAnalysisRecord>[];
    for (final record in existing) {
      if (activate && record.active) {
        result.add(record.copyWith(active: false));
      } else {
        result.add(record);
      }
    }
    result.add(newRecord.copyWith(active: activate));

    return List<EpisodeAnalysisRecord>.unmodifiable(result);
  }

  static EpisodeAnalysisRecord? _findActive(List<EpisodeAnalysisRecord> history) {
    for (final record in history) {
      if (record.active) {
        return record;
      }
    }
    return null;
  }
}
