// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

/// This class acts as a go-between between [AudioService] and the chosen
/// audio player implementation.
///
/// For each transition, such as play, pause etc, this class will call the
/// equivalent function on the audio player and update the [AudioService]
/// state.
///
/// This version is backed by [AudioPlayers]. However, I have had issues with
/// playing files from an external SD Card on Android 9. This version is
/// being deprecated whilst I try out just_audio instead.
@deprecated
class AndroidAudioPlayer {
  final log = Logger('AndroidAudioPlayer');

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Completer _completer = Completer<dynamic>();
  AudioProcessingState _playbackState;
  List<MediaControl> _controls = [];
  String _uri;
  int _position = 0;
  bool _isPlaying = false;
  bool _local;

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
    await _setState();
  }

  Future<void> setMediaItem(dynamic args) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }

    _uri = args[3] as String;
    _local = (args[4] as String) == '1';
    var sp = args[5] as String;

    _position = 0;

    if (int.tryParse(sp) != null) {
      _position = int.parse(sp);
    } else {
      log.info('Failed to parse starting position of $sp');
    }

    log.fine('Setting play URI to $_uri, isLocal $_local and position $_position');

    await AudioServiceBackground.setMediaItem(MediaItem(
      id: '100',
      title: args[1] as String,
      album: args[0] as String,
      artUri: args[2] as String,
    ));
  }

  Future<void> start() async {
    log.fine('start()');

    var audioPositionSubscription = _audioPlayer.onAudioPositionChanged.listen((when) {
      _position = when.inMilliseconds;
    });

    var audioCompletionSubscription = _audioPlayer.onPlayerCompletion.listen((event) async {
      log.fine('onPlayerCompletion - Reached end of episode. Stop');

      // Mark we have played all.
      _position = -1;
      await stop();
    });

    await _completer.future;

    await audioPositionSubscription.cancel();
    await audioCompletionSubscription.cancel();
    await _audioPlayer.dispose();
  }

  Future<void> play() async {
    log.fine('play() $_uri - from position $_position');
    var result = await _audioPlayer.play(
      _uri,
      isLocal: _local,
      position: Duration(milliseconds: _position),
    );

    print('Play result is $result');

    await _setPlayingState();
  }

  Future<void> pause() async {
    log.fine('pause()');

    _position = await _audioPlayer.getCurrentPosition();

    await _audioPlayer.pause();
    await _setPausedState();
  }

  Future<void> stop() async {
    log.fine('stop() ****************************');

    await _audioPlayer.stop();
    await _setStoppedState();
  }

  Future<void> fastforward() async {
    log.fine('fastforward()');

    var pos = await _audioPlayer.getCurrentPosition();

    await _audioPlayer.seek(Duration(milliseconds: pos + 30000));

    if (_isPlaying) {
      await _setPlayingState();
    } else {
      _playbackState = AudioProcessingState.fastForwarding;

      await _setState();
    }

    _position = pos;
  }

  Future<void> rewind() async {
    log.fine('rewind()');

    var pos = await _audioPlayer.getCurrentPosition();

    if (pos > 0) {
      pos -= 30000;

      if (pos < 0) {
        pos = 0;
      }

      await _audioPlayer.seek(Duration(milliseconds: pos));

      _position = pos;

      if (_isPlaying) {
        await _setPlayingState();
      } else {
        _playbackState = AudioProcessingState.rewinding;
        await _setState();
      }
    }
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

    _position = await _audioPlayer.getCurrentPosition();

    _playbackState = AudioProcessingState.ready;
    _controls = [rewindControl, playControl, fastforwardControl];
    _isPlaying = false;

    await _setState();
  }

  Future<void> _setStoppedState() async {
    log.fine('setStoppedState()');

    _playbackState = AudioProcessingState.stopped;
    _controls = [playControl];
    _isPlaying = false;

    await _setState();

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

  Future<void> _setState() async {
    log.fine('_setState() to ${_playbackState.toString()} - $_position');

    await AudioServiceBackground.setState(
        controls: _controls, processingState: _playbackState, position: Duration(milliseconds: _position), playing: _isPlaying);
  }
}
