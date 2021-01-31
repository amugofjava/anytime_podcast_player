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
  Episode episode;

  PositionState(this.position, this.length, this.percentage, this.episode);

  PositionState.emptyState() {
    PositionState(Duration(seconds: 0), Duration(seconds: 0), 0, null);
  }
}

/// This class defines the audio playback options supported by Anytime.
/// The implementing classes will then handle the specifics for the
/// platform we are running on. Currently this is just mobile, but may
/// expand to web and desktop in the future.
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
  Future<Episode> resume();

  /// Call when the app is about to be suspended.
  Future<void> suspend();

  /// Call to set the playback speed.
  Future<void> setPlaybackSpeed(double speed);

  Episode nowPlaying;

  /// Event listeners
  Stream<AudioState> playingState;
  Stream<PositionState> playPosition;
}
