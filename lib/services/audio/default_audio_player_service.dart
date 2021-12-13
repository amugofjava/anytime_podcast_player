// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:anytime/core/environment.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/persistable.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/persistent_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// This is the default implementation of [AudioPlayerService]. This implementation uses
/// the [audio_service](https://pub.dev/packages/audio_service) package to run the audio
/// layer as a service to allow background play, and playback is handled by the
/// [just_audio](https://pub.dev/packages/just_audio) package.
class DefaultAudioPlayerService extends AudioPlayerService {
  final zeroDuration = const Duration(seconds: 0);
  final log = Logger('DefaultAudioPlayerService');
  final Repository repository;
  final SettingsService settingsService;
  final PodcastService podcastService;

  AudioHandler _audioHandler;
  var _initialised = false;
  var _cold = false;

  double _playbackSpeed;
  bool _trimSilence = false;
  bool _volumeBoost = false;
  Episode _episode;

  /// Subscription to the position ticker.
  StreamSubscription<int> _positionSubscription;

  /// Stream showing our current playing state.
  final BehaviorSubject<AudioState> _playingState = BehaviorSubject<AudioState>.seeded(AudioState.none);

  /// Ticks whilst playing. Updates our current position within an episode.
  final _durationTicker = Stream<int>.periodic(Duration(milliseconds: 500)).asBroadcastStream();

  /// Stream for the current position of the playing track.
  final BehaviorSubject<PositionState> _playPosition = BehaviorSubject<PositionState>();

  final BehaviorSubject<Episode> _episodeEvent = BehaviorSubject<Episode>(sync: true);

  /// Stream for the last audio error as an integer code.
  final PublishSubject<int> _playbackError = PublishSubject<int>();

  DefaultAudioPlayerService({
    @required this.repository,
    @required this.settingsService,
    @required this.podcastService,
  }) {
    AudioService.init(
      builder: () => _DefaultAudioPlayerHandler(
        repository: repository,
        settings: settingsService,
      ),
      config: const AudioServiceConfig(
        androidResumeOnClick: true,
        androidNotificationChannelName: 'Anytime Podcast Player',
        androidNotificationIcon: 'drawable/ic_stat_name',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        rewindInterval: Duration(seconds: 10),
        fastForwardInterval: Duration(seconds: 30),
      ),
    ).then((value) {
      _audioHandler = value;
      _initialised = true;
      _handleAudioServiceTransitions();
    });
  }

  @override
  Future<void> pause() async => _audioHandler.pause();

  @override
  Future<void> play() {
    if (_cold) {
      _cold = false;
      return playEpisode(episode: _episode, resume: true);
    } else {
      return _audioHandler.play();
    }
  }

