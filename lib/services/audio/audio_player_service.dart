// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/sleep.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/state/transcript_state_event.dart';
import 'package:rxdart/rxdart.dart';

enum AudioState {
  none,
  buffering,
  starting,
  playing,
  pausing,
  stopped,
  error,
}

class PositionState {
  Duration position;
  late Duration length;
  late int percentage;
  Episode? episode;
  final bool buffering;

  PositionState({
    required this.position,
    required this.length,
    required this.percentage,
    this.episode,
    this.buffering = false,
  });

  PositionState.emptyState()
      : position = const Duration(seconds: 0),
        length = const Duration(seconds: 0),
        percentage = 0,
        buffering = false;
}

/// This class defines the audio playback options supported by Anytime.
///
/// The implementing classes will then handle the specifics for the platform we are running on.
abstract class AudioPlayerService {
  /// Play a new episode, optionally resume at last save point.
  Future<void> playEpisode({required Episode episode, bool resume = true});

  /// Play the latest episode for a given podcast.
  Future<void> playLatestEpisode({required Podcast podcast, bool resume = true});

  /// Play the next unplayed episode for a given podcast.
  Future<void> playNextUnplayedEpisode({required Podcast podcast, bool resume = true});

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
  Future<void> fastForward();

  /// Seek to the specified position within the current episode.
  Future<void> seek({required int position});

  /// Call when the app is resumed to re-establish the audio service.
  Future<Episode?> resume();

  /// Queue the latest episode for a given podcast.
  Future<void> addUpNextLatestEpisode({required Podcast podcast});

  /// Queue the next unplayed episode for a given podcast.
  Future<void> addUpNextUnplayedEpisode({required Podcast podcast});

  /// Add an episode to the playback queue
  Future<void> addUpNextEpisode(Episode episode);

  /// Remove an episode from the playback queue if it exists
  Future<bool> removeUpNextEpisode(Episode episode);

  /// Remove an episode from the playback queue if it exists
  Future<bool> moveUpNextEpisode(Episode episode, int oldIndex, int newIndex);

  /// Empty the up next queue
  Future<void> clearUpNext();

  /// Call when the app is about to be suspended.
  Future<void> suspend();

  /// Call to set the playback speed.
  Future<void> setPlaybackSpeed(double speed);

  /// Call to toggle trim silence.
  Future<void> trimSilence(bool trim);

  /// Call to toggle trim silence.
  Future<void> volumeBoost(bool boost);

  Future<void> searchTranscript(String search);

  Future<void> clearTranscript();

  void sleep(Sleep sleep);

  Episode? nowPlaying;

  /// Event listeners
  Stream<AudioState>? playingState;
  ValueStream<PositionState>? playPosition;
  ValueStream<Episode?>? episodeEvent;
  Stream<TranscriptState>? transcriptEvent;
  Stream<int>? playbackError;
  Stream<QueueListState>? queueState;
  Stream<Sleep>? sleepStream;
}
