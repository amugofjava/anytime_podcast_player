// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// The BLoC provides access to [Episode] details outside the direct scope
/// of a [Podcast].
class EpisodeBloc extends Bloc {
  final log = Logger('EpisodeBloc');
  final PodcastService podcastService;
  final AudioPlayerService audioPlayerService;

  /// Add to sink to fetch list of current downloaded episodes.
  final BehaviorSubject<bool> _downloadsInput = BehaviorSubject<bool>();

  /// Add to sink to fetch list of current episodes.
  final BehaviorSubject<bool> _episodesInput = BehaviorSubject<bool>();

  /// Add to sink to delete the passed [Episode] from storage.
  final PublishSubject<Episode> _deleteDownload = PublishSubject<Episode>();

  /// Add to sink to toggle played status of the [Episode].
  final PublishSubject<Episode> _togglePlayed = PublishSubject<Episode>();

  /// Stream of currently downloaded episodes
  Stream<BlocState<List<Episode>>> _downloadsOutput;

  /// Stream of current episodes
  Stream<BlocState<List<Episode>>> _episodesOutput;

  /// Cache of our currently downloaded episodes.
  List<Episode> _episodes;

  EpisodeBloc({
    @required this.podcastService,
    @required this.audioPlayerService,
  }) {
    _init();
  }

  void _init() {
    _downloadsOutput = _downloadsInput.switchMap<BlocState<List<Episode>>>((bool silent) => _loadDownloads(silent));
    _episodesOutput = _episodesInput.switchMap<BlocState<List<Episode>>>((bool silent) => _loadEpisodes(silent));

    _handleDeleteDownloads();
    _handleMarkAsPlayed();
    _listenEpisodeEvents();
  }

  void _handleDeleteDownloads() async {
    _deleteDownload.stream.listen((episode) async {
      var nowPlaying = audioPlayerService.nowPlaying == episode;

      await podcastService.deleteDownload(episode);

      /// If we are attempting to delete the episode we are currently playing, we need to stop the audio.
      if (nowPlaying) {
        await audioPlayerService.stop();
      }

      fetchDownloads(true);
    });
  }

  void _handleMarkAsPlayed() async {
    _togglePlayed.stream.listen((episode) async {
      await podcastService.toggleEpisodePlayed(episode);

      fetchDownloads(true);
    });
  }

  void _listenEpisodeEvents() {
    podcastService.episodeListener.listen((state) {
      // Do we have this episode?
      if (_episodes != null) {
        var episode = _episodes.indexWhere((e) => e.pguid == state.episode.pguid && e.guid == state.episode.guid);
        bool downloadCompleted = state.episode.downloaded;
        if (episode == -1 && downloadCompleted) {
          fetchDownloads(true);
        }
      }
    });
  }

  Stream<BlocState<List<Episode>>> _loadDownloads(bool silent) async* {
    if (!silent) {
      yield BlocLoadingState();
    }

    _episodes = await podcastService.loadDownloads();

    yield BlocPopulatedState<List<Episode>>(results: _episodes);
  }

  Stream<BlocState<List<Episode>>> _loadEpisodes(bool silent) async* {
    if (!silent) {
      yield BlocLoadingState();
    }

    _episodes = await podcastService.loadEpisodes();

    yield BlocPopulatedState<List<Episode>>(results: _episodes);
  }

  @override
  void dispose() {
    _downloadsInput.close();
    _deleteDownload.close();
    _togglePlayed.close();
  }

  void Function(bool) get fetchDownloads => _downloadsInput.add;
  void Function(bool) get fetchEpisodes => _episodesInput.add;

  Stream<BlocState<List<Episode>>> get downloads => _downloadsOutput;
  Stream<BlocState<List<Episode>>> get episodes => _episodesOutput;

  void Function(Episode) get deleteDownload => _deleteDownload.add;
  void Function(Episode) get togglePlayed => _togglePlayed.add;
}
