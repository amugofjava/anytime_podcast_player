// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/persistable.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/audio/audio_background_player.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/persistent_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

/// An implementation of the [AudioPlayerService] for mobile devices.
/// The [audio_service](https://pub.dev/packages/audio_service) package
/// is used to handle audio tasks in a separate Isolate thus allowing
/// audio to play in the background or when the screen is off. An
/// instance of [BackgroundPlayerTask] is used to handle events from
/// the background Isolate and pass them on to the audio player.
class MobileAudioPlayerService extends AudioPlayerService {
  final log = Logger('MobileAudioPlayerService');
  final Repository repository;
  final SettingsService settingsService;
  final PodcastService podcastService;
  final Color androidNotificationColor;
  double _playbackSpeed;
  Episode _episode;

  /// Subscription to the position ticker.
  StreamSubscription<int> _positionSubscription;

  /// Stream showing our current playing state.
  final BehaviorSubject<AudioState> _playingState = BehaviorSubject<AudioState>.seeded(AudioState.none);

  /// Ticks whilst playing. Updates our current position within an episode.
  final _durationTicker = Stream<int>.periodic(Duration(milliseconds: 500)).asBroadcastStream();

  /// Stream for the current position of the playing track.
  final BehaviorSubject<PositionState> _playPosition = BehaviorSubject<PositionState>();

  MobileAudioPlayerService({
    @required this.repository,
    @required this.settingsService,
    @required this.podcastService,
    this.androidNotificationColor,
  }) {
    _handleAudioServiceTransitions();
  }

  /// Called by the client (UI) when a new episode should be played. If we have
  /// a downloaded copy of the requested episode we will use that; otherwise
  /// we will stream the episode directly.
  @override
  Future<void> playEpisode({@required Episode episode, bool resume = true}) async {
    if (episode.guid != '') {
      await _playingState.add(AudioState.playing);

      _playbackSpeed = await settingsService.playbackSpeed;

      var trackDetails = <String>[];

      var streaming = true;
      var startPosition = 0;
      var uri = episode.contentUrl;

      log.info('Playing episode ${episode.title} - ${episode.id}');

      // See if we have the details for this episode already in storage.
      final savedEpisode = await repository.findEpisodeByGuid(episode.guid);

      // If we have a downloaded copy of the episode, set the URI to the file path.
      if (savedEpisode != null && episode.downloadState == DownloadState.downloaded) {
        if (await hasStoragePermission()) {
          final filepath = episode.filepath == null || episode.filepath.isEmpty
              ? join(await getStorageDirectory(), safePath(episode.podcast))
              : episode.filepath;
          final downloadFile = join(filepath, episode.filename);

          uri = downloadFile;

          streaming = false;

          episode.position = savedEpisode.position;

          startPosition = !streaming && resume ? savedEpisode.position : 0;
        } else {
          throw Exception('Insufficient storage permissions');
        }
      }

      // If we are streaming try and let the user know as soon as possible.
      if (streaming) {
        await _playingState.add(AudioState.buffering);
      }

      // If we are currently playing a track - save the position of the current
      // track before switching to the next.
      var currentState = AudioService.playbackState?.processingState ?? AudioProcessingState.none;

      log.fine('Current playback state is $currentState');

      if (currentState == AudioProcessingState.ready) {
        await _savePosition();
      }

      trackDetails = [
        episode.author ?? 'Unknown Author',
        episode.title ?? 'Unknown Title',
        episode.imageUrl,
        uri,
        episode.downloaded ? '1' : '0',
        startPosition.toString(),
        episode.id == null ? '0' : episode.id.toString(),
        _playbackSpeed.toString(),
        episode.duration?.toString() ?? '0',
      ];

      // Store reference
      _episode = episode;
      _episode.played = false;

      await repository.saveEpisode(_episode);

      if (!await AudioService.running) {
        await _start();
      }

      await AudioService.customAction('track', trackDetails);

      try {
        await AudioService.play();

        // If we are streaming and this episode has chapters we should fetch them now.
        if (streaming && _episode.hasChapters) {
          _episode.chapters = await podcastService.loadChaptersByUrl(url: _episode.chaptersUrl);
        }
      } catch (e) {
        log.fine('Error during playback');
        log.fine(e.toString());

        await _playingState.add(AudioState.error);
        await _playingState.add(AudioState.stopped);
        await AudioService.stop();
      }
    }
  }

  @override
  Future<void> fastforward() {
    return AudioService.fastForward();
  }

