// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/state/episode_state.dart';

/// An abstract class that represent the actions supported by the chosen
/// database or storage implementation.
abstract class Repository {
  /// General
  Future<void> close();

  /// Podcasts
  Future<Podcast?> findPodcastById(num id);

  Future<Podcast?> findPodcastByGuid(String guid);

  Future<Podcast> savePodcast(Podcast podcast, {bool withEpisodes = true});

  Future<void> deletePodcast(Podcast podcast);

  Future<List<Podcast>> subscriptions();

  /// Episodes
  Future<List<Episode>> findAllEpisodes();

  Future<Episode?> findEpisodeById(int id);

  Future<Episode?> findEpisodeByGuid(String guid);

  Future<List<Episode>> findEpisodesByPodcastGuid(
    String pguid, {
    PodcastEpisodeFilter filter = PodcastEpisodeFilter.none,
    PodcastEpisodeSort sort = PodcastEpisodeSort.none,
  });

  Future<Map<String, int>> findEpisodeCountByPodcast({
    PodcastEpisodeFilter filter = PodcastEpisodeFilter.none,
  });

  Future<int> findEpisodeCountByPodcastGuid(
    String pguid, {
    PodcastEpisodeFilter filter = PodcastEpisodeFilter.none,
    PodcastEpisodeSort sort = PodcastEpisodeSort.none,
  });

  Future<Episode?> findEpisodeByTaskId(String taskId);

  Future<Episode?> findLatestPlayableEpisode(Podcast podcast);

  Future<Episode?> findNextUnplayedEpisode(Podcast podcast);

  Future<Episode?> findNextPlayableEpisode(Episode episode);

  Future<Episode> saveEpisode(Episode episode, [bool updateIfSame = false]);

  Future<List<Episode>> saveEpisodes(List<Episode> episodes, [bool updateIfSame = false]);

  Future<void> deleteEpisode(Episode episode);

  Future<void> deleteEpisodes(List<Episode> episodes);

  Future<List<Episode>> findDownloadsByPodcastGuid(String pguid);

  Future<List<Episode>> findDownloads();

  Future<Transcript?> findTranscriptById(int id);

  Future<Transcript> saveTranscript(Transcript transcript);

  Future<void> deleteTranscriptById(int id);

  Future<void> deleteTranscriptsById(List<int> id);

  /// Queue
  Future<void> saveQueue(List<Episode> episodes);

  Future<List<Episode>> loadQueue();

  /// Analysis history (spec §4.2).
  Future<void> saveAnalysisRecord(String episodeId, EpisodeAnalysisRecord record);

  Future<List<EpisodeAnalysisRecord>> findAnalysisHistory(String episodeId);

  Future<void> deleteAnalysisHistory(String episodeId);

  Future<void> replaceAnalysisHistory(String episodeId, List<EpisodeAnalysisRecord> records);

  /// Background analysis queue (spec §4.4).
  Future<void> enqueueBackgroundAnalysis(String episodeId);

  Future<void> dequeueBackgroundAnalysis(String episodeId);

  Future<List<String>> listBackgroundAnalysisQueue();

  /// Background analysis stage checkpoint (spec §4.4, AC-004).
  ///
  /// The stage token is free-form but stable; see `BackgroundAnalysisWorker`
  /// for the values it writes. `null` means "no checkpoint recorded".
  Future<void> recordBackgroundAnalysisCheckpoint(String episodeId, String stage);

  Future<String?> findBackgroundAnalysisCheckpoint(String episodeId);

  Future<void> clearBackgroundAnalysisCheckpoint(String episodeId);

  /// Event listeners
  late Stream<Podcast> podcastListener;
  late Stream<EpisodeState> episodeListener;
}
