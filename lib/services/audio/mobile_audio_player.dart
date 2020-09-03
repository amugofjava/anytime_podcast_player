// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
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

  StreamSubscription<AudioPlaybackState> playerStateSubscription;
  StreamSubscription<AudioPlaybackEvent> eventSubscription;

  AudioProcessingState _playbackState;
  List<MediaControl> _controls = [];
  String _uri;
  int _position = 0;
  bool _isPlaying = false;
  bool _loadTrack = false;
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

    _position = 0;

    if (int.tryParse(sp) != null) {
      _position = int.parse(sp);
    } else {
      log.info('Failed to parse starting position of $sp');
    }

    log.fine('Setting play URI to $_uri, isLocal $_local and position $_position');

    _loadTrack = true;

    await AudioServiceBackground.setMediaItem(MediaItem(
      id: '100',
      title: args[1] as String,
      album: args[0] as String,
      artUri: args[2] as String,
    ));
  }

  Future<void> start() async {
    log.fine('start()');

    playerStateSubscription =
        _audioPlayer.playbackStateStream.where((state) => state == AudioPlaybackState.completed).listen((state) async {
      await complete();
    });

    eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      if (event.state == AudioPlaybackState.playing) {
        _position = event.position.inMilliseconds;
      }
    });
  }

  Future<void> play() async {
    log.fine('play()');

    if (_loadTrack) {
      if (!_local) {
        await _setBufferingState();
      }

      log.fine('loading new track $_uri - from position $_position');

      await _audioPlayer.setUrl(_uri);

      if (_position > 0) {
        log.fine('moving position to ${_position}');
        await _audioPlayer.seek(Duration(milliseconds: _position));
      }

      _loadTrack = false;
    }

    if (_audioPlayer.playbackEvent.state != AudioPlaybackState.connecting ||
        _audioPlayer.playbackEvent.state != AudioPlaybackState.none) {
      try {
        unawaited(_audioPlayer.play());
      } catch (e) {
        print('State error');
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

    _position = -1;

    await _setStoppedState();
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

    await _setState();
  }

  Future<void> _setStoppedState() async {
    log.fine('setStoppedState()');

    await playerStateSubscription.cancel();
    await eventSubscription.cancel();

    await _audioPlayer.stop();
    await _audioPlayer.dispose();

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

  int _latestPosition() {
    log.fine('Fetching latest position:');
    log.fine(' - Stored position is $_position');
    log.fine(' - Player position is ${_audioPlayer.position?.inMilliseconds}');

    return _audioPlayer.position == null ? _position : _audioPlayer.position.inMilliseconds;
  }
}