  /// Called by the client (UI) when a new episode should be played. If we have
  /// a downloaded copy of the requested episode we will use that; otherwise
  /// we will stream the episode directly.
  @override
  Future<void> playEpisode({Episode episode, bool resume}) async {
    if (episode.guid != '' && _initialised) {
      var streaming = true;
      var startPosition = 0;
      var uri = episode.contentUrl;

      _episodeEvent.sink.add(episode);
      _playingState.add(AudioState.buffering);

      if (resume) {
        startPosition = episode?.position ?? 0;
      }

      if (episode.downloadState == DownloadState.downloaded) {
        if (await hasStoragePermission()) {
          final downloadFile = await resolvePath(episode);

          uri = downloadFile;

          streaming = false;
        } else {
          throw Exception('Insufficient storage permissions');
        }
      }

      log.info('Playing episode ${episode?.id} - ${episode?.title} from position $startPosition');
      log.fine(' - $uri');

      // If we are streaming try and let the user know as soon as possible and
      // clear any chapters as we'll fetch them again.
      if (streaming) {
        // We are streaming. Clear any chapters as we'll (re)fetch them
        episode.chapters = <Chapter>[];
        episode.currentChapter = null;

        _playingState.add(AudioState.buffering);

        // Check we have connectivity
        var connectivityResult = await Connectivity().checkConnectivity();

        if (connectivityResult == ConnectivityResult.none) {
          _playbackError.add(401);
          _playingState.add(AudioState.none);

          return;
        }
      }

      _episodeEvent.sink.add(episode);
      _updateCurrentPosition(episode);
      _playbackSpeed = settingsService.playbackSpeed;
      _trimSilence = settingsService.trimSilence;
      _volumeBoost = settingsService.volumeBoost;

      // If we are currently playing a track - save the position of the current
      // track before switching to the next.
      var currentState = _audioHandler.playbackState.value.processingState ?? AudioProcessingState.idle;

      log.fine(
          'Current playback state is $currentState. Speed = $_playbackSpeed. Trim = $_trimSilence. Volume Boost = $_volumeBoost}');

      if (currentState == AudioProcessingState.ready) {
        await _savePosition();
      }

      // Store reference
      _episode = episode;
      _episode.played = false;

      await repository.saveEpisode(_episode);

      try {
        await _audioHandler.playMediaItem(_loadTrackDetails(uri, startPosition));

        // If we are streaming and this episode has chapters we should (re)fetch them now.
        if (streaming && _episode.hasChapters) {
          _episode.chaptersLoading = true;
          _episode.chapters = <Chapter>[];
          _episodeEvent.sink.add(_episode);

          await _onUpdatePosition();

          _episode.chapters = await podcastService.loadChaptersByUrl(url: _episode.chaptersUrl);
          _episode.chaptersLoading = false;

          _episode = await repository.saveEpisode(_episode);
          _episodeEvent.sink.add(_episode);

          await _onUpdatePosition();
        }
      } catch (e) {
        log.fine('Error during playback');
        log.fine(e.toString());

        _playingState.add(AudioState.error);
        _playingState.add(AudioState.stopped);

        await _audioHandler.stop();
      }
    }
  }

  @override
  Future<void> rewind() => _audioHandler.rewind();

  @override
  Future<void> fastForward() => _audioHandler.fastForward();

  @override
  Future<void> seek({int position}) async {
    var currentMediaItem = _audioHandler.mediaItem.value;
    var duration = currentMediaItem?.duration ?? Duration(seconds: 1);
    var p = Duration(seconds: position);
    var complete = p.inSeconds > 0 ? (duration.inSeconds / p.inSeconds) * 100 : 0;

    // Pause the ticker whilst we seek to prevent jumpy UI.
    _positionSubscription?.pause();

    _updateChapter(p.inSeconds, duration.inSeconds);

    _playPosition.add(PositionState(p, duration, complete.toInt(), _episode, true));

    await _audioHandler.seek(Duration(seconds: position));

    _positionSubscription?.resume();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) => _audioHandler.setSpeed(speed);

  @override
  Future<void> stop() => _audioHandler.stop();

  void updateCurrentPosition(Episode e) {
    if (e != null) {
      var duration = Duration(seconds: e.duration);
      var complete = e.position > 0 ? (duration.inSeconds / e.position) * 100 : 0;

      _playPosition.add(PositionState(Duration(milliseconds: e.position), duration, complete.toInt(), e, false));
    }
  }

  @override
  Future<void> suspend() async {
    _stopTicker();
    _persistState();
  }

  @override
  Future<Episode> resume() async {
    if (_audioHandler != null) {
      if (_episode == null) {
        if (_audioHandler?.mediaItem?.value != null) {
          _episode = await repository.findEpisodeById(int.parse(_audioHandler.mediaItem.value.id));
        } else {
          // Let's see if we have a persisted state
          var ps = await PersistentState.fetchState();

          if (ps != null && ps.state == LastState.paused) {
            _episode = await repository.findEpisodeById(ps.episodeId);
            _episode.position = ps.position;
            _playingState.add(AudioState.pausing);
            updateCurrentPosition(_episode);
            _cold = true;
          }
        }
      } else {
        var playbackState = _audioHandler.playbackState.value;

        final basicState = playbackState?.processingState ?? AudioProcessingState.idle;

        // If we have no state we'll have to assume we stopped whilst suspended.
        if (basicState != AudioProcessingState.idle) {
          _startTicker();
        }
      }

      await PersistentState.clearState();

      _episodeEvent.sink.add(_episode);

      return Future.value(_episode);
    }

    return Future.value(null);
  }

