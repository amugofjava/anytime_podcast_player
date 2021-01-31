// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/persistable.dart';
import 'package:anytime/state/persistent_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';

/// This class acts as a go-between between [AudioService] and the chosen
/// audio player implementation.
///
/// For each transition, such as play, pause etc, this class will call the
/// equivalent function on the audio player and update the [AudioService]
/// state.
///
/// This version is backed by just_audio
class MobileAudioPlayer {
  final log = Logger('MobileAudioPlayer');
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Completer _completer = Completer<dynamic>();
  VoidCallback completionHandler;

  MobileAudioPlayer({this.completionHandler});

  StreamSubscription<ProcessingState> _playerStateSubscription;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  AudioProcessingState _playbackState;
  List<MediaControl> _controls = [];
  String _uri;
  int _position = 0;
  bool _isPlaying = false;
  bool _loadTrack = false;
  bool _clearedCompletedState = false;
  bool _local;
  int _episodeId = 0;
  double _playbackSpeed = 1.0;

  MediaControl playControl = MediaControl(
    androidIcon: 'drawable/ic_action_play_circle_outline',
    label: 'Play',
    action: MediaAction.play,
  );

  MediaControl pauseControl = MediaControl(
    androidIcon: 'drawable/ic_action_pause_circle_outline',
    label: 'Pause',
    action: MediaAction.pause,
  );

  MediaControl stopControl = MediaControl(
    androidIcon: 'drawable/ic_action_stop',
    label: 'Stop',
    action: MediaAction.stop,
  );

  MediaControl rewindControl = MediaControl(
    androidIcon: 'drawable/ic_action_rewind',
    label: 'Rewind',
    action: MediaAction.rewind,
  );

  MediaControl fastforwardControl = MediaControl(
    androidIcon: 'drawable/ic_action_fastforward',
    label: 'Fastforward',
    action: MediaAction.fastForward,
  );

  Future<void> updatePosition() async {
    await AudioServiceBackground.setState(
      controls: _controls,
      processingState: AudioProcessingState.none,
      playing: _isPlaying,
      position: Duration(milliseconds: _position),
    );
  }

  Future<void> setMediaItem(dynamic args) async {
    _uri = args[3] as String;
    _local = (args[4] as String) == '1';
    var sp = args[5] as String;
    var episodeIdStr = args[6] as String;
    var playbackSpeedStr = args[7] as String;
    _episodeId = int.parse(episodeIdStr);
    _playbackSpeed = double.parse(playbackSpeedStr);

    _position = 0;

    if (int.tryParse(sp) != null) {
      _position = int.parse(sp);
    } else {
      log.info('Failed to parse starting position of $sp');
    }

    log.fine(
        'Setting play URI to $_uri, isLocal $_local and position $_position id $_episodeId speed $_playbackSpeed}');

    _loadTrack = true;

    await AudioServiceBackground.setMediaItem(MediaItem(
      id: episodeIdStr,
      title: args[1] as String,
      album: args[0] as String,
      artUri: args[2] as String,
    ));
  }