  @override
  Future<void> pause() => AudioService.pause();

  @override
  Future<void> play() => AudioService.play();

  @override
  Future<void> rewind() => AudioService.rewind();

  @override
  Future<void> seek({int position}) async {
    var duration = _episode == null ? 0 : _episode.duration;
    var complete = position > 0 ? (duration / position) * 100 : 0;
    var seconds = Duration(seconds: position);

    _updateChapter(seconds.inSeconds, duration);

    _playPosition.add(PositionState(seconds, Duration(seconds: _episode.duration), complete.toInt(), _episode));

    return await AudioService.seekTo(seconds);
  }

  @override
  Future<void> stop() async {
    await AudioService.stop();
  }

  /// When resuming from a paused state we first need to reconnect to the [AudioService].
  /// Next we need to restore the state of either the current playing episode or the last
  /// played episode. We do this in one of three ways. If Anytime has only been placed in
  /// the background when we resume [_episode] may still be valid and we can continue as
  /// normal. If not, we check to see if the [AudioService] has a current media item and,
  /// if so, we restore [_episode] that way. Failing that, we look to see if we have a
  /// persisted state file and use that to re-fetch the episode.
  @override
  Future<Episode> resume() async {
    await AudioService.connect();

    if (_episode == null) {
      if (AudioService.currentMediaItem == null) {
        await _updateEpisodeFromSavedState();
      } else {
        _episode = await repository.findEpisodeById(int.parse(AudioService.currentMediaItem.id));
      }
    } else {
      var playbackState = await AudioService.playbackState;

      final basicState = playbackState?.processingState ?? AudioProcessingState.none;

      // If we have no state we'll have to assume we stopped whilst suspended.
      if (basicState == AudioProcessingState.none) {
        await _updateEpisodeFromSavedState();
        await _playingState.add(AudioState.stopped);
      } else {
        await _startTicker();
      }
    }

    await PersistentState.clearState();

    return Future.value(_episode);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) => AudioService.setSpeed(speed);

  /// This method opens a saved state file. If it exists we fetch the episode ID from
  /// the saved state and fetch it from the database. If the last updated value of the
  /// saved state is later than the episode last updated date, we update the episode
  /// properties from the saved state.
  Future<void> _updateEpisodeFromSavedState() async {
    var persistedState = await PersistentState.fetchState();

    if (persistedState != null) {
      _episode = await repository.findEpisodeById(persistedState.episodeId);

      if (_episode != null && persistedState.lastUpdated.isAfter(_episode?.lastUpdated)) {
        if (persistedState.state == LastState.completed) {
          _episode.position = 0;
          _episode.played = true;
        } else {
          _episode.position = persistedState.position;
        }

        await repository.saveEpisode(_episode);
      }
    }
  }

  @override
  Future<void> suspend() async {
    await _stopTicker();

    await AudioService.disconnect();
  }

  Future<void> _onStop() async {
    var playbackState = await AudioService.playbackState;

    await _stopTicker();

    log.fine('_onStop() ${playbackState.position}');

    await _savePosition();

    _episode = null;

    _playingState.add(AudioState.stopped);
  }

  Future<void> _onComplete() async {
    var playbackState = await AudioService.playbackState;

    await _stopTicker();

    log.fine('_onStop() ${playbackState.position}');

    _episode.position = 0;
    _episode.played = true;

    await repository.saveEpisode(_episode);

    _episode = null;

    _playingState.add(AudioState.stopped);
  }

  Future<void> _onPause() async {
    _playingState.add(AudioState.pausing);

    await _stopTicker();
    await _savePosition();
  }

  Future<void> _onPlay() async {
    _playingState.add(AudioState.playing);

    await _startTicker();
  }

  Future<void> _onBuffering() async {
    _playingState.add(AudioState.buffering);
  }

  Future<void> _onUpdatePosition() async {
    var playbackState = await AudioService.playbackState;

    if (playbackState != null) {
      var currentMediaItem = AudioService.currentMediaItem;
      var duration = currentMediaItem?.duration ?? Duration(seconds: 1);
      var position = playbackState?.currentPosition;
      var complete = position.inSeconds > 0 ? (duration.inSeconds / position.inSeconds) * 100 : 0;

      _updateChapter(position.inSeconds, duration.inSeconds);

      _playPosition.add(PositionState(position, duration, complete.toInt(), _episode));
    }
  }