  Future<void> _persistState() async {
    var currentPosition = _audioHandler?.playbackState?.value?.position?.inMilliseconds ?? 0;

    /// We only need to persist if we are paused.
    if (_playingState.value == AudioState.pausing) {
      await PersistentState.persistState(Persistable(
        episodeId: _episode.id,
        position: currentPosition,
        state: LastState.paused,
      ));
    }
  }

  @override
  Future<void> trimSilence(bool trim) {
    return _audioHandler.customAction('trim', <String, dynamic>{
      'value': trim,
    });
  }

  @override
  Future<void> volumeBoost(bool boost) {
    return _audioHandler.customAction('boost', <String, dynamic>{
      'value': boost,
    });
  }

  MediaItem _loadTrackDetails(String uri, int startPosition) {
    return MediaItem(
      id: uri,
      title: _episode.title ?? 'Unknown Title',
      artist: _episode.author ?? 'Unknown Title',
      artUri: Uri.parse(_episode.imageUrl),
      duration: Duration(seconds: _episode.duration ?? 0),
      extras: <String, dynamic>{
        'position': startPosition,
        'downloaded': _episode.downloaded,
        'speed': _playbackSpeed,
        'trim': _trimSilence,
        'boost': _volumeBoost,
        'eid': _episode.guid,
      },
    );
  }

  void _handleAudioServiceTransitions() {
    _audioHandler.playbackState.distinct((previousState, currentState) {
      return previousState.playing == currentState.playing &&
          previousState.processingState == currentState.processingState;
    }).listen((PlaybackState state) {
      switch (state.processingState) {
        case AudioProcessingState.idle:
          _playingState.add(AudioState.none);
          break;
        case AudioProcessingState.loading:
        case AudioProcessingState.buffering:
          _playingState.add(AudioState.buffering);
          break;
        case AudioProcessingState.ready:
          if (state.playing) {
            _startTicker();
            _playingState.add(AudioState.playing);
          } else {
            _stopTicker();
            _playingState.add(AudioState.pausing);
          }
          break;
        case AudioProcessingState.completed:
          _playingState.add(AudioState.stopped);
          break;
        case AudioProcessingState.error:
          _playingState.add(AudioState.error);
          break;
      }
    });
  }

  void _updateCurrentPosition(Episode e) {
    if (e != null) {
      var duration = Duration(seconds: e.duration);
      var complete = e.position > 0 ? (duration.inSeconds / e.position) * 100 : 0;

      _playPosition.add(PositionState(Duration(milliseconds: e.position), duration, complete.toInt(), e, false));
    }
  }

  /// Saves the current play position to persistent storage. This enables a
  /// podcast to continue playing where it left off if played at a later
  /// time.
  Future<void> _savePosition({bool complete = false}) async {
    if (_episode != null) {
      // The episode may have been updated elsewhere - re-fetch it.
      var currentPosition = _audioHandler.playbackState.value.position.inMilliseconds ?? 0;

      _episode = await repository.findEpisodeByGuid(_episode.guid);

      log.fine('_savePosition(): Current position is $currentPosition - stored position is ${_episode.position}');

      if (currentPosition != _episode.position) {
        _episode.position = complete ? 0 : currentPosition;
        _episode = await repository.saveEpisode(_episode);
      }
    } else {
      log.fine(' - Cannot save position as episode is null');
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
    } else if (_positionSubscription.isPaused) {
      _positionSubscription.resume();
    }
  }

