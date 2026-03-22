// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/episode_analysis_transcript_codec.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// The BLoC provides access to [Episode] details outside the direct scope
/// of a [Podcast].
class EpisodeBloc extends Bloc {
  final log = Logger('EpisodeBloc');
  final PodcastService podcastService;
  final AudioPlayerService audioPlayerService;
  final EpisodeAnalysisService analysisService;
  final Duration analysisPollInterval;

  /// Add to sink to fetch list of current downloaded episodes.
  final BehaviorSubject<bool> _downloadsInput = BehaviorSubject<bool>();

  /// Add to sink to fetch list of current episodes.
  final BehaviorSubject<bool> _episodesInput = BehaviorSubject<bool>();

  /// Add to sink to delete the passed [Episode] from storage.
  final PublishSubject<Episode?> _deleteDownload = PublishSubject<Episode>();

  /// Add to sink to toggle played status of the [Episode].
  final PublishSubject<Episode?> _togglePlayed = PublishSubject<Episode>();

  /// Stream of currently downloaded episodes
  Stream<BlocState<List<Episode>>>? _downloadsOutput;

  /// Stream of current episodes
  Stream<BlocState<List<Episode>>>? _episodesOutput;

  /// Cache of our currently downloaded episodes.
  List<Episode>? _episodes;

  final _analysisTasks = <String, Future<Episode>>{};

  EpisodeBloc({
    required this.podcastService,
    required this.audioPlayerService,
    required this.analysisService,
    this.analysisPollInterval = const Duration(seconds: 5),
  }) {
    _init();
  }

  void _init() {
    _downloadsOutput = _downloadsInput.switchMap<BlocState<List<Episode>>>((bool silent) => _loadDownloads(silent));
    _episodesOutput = _episodesInput.switchMap<BlocState<List<Episode>>>((bool silent) => _loadEpisodes(silent));

    _handleDeleteDownloads();
    _handleMarkAsPlayed();
    _listenEpisodeEvents();
  }

  void _handleDeleteDownloads() async {
    _deleteDownload.stream.listen((episode) async {
      var nowPlaying = audioPlayerService.nowPlaying?.guid == episode?.guid;

      /// If we are attempting to delete the episode we are currently playing, we need to stop the audio.
      if (nowPlaying) {
        await audioPlayerService.stop();
      }

      /// If this episode is queued up, clear it from the queue before deleting it.
      await audioPlayerService.removeUpNextEpisode(episode!);
      await podcastService.deleteDownload(episode);

      fetchDownloads(true);
    });
  }

  void _handleMarkAsPlayed() async {
    _togglePlayed.stream.listen((episode) async {
      await podcastService.toggleEpisodePlayed(episode!);

      fetchDownloads(true);
    });
  }

  void _listenEpisodeEvents() {
    // Listen for episode updates. If the episode is downloaded, we need to update.
    podcastService.episodeListener
        .where((event) => event.episode.downloaded || event.episode.played)
        .listen((event) => fetchDownloads(true));
  }

  Stream<BlocState<List<Episode>>> _loadDownloads(bool silent) async* {
    if (!silent) {
      yield BlocLoadingState();
    }

    _episodes = await podcastService.loadDownloads();

    yield BlocPopulatedState<List<Episode>>(results: _episodes);
  }

  Stream<BlocState<List<Episode>>> _loadEpisodes(bool silent) async* {
    if (!silent) {
      yield BlocLoadingState();
    }

    _episodes = await podcastService.loadEpisodes();

    yield BlocPopulatedState<List<Episode>>(results: _episodes);
  }

  @override
  void dispose() {
    _downloadsInput.close();
    _episodesInput.close();
    _deleteDownload.close();
    _togglePlayed.close();
    super.dispose();
  }

  void Function(bool) get fetchDownloads => _downloadsInput.add;

  void Function(bool) get fetchEpisodes => _episodesInput.add;

  Stream<BlocState<List<Episode>>>? get downloads => _downloadsOutput;

  Stream<BlocState<List<Episode>>>? get episodes => _episodesOutput;

  void Function(Episode?) get deleteDownload => _deleteDownload.add;

  void Function(Episode?) get togglePlayed => _togglePlayed.add;

  Stream<EpisodeState> get episodeListener => podcastService.episodeListener;

  Future<Episode> analyzeAds(Episode episode, {bool force = false}) {
    final guid = episode.guid;
    final existingTask = _analysisTasks[guid];

    if (existingTask != null) {
      return existingTask;
    }

    final task = _analyzeAds(episode, force: force).whenComplete(() {
      _analysisTasks.remove(guid);
    });

    _analysisTasks[guid] = task;

    return task;
  }

