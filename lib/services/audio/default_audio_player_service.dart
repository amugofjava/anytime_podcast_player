// Copyright 2020-2022 Ben Hills. All rights reserved.
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
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/persistent_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/state/transcript_state_event.dart';
import 'package:audio_service/audio_service.dart';
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
  var _playbackSpeed = 1.0;
  var _trimSilence = false;
  var _volumeBoost = false;
  var _queue = <Episode>[];

  /// The currently playing episode
  Episode _currentEpisode;

  /// The currently 'processed' transcript;
  Transcript _currentTranscript;

  /// Subscription to the position ticker.
  StreamSubscription<int> _positionSubscription;

  /// Stream showing our current playing state.
  final BehaviorSubject<AudioState> _playingState = BehaviorSubject<AudioState>.seeded(AudioState.none);

  /// Ticks whilst playing. Updates our current position within an episode.
  final _durationTicker = Stream<int>.periodic(Duration(milliseconds: 500)).asBroadcastStream();

  /// Stream for the current position of the playing track.
  final _playPosition = BehaviorSubject<PositionState>();

  /// Stream the current playing episode
  final _episodeEvent = BehaviorSubject<Episode>(sync: true);

  /// Stream transcript events such as search filters and updates.
  final _transcriptEvent = BehaviorSubject<TranscriptState>(sync: true);

  /// Stream for the last audio error as an integer code.
  final _playbackError = PublishSubject<int>();

  final _queueState = BehaviorSubject<QueueListState>();

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
      _loadQueue();
    });
  }

  @override
  Future<void> pause() async => _audioHandler.pause();

  @override
  Future<void> play() {
    if (_cold) {
      _cold = false;
      return playEpisode(episode: _currentEpisode, resume: true);
    } else {
      return _audioHandler.play();
    }
  }

  /// Called by the client (UI), or when we move to a different episode within the queue, to play an episode.
  /// If we have a downloaded copy of the requested episode we will use that; otherwise we will stream the
  /// episode directly.
  @override
  Future<void> playEpisode({Episode episode, bool resume}) async {
    if (episode.guid != '' && _initialised) {
      var uri = await _generateEpisodeUri(episode);

      log.info('Playing episode ${episode?.id} - ${episode?.title} from position ${episode.position}');
      log.fine(' - $uri');

      _playingState.add(AudioState.buffering);
      _playbackSpeed = settingsService.playbackSpeed;
      _trimSilence = settingsService.trimSilence;
      _volumeBoost = settingsService.volumeBoost;

      // If we are currently playing a track - save the position of the current
      // track before switching to the next.
      var currentState = _audioHandler.playbackState.value.processingState ?? AudioProcessingState.idle;

      log.fine(
          'Current playback state is $currentState. Speed = $_playbackSpeed. Trim = $_trimSilence. Volume Boost = $_volumeBoost}');

      if (currentState == AudioProcessingState.ready) {
        await _saveCurrentEpisodePosition();
      } else if (currentState == AudioProcessingState.loading) {
        log.fine('We are loading, so call stop on current playback');
        await _audioHandler.stop();
      }

      // If we have a queue, we are currently playing and the user has elected to play something new,
      // place the current episode at the top of the queue before moving on.
      if (_currentEpisode != null && _currentEpisode.guid != episode.guid && _queue.isNotEmpty) {
        _queue.insert(0, _currentEpisode);
      }

      // If we are attempting to play an episode that is also in the queue, remove it from the queue.
      _queue.removeWhere((e) => episode.guid == e.guid);

      // Current episode is saved. Now we re-point the current episode to the new one passed in.
      _currentEpisode = episode;
      _currentEpisode.played = false;

      await repository.saveEpisode(_currentEpisode);

      /// Update the state of the queue.
      _updateQueueState();
      _updateEpisodeState();

      /// And the position of our current episode.
      _broadcastEpisodePosition(_currentEpisode);

      try {
        // Load ancillary items
        _loadEpisodeAncillaryItems();

        await _audioHandler.playMediaItem(_episodeToMediaItem(_currentEpisode, uri));

        _currentEpisode.duration = _audioHandler.mediaItem.value.duration.inSeconds;

        await repository.saveEpisode(_currentEpisode);
      } catch (e) {
        log.fine('Error during playback');
        log.fine(e.toString());

        _playingState.add(AudioState.error);
        _playingState.add(AudioState.stopped);

        await _audioHandler.stop();
      }
    } else {
      log.fine('ERROR: Attempting to play an empty episode');
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

    _playPosition.add(PositionState(p, duration, complete.toInt(), _currentEpisode, true));

    await _audioHandler.seek(Duration(seconds: position));

    _positionSubscription?.resume();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) => _audioHandler.setSpeed(speed);

  @override
  Future<void> addUpNextEpisode(Episode episode) async {
    log.fine('addUpNextEpisode Adding ${episode.title} - ${episode.guid}');

    if (episode.guid != _currentEpisode?.guid) {
      _queue.add(episode);
      _updateQueueState();
    }
  }

  @override
  Future<bool> removeUpNextEpisode(Episode episode) async {
    var removed = false;
    log.fine('removeUpNextEpisode Removing ${episode.title} - ${episode.guid}');

    var i = _queue.indexWhere((element) => element.guid == episode.guid);

    if (i >= 0) {
      removed = true;
      _queue.removeAt(i);
      _updateQueueState();
    }

    return removed;
  }

  @override
  Future<bool> moveUpNextEpisode(Episode episode, int oldIndex, int newIndex) async {
    var moved = false;
    log.fine('moveUpNextEpisode Moving ${episode.title} - ${episode.guid} from $oldIndex to $newIndex');

    var oldEpisode = _queue.removeAt(oldIndex);

    _queue.insert(newIndex, oldEpisode);
    _updateQueueState();

    return moved;
  }

  @override
  Future<void> clearUpNext() async {
    _queue.clear();
    _updateQueueState();
  }

  @override
  Future<void> stop() {
    _currentEpisode = null;
    return _audioHandler.stop();
  }

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
    /// If _episode is null, we must have stopped whilst still active or we were killed.
    if (_currentEpisode == null) {
      if (_audioHandler?.mediaItem?.value != null) {
        final extras = _audioHandler.mediaItem.value.extras;

        if (extras['eid'] != null) {
          _currentEpisode = await repository.findEpisodeByGuid(extras['eid'] as String);
        }
      } else {
        // Let's see if we have a persisted state
        var ps = await PersistentState.fetchState();

        if (ps != null && ps.state == LastState.paused) {
          _currentEpisode = await repository.findEpisodeById(ps.episodeId);
          _currentEpisode.position = ps.position;
          _playingState.add(AudioState.pausing);

          updateCurrentPosition(_currentEpisode);

          _cold = true;
        }
      }
    } else {
      final playbackState = _audioHandler.playbackState.value;
      final basicState = playbackState?.processingState ?? AudioProcessingState.idle;

      // If we have no state we'll have to assume we stopped whilst suspended.
      if (basicState == AudioProcessingState.idle) {
        /// We will have to assume we have stopped.
        _playingState.add(AudioState.stopped);
      } else if (basicState == AudioProcessingState.ready) {
        _startTicker();
      }
    }

    await PersistentState.clearState();

    if (_currentEpisode != null) {
      _episodeEvent.sink.add(_currentEpisode);
    }

    return Future.value(null);
  }

  void _updateEpisodeState() {
    _episodeEvent.sink.add(_currentEpisode);
  }

  void _updateTranscriptState({TranscriptState state}) {
    if (state == null) {
      if (_currentTranscript != null) {
        _transcriptEvent.sink.add(TranscriptUpdateState(transcript: _currentTranscript));
      }
    } else {
      _transcriptEvent.sink.add(state);
    }
  }

  void _updateQueueState() {
    _queueState.add(QueueListState(playing: _currentEpisode, queue: _queue));
  }

  Future<String> _generateEpisodeUri(Episode episode) async {
    var uri = episode.contentUrl;

    if (episode.downloadState == DownloadState.downloaded) {
      if (await hasStoragePermission()) {
        uri = await resolvePath(episode);

        episode.streaming = false;
      } else {
        throw Exception('Insufficient storage permissions');
      }
    }

    return uri;
  }

  Future<void> _persistState() async {
    var currentPosition = _audioHandler?.playbackState?.value?.position?.inMilliseconds ?? 0;

    /// We only need to persist if we are paused.
    if (_playingState.value == AudioState.pausing) {
      await PersistentState.persistState(Persistable(
        episodeId: _currentEpisode.id,
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

  @override
  Future<void> searchTranscript(String search) async {
    if (search != null) {
      search = search.trim();

      final subtitles = _currentEpisode.transcript.subtitles.where((subtitle) {
        return subtitle.data.toLowerCase().contains(search.toLowerCase());
      }).toList();

      _currentTranscript = Transcript(
        id: _currentEpisode.transcript.id,
        guid: _currentEpisode.transcript.guid,
        filtered: true,
        subtitles: subtitles,
      );

      _updateTranscriptState();
    }
  }

  @override
  Future<void> clearTranscript() async {
    _currentTranscript = _currentEpisode.transcript;
    _currentTranscript.filtered = false;

    _updateTranscriptState();
  }

  MediaItem _episodeToMediaItem(Episode episode, String uri) {
    return MediaItem(
      id: uri,
      title: episode.title ?? 'Unknown Title',
      artist: episode.author ?? 'Unknown Title',
      artUri: Uri.parse(episode.imageUrl),
      duration: Duration(seconds: episode.duration ?? 0),
      extras: <String, dynamic>{
        'position': episode.position ?? 0,
        'downloaded': episode.downloaded,
        'speed': _playbackSpeed,
        'trim': _trimSilence,
        'boost': _volumeBoost,
        'eid': episode.guid,
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
          _stopTicker();
          break;
        case AudioProcessingState.loading:
          _playingState.add(AudioState.buffering);
          break;
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
          _completed();
          break;
        case AudioProcessingState.error:
          _playingState.add(AudioState.error);
          break;
      }
    });
  }

  Future<void> _loadQueue() async {
    _queue = await podcastService.loadQueue();
  }

  Future<void> _completed() async {
    log.fine('We have completed episode ${_currentEpisode?.title}');

    _stopTicker();

    if (_queue.isEmpty) {
      log.fine('Queue is empty so we will stop');
      _queue = <Episode>[];
      _currentEpisode = null;
      _playingState.add(AudioState.stopped);

      await _audioHandler.customAction('queueend');
    } else {
      log.fine('Queue has ${_queue.length} episodes left');
      _currentEpisode = null;
      var ep = _queue.removeAt(0);

      await playEpisode(episode: ep);

      _updateQueueState();
    }
  }

  /// This method is called when audio_service sends a [AudioProcessingState.loading] event.
  void _loadEpisodeAncillaryItems() async {
    if (_currentEpisode == null) {
      log.fine('_onLoadEpisode: _episode is null - cannot load!');
      return;
    }

    _updateEpisodeState();

    // Chapters
    if (_currentEpisode.hasChapters && _currentEpisode.streaming) {
      _currentEpisode.chaptersLoading = true;
      _currentEpisode.chapters = <Chapter>[];

      _updateEpisodeState();

      await _onUpdatePosition();

      log.fine('Loading chapters from ${_currentEpisode.chaptersUrl}');

      _currentEpisode.chapters = await podcastService.loadChaptersByUrl(url: _currentEpisode.chaptersUrl);
      _currentEpisode.chaptersLoading = false;

      _updateEpisodeState();

      log.fine('We have ${_currentEpisode.chapters?.length} chapters');
      _currentEpisode = await repository.saveEpisode(_currentEpisode);
    }

    if (_currentEpisode.hasTranscripts) {
      Transcript transcript;

      if (_currentEpisode.streaming) {
        var sub = _currentEpisode.transcriptUrls
            .firstWhere((element) => element.type == TranscriptFormat.json, orElse: () => null);

        sub ??= _currentEpisode.transcriptUrls
            .firstWhere((element) => element.type == TranscriptFormat.subrip, orElse: () => null);

        if (sub != null) {
          _updateTranscriptState(state: TranscriptLoadingState());

          log.fine('Loading transcript from ${sub.url}');

          transcript = await podcastService.loadTranscriptByUrl(transcriptUrl: sub);

          log.fine('We have ${transcript.subtitles?.length} transcript lines');
        }
      } else {
        transcript = await repository.findTranscriptById(_currentEpisode.transcriptId);
      }

      if (transcript != null) {
        _currentEpisode.transcript = transcript;
        _currentTranscript = transcript;
        _updateTranscriptState();
      }
    } else {
      _updateTranscriptState(state: TranscriptUnavailableState());
    }

    /// Update the state of the current episode & transcript.
    _updateEpisodeState();

    await _onUpdatePosition();
  }

  void _broadcastEpisodePosition(Episode e) {
    if (e != null) {
      var duration = Duration(seconds: e.duration);
      var complete = e.position > 0 ? (duration.inSeconds / e.position) * 100 : 0;

      _playPosition.add(PositionState(Duration(milliseconds: e.position), duration, complete.toInt(), e, false));
    }
  }

  /// Saves the current play position to persistent storage. This enables a
  /// podcast to continue playing where it left off if played at a later
  /// time.
  Future<void> _saveCurrentEpisodePosition({bool complete = false}) async {
    if (_currentEpisode != null) {
      // The episode may have been updated elsewhere - re-fetch it.
      var currentPosition = _audioHandler.playbackState.value.position.inMilliseconds ?? 0;

      _currentEpisode = await repository.findEpisodeByGuid(_currentEpisode.guid);

      log.fine(
          '_saveCurrentEpisodePosition(): Current position is $currentPosition - stored position is ${_currentEpisode.position} complete is $complete');

      if (currentPosition != _currentEpisode.position) {
        _currentEpisode.position = complete ? 0 : currentPosition;
        _currentEpisode.played = complete;

        _currentEpisode = await repository.saveEpisode(_currentEpisode);
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

      _playPosition.add(PositionState(position, duration, complete.toInt(), _currentEpisode, buffering));
    }
  }

  /// Calculate our current chapter based on playback position, and if it's different to
  /// the currently stored chapter - update.
  void _updateChapter(int seconds, int duration) {
    if (_currentEpisode == null) {
      log.fine('Warning. Attempting to update chapter information on a null _episode');
    } else if (_currentEpisode.hasChapters && _currentEpisode.chaptersAreLoaded) {
      final chapters = _currentEpisode.chapters;

      for (var chapterPtr = 0; chapterPtr < _currentEpisode.chapters.length; chapterPtr++) {
        final startTime = chapters[chapterPtr].startTime;
        final endTime =
            chapterPtr == (_currentEpisode.chapters.length - 1) ? duration : chapters[chapterPtr + 1].startTime;

        if (seconds >= startTime && seconds < endTime) {
          if (chapters[chapterPtr] != _currentEpisode.currentChapter) {
            _currentEpisode.currentChapter = chapters[chapterPtr];
            _episodeEvent.sink.add(_currentEpisode);
            break;
          }
        }
      }
    }
  }

  @override
  Episode get nowPlaying => _currentEpisode;

  /// Get the current playing state
  @override
  Stream<AudioState> get playingState => _playingState.stream;

  Stream<EpisodeState> get episodeListener => repository.episodeListener;

  @override
  Stream<PositionState> get playPosition => _playPosition.stream;

  @override
  Stream<Episode> get episodeEvent => _episodeEvent.stream;

  @override
  Stream<TranscriptState> get transcriptEvent => _transcriptEvent.stream;

  @override
  Stream<int> get playbackError => _playbackError.stream;

  @override
  Stream<QueueListState> get queueState => _queueState.stream;
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
    _initPlayer();
  }

  void _initPlayer() {
    if (Platform.isAndroid) {
      _androidLoudnessEnhancer = AndroidLoudnessEnhancer();
      _androidLoudnessEnhancer.setEnabled(true);
      _audioPipeline = AudioPipeline(androidAudioEffects: [_androidLoudnessEnhancer]);
      _player = AudioPlayer(
        audioPipeline: _audioPipeline,
        userAgent: Environment.userAgent(),
      );
    } else {
      _player = AudioPlayer(
        /// Temporarily disable custom user agent to get over proxy issue in just_audio on iOS.
        /// https://github.com/ryanheise/audio_service/issues/915
        //   userAgent: Environment.userAgent(),
          audioLoadConfiguration: AudioLoadConfiguration(
            androidLoadControl: AndroidLoadControl(
              backBufferDuration: Duration(seconds: 45),
            ),
            darwinLoadControl: DarwinLoadControl(),
          ));
    }

    /// List to events from the player itself, transform the player event to an audio service one
    /// and hand it off to the playback state stream to inform our client(s).
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState).catchError((Object o, StackTrace s) async {
      log.fine('Playback error received');
      log.fine(o.toString());

      await _player.stop();
    });
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    _currentItem = mediaItem;

    var downloaded = mediaItem.extras['downloaded'] as bool ?? true;
    var startPosition = mediaItem.extras['position'] as int ?? 0;
    var playbackSpeed = mediaItem.extras['speed'] as double ?? 0.0;
    var start = startPosition > 0 ? Duration(milliseconds: startPosition) : Duration.zero;
    var boost = mediaItem.extras['boost'] as bool ?? true;
    // Commented out until just audio position bug is fixed
    // var trim = mediaItem.extras['trim'] as bool ?? true;

    log.fine('loading new track ${mediaItem.id} - from position ${start.inSeconds} (${start.inMilliseconds})');

    var source = downloaded
        ? AudioSource.uri(
            Uri.parse("file://${mediaItem.id}"),
            tag: mediaItem.id,
          )
        : AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem.id);

    try {
      var duration = await _player.setAudioSource(source, initialPosition: start);

      /// If we don't already have a duration and we have been able to calculate it from
      /// beginning to fetch the media, update the current media item with the duration.
      if (duration != null && (_currentItem.duration == null || _currentItem.duration.inSeconds == 0)) {
        _currentItem = _currentItem.copyWith(duration: duration);
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
    } on PlayerException catch (e) {
      log.fine('PlayerException');
      log.fine(' - Error code ${e.code}');
      log.fine('  - ${e.message}');
      await stop();
      log.fine(e);
    } on PlayerInterruptedException catch (e) {
      log.fine('PlayerInterruptedException');
      await stop();
      log.fine(e);
    } catch (e) {
      log.fine('General playback exception');
      await stop();
      log.fine(e);
    }

    super.mediaItem.add(_currentItem);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    log.fine('pause() triggered - saving position');
    await _savePosition();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    log.fine('stop() triggered - saving position');

    await _player.stop();
    await _savePosition();
  }

  Future<void> complete() async {
    log.fine('complete() triggered - saving position');
    await _savePosition(complete: true);
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
      case 'queueend':
        log.fine('Received custom action: queue end');
        await _player.stop();
        break;
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> trimSilence(bool trim) async {
    _trimSilence = trim;
    await _player.setSkipSilenceEnabled(trim);
  }

  Future<void> volumeBoost(bool boost) async {
    /// For now, we know we only have one effect so we can cheat
    var e = _audioPipeline.androidAudioEffects[0];

    if (e is AndroidLoudnessEnhancer) {
      e.setTargetGain(boost ? audioGain : 0.0);
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    log.fine('_transformEvent Sending state ${_player.processingState}. Playing: ${_player.playing}');

    if (_player.processingState == ProcessingState.completed) {
      log.fine('Transform event has received a complete - calling complete();');
      complete();
    }

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
      processingState: {
        ProcessingState.idle: _player.playing ? AudioProcessingState.ready : AudioProcessingState.idle,
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

      log.fine(
          '_savePosition(): Current position is $currentPosition - stored position is ${storedEpisode.position} complete is $complete on episode ${storedEpisode.title}');

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
