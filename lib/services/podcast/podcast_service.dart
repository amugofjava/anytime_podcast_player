// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/api/podcast/podcast_api.dart';
import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:meta/meta.dart';
import 'package:podcast_search/podcast_search.dart' as pcast;

abstract class PodcastService {
  final PodcastApi api;
  final Repository repository;
  final SettingsService settingsService;

  PodcastService({
    @required this.api,
    @required this.repository,
    @required this.settingsService,
  });

  Future<pcast.SearchResult> search({
    @required String term,
    String country,
    String attribute,
    int limit,
    String language,
    int version = 0,
    bool explicit = false,
  });

  Future<pcast.SearchResult> charts({
    @required int size,
  });

  Future<Podcast> loadPodcast({
    @required Podcast podcast,
    bool refresh,
  });

  Future<Podcast> loadPodcastById({
    @required int id,
  });

  Future<List<Episode>> loadDownloads();

  Future<List<Chapter>> loadChaptersByUrl({@required String url});

  Future<void> deleteDownload(Episode episode);
  Future<void> toggleEpisodePlayed(Episode episode);
  Future<List<Podcast>> subscriptions();
  Future<Podcast> subscribe(Podcast podcast);
  Future<void> unsubscribe(Podcast podcast);
  Future<Podcast> save(Podcast podcast);
  Future<Episode> saveEpisode(Episode episode);

  /// Event listeners
  Stream<Podcast> podcastListener;
  Stream<EpisodeState> episodeListener;
}
