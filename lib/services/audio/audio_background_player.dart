// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/services/audio/mobile_audio_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:logging/logging.dart';

/// This is the implementation of the Anytime Audio Service for Android. This
/// version uses AudioService and AudioPlayer packages to provide the audio
/// playback and Android services for continuing playback in the background.
class BackgroundPlayerTask extends BackgroundAudioTask {
  final log = Logger('BackgroundPlayerTask');
  MobileAudioPlayer _anytimeAudioPlayer;

  /// As we are running in a separate Isolate, we need a separate Logger -
  /// or we'll not see anything in the console/logs!.
  BackgroundPlayerTask() {
    Logger.root.level = Level.FINE;

    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: - ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    log.fine('onStart()');

    // As audio_service now requires a call to super.onStop() we need to
    // be notified if playback comes to an end. Without this callback,
    // episodes that finished would result in audio_service not tidying up.
    // This may be a temporary solution if I can think of a cleaner way
    // of doing this.
    _anytimeAudioPlayer = MobileAudioPlayer(completionHandler: () async {
      await super.onStop();
    });

    await _anytimeAudioPlayer.start();
  }

  @override
  Future<void> onStop() async {
    log.fine('onStop()');
    await _anytimeAudioPlayer.stop();

    await super.onStop();
  }

  @override
  Future<void> onPlay() {
    log.fine('onPlay()');
    return _anytimeAudioPlayer.play();
  }

  @override
  Future<void> onPause() {
    log.fine('onPause()');
    return _anytimeAudioPlayer.pause();
  }

  @override
  Future<void> onSeekTo(Duration position) {
    log.fine('onSeekTo()');
    return _anytimeAudioPlayer.seekTo(position);
  }

  @override
  Future<void> onAudioBecomingNoisy() {
    return _anytimeAudioPlayer.onNoise();
  }

  @override
  Future<void> onClick(MediaButton button) {
    return _anytimeAudioPlayer.onClick();
  }

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    log.fine('onCustomAction()');
    switch (name) {
      case 'track':
        await _anytimeAudioPlayer.setMediaItem(arguments);
        break;
      case 'position':
        await _anytimeAudioPlayer.updatePosition();
        break;
      case 'kill':
        await _anytimeAudioPlayer.stop();
        break;
    }
  }

  @override
  Future<void> onFastForward() async {
    log.fine('onFastForward()');
    await _anytimeAudioPlayer.fastforward();
  }

  @override
  Future<void> onRewind() async {
    log.fine('onRewind()');
    await _anytimeAudioPlayer.rewind();
  }
}
