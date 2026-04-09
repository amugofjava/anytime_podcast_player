// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/episode_analysis_transcript_codec.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// The BLoC provides access to [Episode] details outside the direct scope
/// of a [Podcast].
class EpisodeBloc extends Bloc {
  final log = Logger('EpisodeBloc');
  final PodcastService podcastService;
  final AudioPlayerService audioPlayerService;
  final EpisodeAnalysisService analysisService;
  final SettingsService settingsService;
  final EpisodeTranscriptionService transcriptionService;
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
  final _subscriptions = <StreamSubscription<dynamic>>[];

  EpisodeBloc({
    required this.podcastService,
    required this.audioPlayerService,
    required this.analysisService,
    required this.settingsService,
    required this.transcriptionService,
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
    final subscription = _deleteDownload.stream.listen((episode) async {
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

    _subscriptions.add(subscription);
  }

  void _handleMarkAsPlayed() async {
    final subscription = _togglePlayed.stream.listen((episode) async {
      await podcastService.toggleEpisodePlayed(episode!);

      fetchDownloads(true);
    });

    _subscriptions.add(subscription);
  }

  void _listenEpisodeEvents() {
    // Listen for episode updates. If the episode is downloaded, we need to update.
    final subscription = podcastService.episodeListener
        .where((event) => event.episode.downloaded || event.episode.played)
        .listen((event) => fetchDownloads(true));

    _subscriptions.add(subscription);
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
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

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

  Future<Episode> analyzeAds(
    Episode episode, {
    bool force = false,
    bool consentToUpload = false,
  }) {
    final guid = episode.guid;
    final existingTask = _analysisTasks[guid];

    if (existingTask != null) {
      return existingTask;
    }

    final task = _analyzeAds(
      episode,
      force: force,
      consentToUpload: consentToUpload,
    ).whenComplete(() {
      _analysisTasks.remove(guid);
    });

    _analysisTasks[guid] = task;

    return task;
  }

  Future<Episode> generateLocalTranscript(
    Episode episode, {
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    if (!episode.downloaded) {
      throw const EpisodeTranscriptionException(
        'Download the episode before generating an AI transcript.',
      );
    }

    final transcript = await transcriptionService.transcribeDownloadedEpisode(
      episode: episode,
      onProgress: onProgress,
    );

    transcript.guid = episode.guid;

    if (!transcript.isAppGeneratedAiTranscript) {
      transcript.provenance = settingsService.transcriptionProvider == TranscriptionProvider.openAi
          ? TranscriptProvenance.openAi
          : TranscriptProvenance.localAi;
    }

    transcript.provider ??=
        settingsService.transcriptionProvider == TranscriptionProvider.openAi ? 'whisper-1' : 'whisper';

    return _persistTranscriptReplacement(
      episode,
      transcript: transcript,
    );
  }

  Future<Episode> generateTranscriptAndAnalyzeAds(
    Episode episode, {
    bool force = false,
    bool consentToUpload = false,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    final updatedEpisode = await generateLocalTranscript(
      episode,
      onProgress: onProgress,
    );

    return analyzeAds(
      updatedEpisode,
      force: force,
      consentToUpload: consentToUpload,
    );
  }

  Future<Episode> _analyzeAds(
    Episode episode, {
    required bool force,
    required bool consentToUpload,
  }) async {
    final provider = settingsService.transcriptUploadProvider;

    if (provider == TranscriptUploadProvider.disabled) {
      throw EpisodeAnalysisFailedException(
        'Ad analysis is not configured in this build.',
      );
    }

    if (!consentToUpload) {
      throw EpisodeAnalysisFailedException(
        'Analysis requires explicit confirmation for this episode.',
      );
    }

    // Gemini uses a single-step audio-native approach — no transcript needed.
    final isAudioDirect = provider == TranscriptUploadProvider.gemini;

    log.fine('analyzeAds: provider=$provider isAudioDirect=$isAudioDirect '
        'downloaded=${episode.downloaded} filepath=${episode.filepath}');

    EpisodeAnalysisTranscriptPayload? transcriptPayload;

    if (!isAudioDirect) {
      final existingTranscript = await _loadExistingAiTranscript(episode);

      if (existingTranscript == null || !existingTranscript.transcriptAvailable) {
        throw EpisodeAnalysisFailedException(
          'Generate an AI transcript before analyzing ads.',
        );
      }

      transcriptPayload = EpisodeAnalysisTranscriptCodec.toPayload(existingTranscript);
    } else {
      if (!episode.downloaded || episode.filepath == null || episode.filepath!.isEmpty) {
        throw EpisodeAnalysisFailedException(
          'Download the episode before using Gemini audio analysis.',
        );
      }
    }

    late EpisodeAnalysisSubmitResponse submitResponse;

    try {
      submitResponse = await analysisService.submit(
        episode: episode,
        force: force,
        transcript: transcriptPayload,
      );
    } catch (error) {
      throw EpisodeAnalysisFailedException(_analysisErrorMessage(error));
    }

    var currentEpisode = await _persistAnalysisUpdate(
      episode,
      status: submitResponse.status,
      jobId: submitResponse.jobId,
      error: null,
    );

    while (true) {
      late EpisodeAnalysisStatusResponse pollResponse;

      try {
        pollResponse = await analysisService.poll(jobId: submitResponse.jobId);
      } catch (error) {
        throw EpisodeAnalysisFailedException(_analysisErrorMessage(error));
      }

      currentEpisode = await _persistAnalysisUpdate(
        currentEpisode,
        status: pollResponse.status,
        jobId: pollResponse.jobId,
        error: pollResponse.error,
        adSegments: pollResponse.isCompleted ? pollResponse.adSegments : null,
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
  }) async {
    final currentEpisode = await _loadCurrentEpisode(episode);

    currentEpisode.analysisStatus = status.name;
    currentEpisode.analysisJobId = jobId;
    currentEpisode.analysisError = error;
    currentEpisode.analysisUpdatedAt = DateTime.now();

    if (adSegments != null) {
      currentEpisode.adSegments = List.unmodifiable(adSegments);
    }

    return podcastService.saveEpisode(currentEpisode);
  }

  Future<Episode> _loadCurrentEpisode(Episode episode) async {
    return await podcastService.repository.findEpisodeByGuid(episode.guid) ?? episode;
  }

  Future<Episode> _persistTranscriptReplacement(
    Episode episode, {
    required Transcript transcript,
  }) async {
    final currentEpisode = await _loadCurrentEpisode(episode);
    final previousTranscriptId = currentEpisode.transcriptId;
    var savedTranscript = await podcastService.saveTranscript(transcript);

    currentEpisode.transcript = savedTranscript;
    currentEpisode.transcriptId = savedTranscript.id;
    currentEpisode.analysisStatus = null;
    currentEpisode.analysisJobId = null;
    currentEpisode.analysisError = null;
    currentEpisode.analysisUpdatedAt = null;
    currentEpisode.adSegments = const <AdSegment>[];

    if (previousTranscriptId != null && previousTranscriptId > 0 && previousTranscriptId != savedTranscript.id) {
      await podcastService.repository.deleteTranscriptById(previousTranscriptId);
    }

    return podcastService.saveEpisode(currentEpisode);
  }

  Future<Transcript?> _loadExistingAiTranscript(Episode episode) async {
    if (episode.transcript != null && episode.transcript!.transcriptAvailable) {
      return episode.transcript!.isAppGeneratedAiTranscript ? episode.transcript : null;
    }

    final currentEpisode = await _loadCurrentEpisode(episode);

    if (currentEpisode.transcript != null && currentEpisode.transcript!.transcriptAvailable) {
      return currentEpisode.transcript!.isAppGeneratedAiTranscript ? currentEpisode.transcript : null;
    }

    if (currentEpisode.transcriptId != null && currentEpisode.transcriptId! > 0) {
      final storedTranscript = await podcastService.repository.findTranscriptById(currentEpisode.transcriptId!);

      if (storedTranscript != null &&
          storedTranscript.transcriptAvailable &&
          storedTranscript.isAppGeneratedAiTranscript) {
        return storedTranscript;
      }
    }

    return null;
  }

  String _analysisErrorMessage(Object error) {
    final description = error.toString();

    if (description.startsWith('Exception: ')) {
      return description.substring('Exception: '.length);
    }

    if (description.startsWith('StateError: ')) {
      return description.substring('StateError: '.length);
    }

    return description;
  }
}

class EpisodeAnalysisFailedException implements Exception {
  final String message;

  EpisodeAnalysisFailedException(this.message);

  @override
  String toString() => 'EpisodeAnalysisFailedException($message)';
}
