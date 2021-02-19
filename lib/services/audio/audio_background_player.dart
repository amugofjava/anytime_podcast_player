// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/services/audio/mobile_audio_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';

/// This class provides an implementation of [BackgroundAudioTask] from the
/// [audio_service](https://pub.dev/packages/audio_service) package to handle
/// events from [AudioService] in a background Isolate.
class BackgroundPlayerTask extends BackgroundAudioTask {
  final log = Logger('BackgroundPlayerTask');

  /// A stream that listens for 'noisy' events. This allows Anytime to listen
  /// for events such as the headphones being pulled from the audio jack.
  StreamSubscription<void> noisyStream;

  /// Our [MobileAudioPlayer] instance that sits between the [AudioServce] and
  /// the player that handles the actual playback.
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

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    noisyStream = session.becomingNoisyEventStream.listen((_) {
      _anytimeAudioPlayer.onNoise();
    });

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

    if (noisyStream != null) {
      await noisyStream.cancel();
    }

    await super.onStop();
  }

  @override
  Future<void> onPlay() async {
    log.fine('onPlay()');

    final session = await AudioSession.instance;

    if (await session.setActive(true)) {
      return _anytimeAudioPlayer.play();
    } else {
      log.fine('ERROR: Could not activate play session');
    }

    return;
  }

  @override
  Future<void> onPause() async {
    log.fine('onPause()');
    return _anytimeAudioPlayer.pause();
  }

  @override
  Future<void> onSeekTo(Duration position) {
    log.fine('onSeekTo()');
    return _anytimeAudioPlayer.seekTo(position);
  }

  @override
  Future<void> onClick(MediaButton button) {
    return _anytimeAudioPlayer.onClick();
  }

  @override
  Future<void> onSetSpeed(double speed) {
    return _anytimeAudioPlayer.setSpeed(speed);
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
        await onStop();
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
