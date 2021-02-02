// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

enum TransitionState {
  play,
  pause,
  stop,
  fastforward,
  rewind,
}

enum LifecyleState {
  pause,
  resume,
}

/// A BLoC to handle interactions between the audio service and the client.
/// A lot of the code in here could do with moving to the audio player service.
class AudioBloc extends Bloc {
  final log = Logger('AudioBloc');

  /// Stream for our currently playing Episode
  final BehaviorSubject<Episode> _playSubject = BehaviorSubject<Episode>();

  /// Move from one playing state to another such as from paused to play
  final PublishSubject<TransitionState> _transitionPlayingState = PublishSubject<TransitionState>();

  /// Sink to update our position
  final PublishSubject<double> _transitionPosition = PublishSubject<double>();

  /// Handle lifecycle events
  final PublishSubject<LifecyleState> _lifecycleSubject = PublishSubject<LifecyleState>(sync: true);

  /// Handles persisting data to storage.
  final AudioPlayerService audioPlayerService;

  final PublishSubject<double> _playbackSpeedSubject = PublishSubject<double>();

  StreamSubscription<dynamic> _positionSubscription;

  AudioBloc({
    @required this.audioPlayerService,
  }) {
    /// Listen for transition events from the client.
    _handlePlayingStateTransitions();

    /// Listen for events requesting the start of a new episode.
    _handleEpisodeRequests();

    /// Listen for requests to move the play position within the episode.
    _handlePositionTransitions();

    /// Listen for lifecycle pause or resume states
    _handleLifecycleTransitions();

    /// Listen for playback speed changes
    _handlePlaybackSpeedTransitions();
  }

  /// Listens to events from the UI (or any client) to transition from one
  /// audio state to another. For example, to pause the current playback
  /// a [TransitionState.pause] event should be sent. To ensure the underlying
  /// audio service processes one state request at a time we push events
  /// on to a queue and execute them sequentially. Each state maps to a call
  /// to the Audio Service plugin.
  void _handlePlayingStateTransitions() {
    _transitionPlayingState.asyncMap((event) => Future.value(event)).listen((state) async {
      switch (state) {
        case TransitionState.play:
          await audioPlayerService.play();
          break;
        case TransitionState.pause:
          await audioPlayerService.pause();
          break;
        case TransitionState.fastforward:
          await audioPlayerService.fastforward();
          break;
        case TransitionState.rewind:
          await audioPlayerService.rewind();
          break;
        case TransitionState.stop:
          await audioPlayerService.stop();
          break;
      }
    });
  }

  /// Setup a listener for episode requests and then connect to the
  /// underlying audio service.
  void _handleEpisodeRequests() async {
    _playSubject.listen((episode) => audioPlayerService.playEpisode(episode: episode, resume: true));
  }

  /// Listen for requests to change the position of the current episode.
  void _handlePositionTransitions() async {
    _transitionPosition.listen((pos) async {
      await audioPlayerService.seek(position: pos.toInt());
    });
  }

  void _handleLifecycleTransitions() async {
    _lifecycleSubject.listen((state) async {
      if (state == LifecyleState.resume) {
        await audioPlayerService.resume();
      } else if (state == LifecyleState.pause) {
        await audioPlayerService.suspend();
      }
    });
  }

  void _handlePlaybackSpeedTransitions() {
    _playbackSpeedSubject.listen((double speed) async {
      await audioPlayerService.setPlaybackSpeed(speed);
    });
  }

  /// Play the specified track now
  void Function(Episode) get play => _playSubject.add;

  /// Transition the state from connecting, to play, pause, stop etc.
  void Function(TransitionState) get transitionState => _transitionPlayingState.add;

  /// Move the play position.
  void Function(double) get transitionPosition => _transitionPosition.sink.add;

  void Function(LifecyleState) get transitionLifecycleState => _lifecycleSubject.sink.add;

  /// Get the current playing state
  Stream<AudioState> get playingState => audioPlayerService.playingState;

  /// Get the current playing track
  Stream<Episode> get nowPlaying => _playSubject.stream;

  /// Get position and percentage played of playing episode
  Stream<PositionState> get playPosition => audioPlayerService.playPosition;

  /// Change playback speed
  void Function(double) get playbackSpeed => _playbackSpeedSubject.sink.add;

  @override
  void dispose() {
    _playSubject.close();
    _transitionPlayingState.close();
    _transitionPosition.close();
    _lifecycleSubject.close();
    _playbackSpeedSubject.close();
    _positionSubscription.cancel();
  }
}