  Future<Episode> _analyzeAds(Episode episode, {required bool force}) async {
    final existingTranscript = await _loadExistingTranscript(episode);
    final submitResponse = await analysisService.submit(
      episode: episode,
      force: force,
      transcript: existingTranscript == null ? null : EpisodeAnalysisTranscriptCodec.toPayload(existingTranscript),
    );

    var currentEpisode = await _persistAnalysisUpdate(
      episode,
      status: submitResponse.status,
      jobId: submitResponse.jobId,
      error: null,
    );

    while (true) {
      final pollResponse = await analysisService.poll(jobId: submitResponse.jobId);

      currentEpisode = await _persistAnalysisUpdate(
        currentEpisode,
        status: pollResponse.status,
        jobId: pollResponse.jobId,
        error: pollResponse.error,
        adSegments: pollResponse.isCompleted ? pollResponse.adSegments : null,
        transcript: pollResponse.transcript,
      );

      if (pollResponse.status == EpisodeAnalysisJobStatus.completed) {
        return currentEpisode;
      }

      if (pollResponse.status == EpisodeAnalysisJobStatus.failed) {
        throw EpisodeAnalysisFailedException(
          pollResponse.error ?? 'Episode analysis failed for ${episode.guid}.',
        );
      }

      if (pollResponse.status == EpisodeAnalysisJobStatus.unknown) {
        throw EpisodeAnalysisFailedException(
          'Episode analysis returned an unknown status for ${episode.guid}.',
        );
      }

      if (analysisPollInterval > Duration.zero) {
        await Future<void>.delayed(analysisPollInterval);
      }
    }
  }

  Future<Episode> _persistAnalysisUpdate(
    Episode episode, {
    required EpisodeAnalysisJobStatus status,
    required String jobId,
    required String? error,
    List<AdSegment>? adSegments,
    EpisodeAnalysisTranscriptDto? transcript,
  }) async {
    final currentEpisode = await _loadCurrentEpisode(episode);
    final previousTranscriptId = currentEpisode.transcriptId;

    currentEpisode.analysisStatus = status.name;
    currentEpisode.analysisJobId = jobId;
    currentEpisode.analysisError = error;
    currentEpisode.analysisUpdatedAt = DateTime.now();

    if (adSegments != null) {
      currentEpisode.adSegments = List.unmodifiable(adSegments);
    }

    if (status == EpisodeAnalysisJobStatus.completed && transcript != null) {
      var savedTranscript = EpisodeAnalysisTranscriptCodec.fromDto(transcript, guid: currentEpisode.guid);
      savedTranscript = await podcastService.saveTranscript(savedTranscript);

      currentEpisode.transcript = savedTranscript;
      currentEpisode.transcriptId = savedTranscript.id;

      if (previousTranscriptId != null && previousTranscriptId > 0 && previousTranscriptId != savedTranscript.id) {
        await podcastService.repository.deleteTranscriptById(previousTranscriptId);
      }
    }

    return podcastService.saveEpisode(currentEpisode);
  }

  Future<Episode> _loadCurrentEpisode(Episode episode) async {
    return await podcastService.repository.findEpisodeByGuid(episode.guid) ?? episode;
  }

  Future<Transcript?> _loadExistingTranscript(Episode episode) async {
    if (episode.transcript != null && episode.transcript!.transcriptAvailable) {
      return episode.transcript;
    }

    final currentEpisode = await _loadCurrentEpisode(episode);

    if (currentEpisode.transcript != null && currentEpisode.transcript!.transcriptAvailable) {
      return currentEpisode.transcript;
    }

    if (currentEpisode.transcriptId != null && currentEpisode.transcriptId! > 0) {
      final storedTranscript = await podcastService.repository.findTranscriptById(currentEpisode.transcriptId!);

      if (storedTranscript != null && storedTranscript.transcriptAvailable) {
        return storedTranscript;
      }
    }

    if (currentEpisode.transcriptUrls.isEmpty) {
      return null;
    }

    var transcriptUrl =
        currentEpisode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.vtt);
    transcriptUrl ??=
        currentEpisode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.json);
    transcriptUrl ??=
        currentEpisode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.subrip);

    if (transcriptUrl == null) {
      return null;
    }

    return podcastService.loadTranscriptByUrl(transcriptUrl: transcriptUrl);
  }
}

class EpisodeAnalysisFailedException implements Exception {
  final String message;

  EpisodeAnalysisFailedException(this.message);

  @override
  String toString() => 'EpisodeAnalysisFailedException($message)';
}
