// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/analysis/background/background_analysis_progress.dart';
import 'package:anytime/services/analysis/background/supersession_resolver.dart';
import 'package:logging/logging.dart';

/// See spec §4.4. Public interface used by enrollment call sites and the UI
/// to observe queue state and per-episode progress.
///
/// The concrete implementation additionally exposes worker-side hooks
/// (`reportProgress`, `commitResult`) that are intentionally *not* on the
/// interface — they belong to the background worker's implementation surface.
abstract class BackgroundAnalysisService {
  /// Enqueue an episode for background analysis. Idempotent per [episodeId].
  Future<void> enqueue(String episodeId);

  /// Remove an episode from the queue if present. No-op if not queued.
  Future<void> dequeue(String episodeId);

  /// Current queue snapshot, ordered by enqueue time.
  Future<List<String>> listQueued();

  /// Broadcast stream of progress updates published by the worker.
  Stream<BackgroundAnalysisProgress> progress();
}

/// Repository-backed `BackgroundAnalysisService` used in app runtime and in
/// tests. The queue is persisted via the Sembast repository (Phase 1);
/// progress is published over a single broadcast `StreamController`.
class DefaultBackgroundAnalysisService implements BackgroundAnalysisService {
  static final _log = Logger('BackgroundAnalysisProgress');
  final Repository _repository;
  final StreamController<BackgroundAnalysisProgress> _progress =
      StreamController<BackgroundAnalysisProgress>.broadcast();

  DefaultBackgroundAnalysisService(this._repository);

  @override
  Future<void> enqueue(String episodeId) async {
    await _repository.enqueueBackgroundAnalysis(episodeId);
    _progress.add(BackgroundAnalysisProgress(
      episodeId: episodeId,
      stage: BackgroundAnalysisStage.queued,
    ));
  }

  @override
  Future<void> dequeue(String episodeId) => _repository.dequeueBackgroundAnalysis(episodeId);

  @override
  Future<List<String>> listQueued() => _repository.listBackgroundAnalysisQueue();

  @override
  Stream<BackgroundAnalysisProgress> progress() => _progress.stream;

  /// Worker-side hook. Publishes a progress update to the broadcast stream.
  void reportProgress(BackgroundAnalysisProgress update) {
    _progress.add(update);
    final pct = update.fraction != null ? ' ${(update.fraction! * 100).toStringAsFixed(0)}%' : '';
    final msg = update.message != null ? ' — ${update.message}' : '';
    _log.fine('[${update.stage.name}]$pct$msg (episode=${update.episodeId})');
  }

  /// Worker-side hook. Persists [record] under supersession rules (spec §4.3)
  /// and keeps `Episode.adSegments` (CON-005) in sync with the active record.
  ///
  /// Returns the committed record (with its final `active` flag applied).
  Future<EpisodeAnalysisRecord> commitResult({
    required String episodeId,
    required EpisodeAnalysisRecord record,
  }) async {
    final existing = await _repository.findAnalysisHistory(episodeId);
    final updated = SupersessionResolver.resolve(existing: existing, newRecord: record);

    await _repository.replaceAnalysisHistory(episodeId, updated);

    final committed = updated.last;

    final episode = await _repository.findEpisodeByGuid(episodeId);
    if (episode != null) {
      final active = _findActive(updated);
      episode.adSegments = active?.adSegments ?? const <AdSegment>[];
      await _repository.saveEpisode(episode);
    }

    return committed;
  }

  /// Releases underlying stream resources.
  Future<void> dispose() => _progress.close();

  static EpisodeAnalysisRecord? _findActive(List<EpisodeAnalysisRecord> history) {
    for (final record in history) {
      if (record.active) {
        return record;
      }
    }
    return null;
  }
}
