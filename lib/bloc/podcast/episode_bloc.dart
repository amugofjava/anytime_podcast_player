// Copyright 2020-2021 Ben Hills. All rights reserved.
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

  /// Add to sink to delete the passed [Episode] from storage.
  final PublishSubject<Episode> _deleteDownload = PublishSubject<Episode>();

  /// Add to sink to toggle played status of the [Episode].
  final PublishSubject<Episode> _togglePlayed = PublishSubject<Episode>();

  /// Stream of currently downloaded episodes
  Stream<BlocState<List<Episode>>> _downloadsOutput;

  /// Cache of our currently downloaded episodes.
  List<Episode> _episodes;

  EpisodeBloc({
    @required this.podcastService,
    @required this.audioPlayerService,
  }) {
    _init();
  }

  void _init() {
    _downloadsOutput = _downloadsInput.switchMap<BlocState<List<Episode>>>((bool silent) => _downloads(silent));

    _handleDeleteDownloads();

    _handleMarkAsPlayed();

    _listenEpisodeEvents();
  }

  void _handleDeleteDownloads() async {
    _deleteDownload.stream.listen((episode) async {
      await podcastService.deleteDownload(episode);

      /// If we are attempting to delete the episode we are currently playing, we need to stop the audio.
      if (audioPlayerService.nowPlaying == episode) {
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
        var episode = _episodes.indexOf(state.episode);

        if (episode != -1) {
          fetchDownloads(true);
        }
      }
    });
  }

  Stream<BlocState<List<Episode>>> _downloads(bool silent) async* {
    if (!silent) {
      yield BlocLoadingState();
    }

    _episodes = await podcastService.loadDownloads();

    yield BlocPopulatedState<List<Episode>>(_episodes);
  }

  @override
  void dispose() {
    _downloadsInput.close();
    _deleteDownload.close();
    _togglePlayed.close();
  }

  void Function(bool) get fetchDownloads => _downloadsInput.add;
  Stream<BlocState<List<Episode>>> get downloads => _downloadsOutput;

  void Function(Episode) get deleteDownload => _deleteDownload.add;
  void Function(Episode) get togglePlayed => _togglePlayed.add;
}