  Future<void> start() async {
    log.fine('start()');

    _playerStateSubscription =
        _audioPlayer.processingStateStream.where((state) => state == ProcessingState.completed).listen((state) async {
      await complete();
    });

    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      if (_audioPlayer.playing && event.updatePosition != null) {
        _position = event.updatePosition.inMilliseconds;
      }
    });
  }

  Future<void> play() async {
    log.fine('play()');

    if (_loadTrack) {
      if (!_local) {
        await _setBufferingState();
      }

      var userAgent = await Environment.userAgent();

      log.fine('loading new track $_uri - from position $_position');

      var headers = <String, String>{
        'User-Agent': '$userAgent',
      };

      _local
          ? await _audioPlayer.setFilePath(_uri, initialPosition: Duration(milliseconds: _position))
          : await _audioPlayer.setUrl(_uri, headers: headers);

      _loadTrack = false;
    }

    if (_audioPlayer.processingState != ProcessingState.idle) {
      try {
        if (_audioPlayer.speed != _playbackSpeed) {
          await _audioPlayer.setSpeed(_playbackSpeed);
        }

        unawaited(_audioPlayer.play());
      } catch (e) {
        log.fine('State error ${e.toString()}');
      }
    }

    await _setPlayingState();
  }

  Future<void> pause() async {
    log.fine('pause()');

    _position = _latestPosition();

    await _audioPlayer.pause();
    await _setPausedState();
  }

  Future<void> stop() async {
    log.fine('stop()');

    _position = _latestPosition();

    await _setStoppedState();
  }

  Future<void> complete() async {
    log.fine('complete()');

    await _setStoppedState(completed: true);

    if (completionHandler != null) {
      completionHandler();
    }
  }

  Future<void> fastforward() async {
    log.fine('fastforward()');

    _position = _latestPosition();

    await _audioPlayer.seek(Duration(milliseconds: _position + 30000));

    if (_isPlaying) {
      await _setPlayingState();
    } else {
      _playbackState = AudioProcessingState.fastForwarding;

      await _setState();
    }
  }

  Future<void> rewind() async {
    log.fine('rewind()');

    _position = _latestPosition();

    log.fine('Positions:');
    log.fine(' - Stored position is $_position');
    log.fine(' - Player position is ${_audioPlayer.position.inMilliseconds}');

    if (_position > 0) {
      _position -= 30000;

      if (_position < 0) {
        _position = 0;
      }

      await _audioPlayer.seek(Duration(milliseconds: _position));

      if (_isPlaying) {
        await _setPlayingState();
      } else {
        _playbackState = AudioProcessingState.rewinding;
        await _setState();
      }
    }
  }

  Future<void> setSpeed(double speed) async {
    if (_isPlaying) {
      _playbackSpeed = speed;

      await _audioPlayer.setSpeed(speed);
      await _setPlayingState();
    }
  }

  Future<void> onNoise() async {
    if (_isPlaying) {
      await pause();
    }
  }

  Future<void> onClick() async {
    if (_uri.isNotEmpty) {
      if (_isPlaying) {
        await pause();
      } else {
        await play();
      }
    }
  }

  Future<void> _setBufferingState() async {
    log.fine('_setBufferingState()');

    _playbackState = AudioProcessingState.buffering;
    _controls = [rewindControl, pauseControl, fastforwardControl];

    await _setState();
  }

  Future<void> _setPlayingState() async {
    log.fine('setPlayingState()');

    _playbackState = AudioProcessingState.ready;
    _controls = [rewindControl, pauseControl, fastforwardControl];
    _isPlaying = true;

    await _setState();
  }

  Future<void> _setPausedState() async {
    log.fine('setPausedState()');

    _playbackState = AudioProcessingState.ready;
    _controls = [rewindControl, playControl, fastforwardControl];
    _isPlaying = false;

    await _setState(state: LastState.paused);
  }

  Future<void> _setStoppedState({bool completed = false}) async {
    log.fine('setStoppedState()');

    await _playerStateSubscription.cancel();
    await _eventSubscription.cancel();

    await _audioPlayer.stop();
    await _audioPlayer.dispose();

    _playbackState = completed ? AudioProcessingState.completed : AudioProcessingState.stopped;
    _controls = [playControl];
    _isPlaying = false;

    await _setState(state: completed ? LastState.completed : LastState.stopped);

    _completer.complete();
  }

  Future<void> seekTo(Duration position) async {
    log.fine('seekTo() ${_playbackState ?? AudioProcessingState.stopped}');

    await _audioPlayer.seek(position);

    _position = position.inMilliseconds;

    await AudioServiceBackground.setState(
        controls: [pauseControl],
        systemActions: [MediaAction.seekTo],
        position: position,
        processingState: _playbackState ?? AudioProcessingState.stopped,
        playing: _isPlaying);
  }

  Future<void> _setState({LastState state = LastState.none}) async {
    log.fine('_setState() to ${_playbackState.toString()} - $_position - state: $state');

    if (state == LastState.none) {
      await _clearPersistentState();
    } else {
      await _persistState(state);
    }

    await AudioServiceBackground.setState(
      controls: _controls,
      processingState: _playbackState,
      position: Duration(milliseconds: _position),
      playing: _isPlaying,
      speed: _playbackSpeed,
    );
  }

  Future<void> _persistState(LastState state) async {
    // Save our completion state to disk so we can query this later
    log.fine('Saving ${state.toString()} state - episode id $_episodeId - position $_position');

    await PersistentState.persistState(Persistable(
      episodeId: _episodeId,
      position: _position,
      state: state,
    ));

    _clearedCompletedState = false;
  }

  Future<void> _clearPersistentState() async {
    log.fine('Clearing completed status $_clearedCompletedState');

    if (!_clearedCompletedState) {
      await PersistentState.persistState(Persistable(
        episodeId: 0,
        position: 0,
        state: LastState.none,
      ));

      _clearedCompletedState = true;
    }
  }

  int _latestPosition() {
    log.fine('Fetching latest position:');
    log.fine(' - Stored position is $_position');
    log.fine(' - Player position is ${_audioPlayer.position?.inMilliseconds}');

    return _audioPlayer.position == null ? _position : _audioPlayer.position.inMilliseconds;
  }
}
