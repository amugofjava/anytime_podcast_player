// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:anytime/services/download/mobile_download_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

enum PodcastEvent {
  subscribe,
  unsubscribe,
  markAllPlayed,
  clearAllPlayed,
}

/// The BLoC provides access to the details of a given Podcast. It takes a feed
/// URL and creates a [Podcast] instance for the URL. It also listen and handles
/// requests to download episodes.
class PodcastBloc extends Bloc {
  final log = Logger('PodcastBloc');
  final PodcastService podcastService;
  final AudioPlayerService audioPlayerService;
  final DownloadService downloadService;
  final PublishSubject<Feed> _podcastFeed = PublishSubject<Feed>(sync: true);

  /// Add to sink to start an Episode download
  final PublishSubject<Episode> _downloadEpisode = PublishSubject<Episode>();

  /// Listen to this subject's stream to obtain list of current subscriptions.
  PublishSubject<List<Podcast>> _subscriptions;

  /// Stream containing details of the current podcast.
  final BehaviorSubject<BlocState<Podcast>> _podcastStream = BehaviorSubject<BlocState<Podcast>>(sync: true);

  /// A separate stream that allows us to listen to changes in the podcast's episodes.
  final BehaviorSubject<List<Episode>> _episodesStream = BehaviorSubject<List<Episode>>();

  /// Receives subscription and mark/clear as played events.
  final PublishSubject<PodcastEvent> _podcastEvent = PublishSubject<PodcastEvent>();

  Podcast _podcast;
  List<Episode> _episodes = [];

  bool first = true;

  PodcastBloc({
    @required this.podcastService,
    @required this.audioPlayerService,
    @required this.downloadService,
  }) {
    _init();
  }

  void _init() {
    /// When someone starts listening for subscriptions, load them.
    _subscriptions = PublishSubject<List<Podcast>>(onListen: _loadSubscriptions);

    /// When we receive a load podcast request, send back a BlocState.
    _listenPodcastLoad();

    /// Listen to an Episode download request
    _listenDownloadRequest();

    /// Listen to active downloads
    _listenDownloads();

    /// Listen to episode change events sent by the [Repository]
    _listenEpisodeRepositoryEvents();

    /// Listen to Podcast subscription, mark/cleared played events
    _listenPodcastStateEvents();
  }

  void _loadSubscriptions() async {
    _subscriptions.add(await podcastService.subscriptions());
  }

  /// Sets up a listener to handle Podcast load requests. We first push a
  /// [BlocLoadingState] to indicate that the Podcast is being loaded,
  /// before calling the [PodcastService] to handle the loading. Once
  /// loaded, we extract the episodes from the Podcast and push them
  /// out via the episode stream before pushing a [BlocPopulatedState]
  /// containing the Podcast.
  void _listenPodcastLoad() async {
    _podcastFeed.listen((feed) async {
      _podcastStream.sink.add(BlocLoadingState<Podcast>());

      _episodes = [];
      _episodesStream.add(_episodes);

      try {
        _podcast = await podcastService.loadPodcast(
          podcast: feed.podcast,
          refresh: feed.refresh,
        );

        _episodes = _podcast?.episodes;
        _episodesStream.add(_episodes);

        _podcastStream.sink.add(BlocPopulatedState<Podcast>(_podcast));
      } catch (e) {
        // For now we'll assume a network error as this is the most likely.
        _podcastStream.sink.add(BlocErrorState<Podcast>());
        log.fine('Error loading podcast', e);
      }
    });
  }