  void _stopTicker() async {
    if (_positionSubscription != null) {
      await _positionSubscription.cancel();

      _positionSubscription = null;
    }
  }

  Future<void> _onUpdatePosition() async {
    var playbackState = _audioHandler?.playbackState?.value;

    if (playbackState != null) {
      var currentMediaItem = _audioHandler.mediaItem.value;
      var duration = currentMediaItem?.duration ?? Duration(seconds: 1);
      var position = playbackState.position;
      var complete = position.inSeconds > 0 ? (duration.inSeconds / position.inSeconds) * 100 : 0;
      var buffering = playbackState.processingState == AudioProcessingState.buffering;

      _updateChapter(position.inSeconds, duration.inSeconds);

      _playPosition.add(PositionState(position, duration, complete.toInt(), _episode, buffering));
    }
  }

  /// Calculate our current chapter based on playback position, and if it's different to
  /// the currently stored chapter - update.
  void _updateChapter(int seconds, int duration) {
    if (_episode == null) {
      log.fine('Warning. Attempting to update chapter information on a null _episode');
    } else if (_episode.hasChapters && _episode.chaptersAreLoaded) {
      final chapters = _episode.chapters;

      for (var chapterPtr = 0; chapterPtr < _episode.chapters.length; chapterPtr++) {
        final startTime = chapters[chapterPtr].startTime;
        final endTime = chapterPtr == (_episode.chapters.length - 1) ? duration : chapters[chapterPtr + 1].startTime;

        if (seconds >= startTime && seconds < endTime) {
          if (chapters[chapterPtr] != _episode.currentChapter) {
            _episode.currentChapter = chapters[chapterPtr];
            _episodeEvent.sink.add(_episode);
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

  @override
  Stream<Episode> get episodeEvent => _episodeEvent.stream;

  @override
  Stream<int> get playbackError => _playbackError.stream;
}

/// This is the default audio handler used by the [DefaultAudioPlayerService] service.
/// This handles the interaction between the service (via the audio service package) and
/// the underlying player.
class _DefaultAudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final log = Logger('DefaultAudioPlayerHandler');
  final Repository repository;
  final SettingsService settings;

  static const rewindMillis = 10001;
  static const fastForwardMillis = 30000;
  static const audioGain = 0.8;
  bool _trimSilence = false;

  AndroidLoudnessEnhancer _androidLoudnessEnhancer;
  AudioPipeline _audioPipeline;
  AudioPlayer _player;
  MediaItem _currentItem;

  static const MediaControl rewindControl = MediaControl(
    androidIcon: 'drawable/ic_action_rewind_10',
    label: 'Rewind',
    action: MediaAction.rewind,
  );

  static const MediaControl fastforwardControl = MediaControl(
    androidIcon: 'drawable/ic_action_fastforward_30',
    label: 'Fastforward',
    action: MediaAction.fastForward,
  );

  _DefaultAudioPlayerHandler({
    @required this.repository,
    @required this.settings,
  }) {
    if (Platform.isAndroid) {
      _androidLoudnessEnhancer = AndroidLoudnessEnhancer();
      _androidLoudnessEnhancer.setEnabled(true);
      _audioPipeline = AudioPipeline(androidAudioEffects: [_androidLoudnessEnhancer]);
      _player = AudioPlayer(audioPipeline: _audioPipeline);
    } else {
      _player = AudioPlayer(
          userAgent: Environment.userAgent(),
          audioLoadConfiguration: AudioLoadConfiguration(
            androidLoadControl: AndroidLoadControl(
              backBufferDuration: Duration(seconds: 45),
            ),
            darwinLoadControl: DarwinLoadControl(),
          ));
    }

    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _handleProcessingState();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    super.mediaItem.add(mediaItem);

    _currentItem = mediaItem;

    var downloaded = mediaItem.extras['downloaded'] as bool ?? true;
    var startPosition = mediaItem.extras['position'] as int ?? 0;
    var playbackSpeed = mediaItem.extras['speed'] as double ?? 0.0;
    var start = startPosition > 0 ? Duration(milliseconds: startPosition) : Duration.zero;
    var boost = mediaItem.extras['boost'] as bool ?? true;
    // Commented out until just audio position bug is fixed
    // var trim = mediaItem.extras['trim'] as bool ?? true;

    log.fine('loading new track ${mediaItem.id} - from position ${start.inSeconds} (${start.inMilliseconds})');

    if (downloaded) {
      await _player.setFilePath(
        mediaItem.id,
        initialPosition: start,
      );
    } else {
      var d = await _player.setUrl(
        mediaItem.id,
        headers: <String, String>{
          'User-Agent': Environment.userAgent(),
        },
        initialPosition: start,
      );

      /// If we don't already have a duration and we have been able to calculate it from
      /// beginning to fetch the media, update the current media item with the duration.
      if (d != null && (mediaItem.duration == null || mediaItem.duration.inSeconds == 0)) {
        _currentItem = _currentItem.copyWith(duration: d);
      }
    }

    if (_player.processingState != ProcessingState.idle) {
      try {
        if (_player.speed != playbackSpeed) {
          await _player.setSpeed(playbackSpeed);
        }

        if (Platform.isAndroid) {
          if (_player.skipSilenceEnabled != _trimSilence) {
            await _player.setSkipSilenceEnabled(_trimSilence);
          }

          volumeBoost(boost);
        }

        _player.play();
      } catch (e) {
        log.fine('State error ${e.toString()}');
      }
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _savePosition();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _savePosition();
    await _player.stop();
  }

  Future<void> complete() async {
    await _savePosition(complete: true);
    await _player.stop();
  }

  @override
  Future<void> fastForward() async {
    var forwardPosition = _player.position?.inMilliseconds ?? 0;

    await _player.seek(Duration(milliseconds: forwardPosition + fastForwardMillis));
  }

  @override
  Future<void> seek(Duration position) async {
    return _player.seek(position);
  }

  @override
  Future<void> rewind() async {
    var rewindPosition = _player.position?.inMilliseconds ?? 0;

    if (rewindPosition > 0) {
      rewindPosition -= rewindMillis;

      if (rewindPosition < 0) {
        rewindPosition = 0;
      }

      await _player.seek(Duration(milliseconds: rewindPosition));
    }
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic> extras]) async {
    switch (name) {
      case 'trim':
        var t = extras['value'] as bool;
        return trimSilence(t);
        break;
      case 'boost':
        var t = extras['value'] as bool;
        return volumeBoost(t);
        break;
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> trimSilence(bool trim) async {
    _trimSilence = trim;
    await _player.setSkipSilenceEnabled(trim);
  }

  void volumeBoost(bool boost) {
    /// For now, we know we only have one effect so we can cheat
    var e = _audioPipeline.androidAudioEffects[0];

    if (e is AndroidLoudnessEnhancer) {
      e.setTargetGain(boost ? audioGain : 0.0);
    }
  }

  void _handleProcessingState() {
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await complete();
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        rewindControl,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        fastforwardControl,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState],
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> _savePosition({bool complete = false}) async {
    if (_currentItem != null) {
      // The episode may have been updated elsewhere - re-fetch it.
      var currentPosition = playbackState.value.position.inMilliseconds ?? 0;
      var storedEpisode = await repository.findEpisodeByGuid(_currentItem.extras['eid'] as String);

      log.fine('_savePosition(): Current position is $currentPosition - stored position is ${storedEpisode.position}');

      if (complete) {
        storedEpisode.position = 0;
        storedEpisode.played = true;

        await repository.saveEpisode(storedEpisode);
      } else if (currentPosition != storedEpisode.position) {
        storedEpisode.position = currentPosition;

        await repository.saveEpisode(storedEpisode);
      }
    } else {
      log.fine(' - Cannot save position as episode is null');
    }
  }
}
