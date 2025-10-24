// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
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

  /// Event listeners
  late Stream<Podcast> podcastListener;
  late Stream<EpisodeState> episodeListener;
}