  /// Sets up a listener to handle requests to download an episode.
  void _listenDownloadRequest() {
    _downloadEpisode.listen((Episode e) async {
      log.fine('Received download request for ${e.title}');

      // To prevent a pause between the user tapping the download icon and
      // the UI showing some sort of progress, set it to queued now.
      var episode = _episodes.firstWhere((ep) => ep.guid == e.guid, orElse: () => null);

      episode.downloadState = DownloadState.queued;

      // Update the stream.
      _episodesStream.add(_episodes);

      // If this episode contains chapter, fetch them first.
      if (episode.hasChapters && episode.chaptersAreNotLoaded) {
        log.fine('This episode has some chapters! Let us load them: ${episode.chaptersUrl}');
        var chapters = await podcastService.loadChaptersByUrl(url: episode.chaptersUrl);

        e.chapters = chapters;

        await podcastService.saveEpisode(e);
      }

      var result = await downloadService.downloadEpisode(e);

      // If there was an error downloading the episode, push an error state
      // and then restore to none.
      if (!result) {
        episode.downloadState = DownloadState.failed;
        _episodesStream.add(_episodes);
        episode.downloadState = DownloadState.none;
        _episodesStream.add(_episodes);
      }
    });
  }

  /// Sets up a listener to listen for status updates from any currently
  /// downloading episode. If the ID of a current download matches that
  /// of an episode currently in use, we update the status of the episode
  /// and push it back into the episode stream.
  void _listenDownloads() {
    // Listen to download progress
    MobileDownloadService.downloadProgress.listen((s) async {
      final downloadable = await downloadService.findEpisodeByTaskId(s.id);

      if (downloadable != null) {
        // Now update our records
        downloadable.downloadPercentage = s.percentage;
        downloadable.downloadState = s.status;

        // If the download matches a current episode push the update back into the stream.
        var episode = _episodes.firstWhere((e) => e.downloadTaskId == s.id, orElse: () => null);

        if (episode != null) {
          episode.downloadPercentage = s.percentage;
          episode.downloadState = s.status;

          // Update the stream.
          _episodesStream.add(_episodes);

          await podcastService.saveEpisode(episode);
        }
      } else {
        log.severe('Downloadable not found with id ${s.id}');
      }
    });
  }

  /// Listen to episode change events sent by the [Repository]
  void _listenEpisodeRepositoryEvents() {
    podcastService.episodeListener.listen((state) {
      // Do we have this episode?
      var episode = _episodes.indexOf(state.episode);

      if (episode != -1) {
        _episodes[episode] = state.episode;
        _episodesStream.add(_episodes);
      }
    });
  }

  void _listenPodcastStateEvents() async {
    _podcastEvent.listen((event) async {
      switch (event) {
        case PodcastEvent.subscribe:
          _podcast = await podcastService.subscribe(_podcast);
          _podcastStream.add(BlocPopulatedState<Podcast>(_podcast));
          _loadSubscriptions();
          break;
        case PodcastEvent.unsubscribe:
          await podcastService.unsubscribe(_podcast);
          _podcast.id = null;
          _podcastStream.add(BlocPopulatedState<Podcast>(_podcast));
          _loadSubscriptions();
          break;
        case PodcastEvent.markAllPlayed:
          _podcast.episodes.forEach((e) {
            e.played = true;
            e.position = 0;
          });
          await podcastService.save(_podcast);
          break;
        case PodcastEvent.clearAllPlayed:
          _podcast.episodes.forEach((e) {
            e.played = false;
            e.position = 0;
          });
          await podcastService.save(_podcast);
          break;
      }

      _episodesStream.add(_podcast.episodes);
    });
  }

  @override
  void detach() {
    downloadService.dispose();
  }

  @override
  void dispose() {
    _podcastFeed.close();
    _downloadEpisode.close();
    _subscriptions.close();
    _podcastStream.close();
    _episodesStream.close();
    _podcastEvent.close();
    MobileDownloadService.downloadProgress.close();
    downloadService.dispose();
    super.dispose();
  }

  /// Sink to load a podcast.
  void Function(Feed) get load => _podcastFeed.add;

  /// Sink to trigger an episode download.
  void Function(Episode) get downloadEpisode => _downloadEpisode.add;

  void Function(PodcastEvent) get podcastEvent => _podcastEvent.add;

  /// Stream containing the current state of the podcast load.
  Stream<BlocState<Podcast>> get details => _podcastStream.stream;

  /// Stream containing the current list of Podcast episodes.
  Stream<List<Episode>> get episodes => _episodesStream;

  /// Obtain a list of podcast currently subscribed to.
  Stream<List<Podcast>> get subscriptions => _subscriptions.stream;
}
