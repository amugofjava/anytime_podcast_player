// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:flutter/cupertino.dart';

enum AudioState {
  none,
  buffering,
  starting,
  playing,
  pausing,
  stopped,
}

class PositionState {
  Duration position;
  Duration length;
  int percentage;

  PositionState(this.position, this.length, this.percentage);
}

abstract class AudioPlayerService {
  /// Play a new episode, optionally resume at last save point.
  Future<void> playEpisode({@required Episode episode, bool resume});

  /// Resume playing of current episode
  Future<void> play();

  /// Stop playing of current episode. Set update to false to stop
  /// playback without saving any episode or positional updates.
  Future<void> stop();

  /// Pause the current episode.
  Future<void> pause();

  /// Rewind the current episode by pre-set number of seconds.
  Future<void> rewind();

  /// Fast forward the current episode by pre-set number of seconds.
  Future<void> fastforward();

  /// Seek to the specified position within the current episode.
  Future<void> seek({@required int position});

  /// Call when the app is resumed to re-establish the audio service.
  Future<void> resume();

  /// Call when the app is about to be suspended.
  Future<void> suspend();

  Episode nowPlaying;

  /// Event listeners
  Stream<AudioState> playingState;
  Stream<PositionState> playPosition;
}