  /// Called before any playing of podcasts can take place. Only needs to be
  /// called again if a [AudioService.stop()] is called. This is quite an
  /// expensive operation so calling this method should be minimised.
  Future<void> _start() async {
    log.fine('_start() ${_episode.title} - ${_episode.position}');

    await AudioService.start(
      backgroundTaskEntrypoint: backgroundPlay,
      androidResumeOnClick: true,
      androidNotificationChannelName: 'Anytime Podcast Player',
      androidNotificationColor: androidNotificationColor?.value ?? Colors.orange.value,
      androidNotificationIcon: 'drawable/ic_stat_name',
      androidStopForegroundOnPause: true,
      fastForwardInterval: Duration(seconds: 30),
      rewindInterval: Duration(seconds: 30),
    );
  }

  /// Listens to events from the Audio Service plugin. We use this to trigger
  /// functions that Anytime needs to run as the audio state changes. Ideally
  /// we would like to handle all of this in the [_transitionPlayingState]
  /// stream, but as Audio Service handles input from external sources such
  /// as the notification bar or a WearOS device we need this second listener
  /// to ensure the necessary Anytime is code is run upon state change.
  void _handleAudioServiceTransitions() async {
    AudioService.playbackStateStream.listen((state) async {
      if (state != null && state is PlaybackState) {
        final ps = state.processingState;

        log.fine('Received state change from audio_service: ${ps.toString()}');

        switch (ps) {
          case AudioProcessingState.none:
            break;
          case AudioProcessingState.completed:
            await _onComplete();
            break;
          case AudioProcessingState.stopped:
            await _onStop();
            break;
          case AudioProcessingState.ready:
            if (state.playing) {
              await _onPlay();
            } else {
              await _onPause();
            }
            break;
          case AudioProcessingState.fastForwarding:
            await _onUpdatePosition();
            break;
          case AudioProcessingState.rewinding:
            await _onUpdatePosition();
            break;
          case AudioProcessingState.buffering:
            await _onBuffering();
            break;
          case AudioProcessingState.error:
            break;
          case AudioProcessingState.connecting:
            break;
          case AudioProcessingState.skippingToPrevious:
            break;
          case AudioProcessingState.skippingToNext:
            break;
          case AudioProcessingState.skippingToQueueItem:
            break;
        }
      }
    });
  }

  /// Saves the current play position to persistent storage. This enables a
  /// podcast to continue playing where it left off if played at a later
  /// time.
  Future<void> _savePosition() async {
    var playbackState = await AudioService.playbackState;

    if (_episode != null && _episode.downloaded) {
      // The episode may have been updated elsewhere - re-fetch it.
      _episode = await repository.findEpisodeByGuid(_episode.guid);

      _episode.position = playbackState.currentPosition?.inMilliseconds;

      log.fine('Saving position for episode ${_episode.title} - ${_episode.position}');
      log.fine('Current state is ${playbackState.processingState}');

      await repository.saveEpisode(_episode);
    }
  }

  /// Called when play starts. Each time we receive an event in the stream
  /// we check the current position of the episode from the audio service
  /// and then push that information out via the [_playPosition] stream
  /// to inform our listeners.
  void _startTicker() async {
    if (_positionSubscription == null) {
      _positionSubscription = _durationTicker.listen((int period) async {
        await _onUpdatePosition();
      });
    } else {
      _positionSubscription.resume();
    }
  }

  void _stopTicker() async {
    if (_positionSubscription != null) {
      await _positionSubscription.cancel();

      _positionSubscription = null;
    }
  }

  void _updateChapter(int seconds, int duration) {
    if (_episode.hasChapters && _episode.chaptersAreLoaded) {
      final chapters = _episode.chapters;

      // What is our current chapter?
      for (var x = 0; x < _episode.chapters.length; x++) {
        final startTime = chapters[x].startTime;
        final endTime = x == (_episode.chapters.length - 1) ? duration : chapters[x + 1].startTime;

        if (seconds >= startTime && seconds < endTime) {
          if (chapters[x] != _episode.currentChapter) {
            _episode.currentChapter = chapters[x];
            break;
          }
        }
      }
    }
  }

  @override
  Episode get nowPlaying => _episode;

  /// Get the current playing state
  @override
  Stream<AudioState> get playingState => _playingState.stream;

  Stream<EpisodeState> get episodeListener => repository.episodeListener;

  @override
  Stream<PositionState> get playPosition => _playPosition.stream;
}

void backgroundPlay() {
  AudioServiceBackground.run(() => BackgroundPlayerTask());
}
