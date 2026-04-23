// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/sleep.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/analysis/background/background_analysis_service.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/state/ad_skip_state.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/library_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/state/transcript_state_event.dart';
import 'package:anytime/ui/app_scaffold_messenger.dart';
import 'package:anytime/ui/podcast/ad_skip_listener.dart';
import 'package:anytime/ui/podcast/episode_details.dart';
import 'package:anytime/ui/podcast/now_playing_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  testWidgets('EpisodeAnalysisPanel confirms and generates a local transcript', (tester) async {
    final repository = _FakeRepository();
    final episode = Episode(
      id: 1,
      guid: 'ep-transcript',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Transcript Episode',
      contentUrl: 'https://cdn.example.com/transcript.mp3',
      downloadPercentage: 100,
    );
    repository.episodesByGuid[episode.guid] = episode;

    final transcriptionService = _FakeEpisodeTranscriptionService(
      transcript: Transcript(
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 2),
            data: 'Local AI line',
          ),
        ],
      ),
    );
    final podcastService = _FakePodcastService(repository: repository);
    final bloc = EpisodeBloc(
      podcastService: podcastService,
      audioPlayerService: _FakeAudioPlayerService(),
      analysisService: _FakeEpisodeAnalysisService(),
      settingsService: _FakeSettingsService(),
      transcriptionService: transcriptionService,
      analysisPollInterval: Duration.zero,
    );
    addTearDown(() async {
      bloc.dispose();
      await podcastService.dispose();
    });

    await tester.pumpWidget(_wrapWithEpisodeBloc(bloc, episode));

    await tester.tap(find.text('Generate AI Transcript'));
    await tester.pumpAndSettle();
    expect(find.text('Generate On-Device Transcript?'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(transcriptionService.callCount, 1);
    expect(find.text('AI transcript ready.'), findsWidgets);
  });

  testWidgets('EpisodeAnalysisPanel can transcribe and analyze in one go', (tester) async {
    final repository = _FakeRepository();
    final episode = Episode(
      id: 11,
      guid: 'ep-transcribe-analyze',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Transcribe and Analyze Episode',
      contentUrl: 'https://cdn.example.com/transcribe-analyze.mp3',
      downloadPercentage: 100,
    );
    repository.episodesByGuid[episode.guid] = episode;

    final transcriptionService = _FakeEpisodeTranscriptionService(
      transcript: Transcript(
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 2),
            data: 'Combined flow line',
          ),
        ],
      ),
    );
    final podcastService = _FakePodcastService(repository: repository);
    final analysisService = _FakeEpisodeAnalysisService(
      pollResponses: <EpisodeAnalysisStatusResponse>[
        EpisodeAnalysisStatusResponse(
          jobId: 'job-1',
          status: EpisodeAnalysisJobStatus.completed,
          adSegments: const <AdSegment>[
            AdSegment(
              startMs: 1000,
              endMs: 4000,
              reason: 'midroll',
              confidence: 0.8,
            ),
          ],
        ),
      ],
    );
    final bloc = EpisodeBloc(
      podcastService: podcastService,
      audioPlayerService: _FakeAudioPlayerService(),
      analysisService: analysisService,
      settingsService: _FakeSettingsService(),
      transcriptionService: transcriptionService,
      backgroundAnalysisService: DefaultBackgroundAnalysisService(repository),
      analysisPollInterval: Duration.zero,
    );
    addTearDown(() async {
      bloc.dispose();
      await podcastService.dispose();
    });

    await tester.pumpWidget(_wrapWithEpisodeBloc(bloc, episode));

    await tester.tap(find.text('Transcribe & Analyze'));
    await tester.pumpAndSettle();
    expect(find.text('Transcribe and Analyze?'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(transcriptionService.callCount, 1);
    expect(analysisService.submitCount, 1);
    expect(find.text('Analysis complete - 1 ad segment'), findsOneWidget);
    expect(find.text('Reason: midroll'), findsOneWidget);
  });

  testWidgets('EpisodeAnalysisPanel confirms upload and renders completed analysis status', (tester) async {
    final repository = _FakeRepository();
    final transcript = Transcript(
      id: 7,
      guid: 'ep-analysis',
      provenance: TranscriptProvenance.localAi,
      subtitles: <Subtitle>[
        Subtitle(
          index: 1,
          start: Duration.zero,
          end: const Duration(seconds: 2),
          data: 'Sponsored by Example Co.',
        ),
      ],
    );
    final episode = Episode(
      id: 2,
      guid: 'ep-analysis',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Analysis Episode',
      contentUrl: 'https://cdn.example.com/analysis.mp3',
      downloadPercentage: 100,
      transcriptId: 7,
    )..transcript = transcript;

    repository.episodesByGuid[episode.guid] = episode;
    repository.transcriptsById[7] = transcript;

    final podcastService = _FakePodcastService(repository: repository);
    final analysisService = _FakeEpisodeAnalysisService(
      pollResponses: <EpisodeAnalysisStatusResponse>[
        EpisodeAnalysisStatusResponse(
          jobId: 'job-1',
          status: EpisodeAnalysisJobStatus.completed,
          adSegments: const <AdSegment>[
            AdSegment(
              startMs: 1000,
              endMs: 4000,
              reason: 'preroll',
              confidence: 0.9,
            ),
          ],
        ),
      ],
    );
    final bloc = EpisodeBloc(
      podcastService: podcastService,
      audioPlayerService: _FakeAudioPlayerService(),
      analysisService: analysisService,
      settingsService: _FakeSettingsService(),
      transcriptionService: _FakeEpisodeTranscriptionService(),
      backgroundAnalysisService: DefaultBackgroundAnalysisService(repository),
      analysisPollInterval: Duration.zero,
    );
    addTearDown(() async {
      bloc.dispose();
      await podcastService.dispose();
    });

    await tester.pumpWidget(_wrapWithEpisodeBloc(bloc, episode));

    await tester.tap(find.text('Analyze Ads'));
    await tester.pumpAndSettle();
    expect(find.text('Upload Transcript?'), findsOneWidget);

    await tester.tap(find.text('Upload'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(analysisService.submitCount, 1);
    expect(find.text('Analysis complete - 1 ad segment'), findsOneWidget);
    expect(find.text('Detected ad segments'), findsOneWidget);
    expect(find.text('00:01 - 00:04 (3s)'), findsOneWidget);
    expect(find.text('Reason: preroll'), findsOneWidget);
    expect(find.text('Confidence: 90%'), findsOneWidget);
  });

  testWidgets('EpisodeAnalysisPanel shows an explicit no-ads message after analysis completes', (tester) async {
    final repository = _FakeRepository();
    final transcript = Transcript(
      id: 12,
      guid: 'ep-no-ads',
      provenance: TranscriptProvenance.localAi,
      subtitles: <Subtitle>[
        Subtitle(
          index: 1,
          start: Duration.zero,
          end: const Duration(seconds: 2),
          data: 'Just regular conversation.',
        ),
      ],
    );
    final episode = Episode(
      id: 12,
      guid: 'ep-no-ads',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'No Ads Episode',
      contentUrl: 'https://cdn.example.com/no-ads.mp3',
      downloadPercentage: 100,
      transcriptId: 12,
    )..transcript = transcript;

    repository.episodesByGuid[episode.guid] = episode;
    repository.transcriptsById[12] = transcript;

    final podcastService = _FakePodcastService(repository: repository);
    final analysisService = _FakeEpisodeAnalysisService(
      pollResponses: <EpisodeAnalysisStatusResponse>[
        EpisodeAnalysisStatusResponse(
          jobId: 'job-1',
          status: EpisodeAnalysisJobStatus.completed,
          adSegments: const <AdSegment>[],
        ),
      ],
    );
    final bloc = EpisodeBloc(
      podcastService: podcastService,
      audioPlayerService: _FakeAudioPlayerService(),
      analysisService: analysisService,
      settingsService: _FakeSettingsService(),
      transcriptionService: _FakeEpisodeTranscriptionService(),
      analysisPollInterval: Duration.zero,
    );
    addTearDown(() async {
      bloc.dispose();
      await podcastService.dispose();
    });

    await tester.pumpWidget(_wrapWithEpisodeBloc(bloc, episode));

    await tester.tap(find.text('Analyze Ads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Analysis complete - no ad segments detected'), findsOneWidget);
  });

  testWidgets('AdSkipListener shows the prompt and wires the skip action', (tester) async {
    final audioService = _FakeAudioPlayerService();
    final audioBloc = AudioBloc(audioPlayerService: audioService);
    addTearDown(() {
      audioBloc.dispose();
      audioService.dispose();
    });

    await tester.pumpWidget(
      Provider<AudioBloc>.value(
        value: audioBloc,
        child: const MaterialApp(
          home: AdSkipListener(
            child: Scaffold(
              body: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    final episode = Episode(
      guid: 'ep-skip',
      podcast: 'Podcast',
      title: 'Skip Episode',
      contentUrl: 'https://cdn.example.com/skip.mp3',
    );
    const segment = AdSegment(startMs: 1000, endMs: 4000);

    audioService.emitAdSkipEvent(AdSkipPromptState(
      episode: episode,
      segment: segment,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Ad detected'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(audioService.skipActiveAdCallCount, 1);

    audioService.emitAdSkipEvent(AdSkipClearedState(
      episode: episode,
      segment: segment,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ad detected'), findsNothing);
  });

  testWidgets('NowPlayingOptionsSelectorWide exposes AI, transcript, and queue tabs', (tester) async {
    final repository = _FakeRepository();
    final transcript = Transcript(
      id: 9,
      guid: 'ep-player',
      provenance: TranscriptProvenance.localAi,
      subtitles: <Subtitle>[
        Subtitle(
          index: 1,
          start: Duration.zero,
          end: const Duration(seconds: 2),
          data: 'Player transcript line',
        ),
      ],
    );
    final episode = Episode(
      id: 3,
      guid: 'ep-player',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Player Episode',
      contentUrl: 'https://cdn.example.com/player.mp3',
      downloadPercentage: 100,
      transcriptId: 9,
    )..transcript = transcript;

    repository.episodesByGuid[episode.guid] = episode;
    repository.transcriptsById[9] = transcript;

    final audioService = _FakeAudioPlayerService(
      episode: episode,
      transcript: transcript,
    );
    final audioBloc = AudioBloc(audioPlayerService: audioService);
    final podcastService = _FakePodcastService(repository: repository);
    final queueBloc = QueueBloc(
      audioPlayerService: audioService,
      podcastService: podcastService,
    );
    final episodeBloc = EpisodeBloc(
      podcastService: podcastService,
      audioPlayerService: audioService,
      analysisService: _FakeEpisodeAnalysisService(),
      settingsService: _FakeSettingsService(),
      transcriptionService: _FakeEpisodeTranscriptionService(
        transcript: transcript,
      ),
      analysisPollInterval: Duration.zero,
    );

    addTearDown(() async {
      audioBloc.dispose();
      queueBloc.dispose();
      episodeBloc.dispose();
      audioService.dispose();
      await podcastService.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AnytimeLocalisationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
        ],
        home: MultiProvider(
          providers: [
            Provider<AudioBloc>.value(value: audioBloc),
            Provider<QueueBloc>.value(value: queueBloc),
            Provider<EpisodeBloc>.value(value: episodeBloc),
          ],
          child: const Scaffold(
            body: SizedBox(
              height: 640.0,
              child: NowPlayingOptionsSelectorWide(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI'), findsOneWidget);
    expect(find.text('TRANSCRIPT'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Regenerate AI Transcript'), findsOneWidget);
    expect(find.text('Analyze Ads'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}

Widget _wrapWithEpisodeBloc(EpisodeBloc bloc, Episode episode) {
  return MaterialApp(
    scaffoldMessengerKey: appScaffoldMessengerKey,
    home: Scaffold(
      body: Provider<EpisodeBloc>.value(
        value: bloc,
        child: EpisodeAnalysisPanel(episode: episode),
      ),
    ),
  );
}

class _FakeEpisodeAnalysisService implements EpisodeAnalysisService {
  final EpisodeAnalysisSubmitResponse submitResponse;
  final List<EpisodeAnalysisStatusResponse> pollResponses;
  int submitCount = 0;

  _FakeEpisodeAnalysisService({
    EpisodeAnalysisSubmitResponse? submitResponse,
    List<EpisodeAnalysisStatusResponse>? pollResponses,
  })  : submitResponse = submitResponse ??
            EpisodeAnalysisSubmitResponse(
              jobId: 'job-1',
              status: EpisodeAnalysisJobStatus.queued,
            ),
        pollResponses = pollResponses ??
            <EpisodeAnalysisStatusResponse>[
              EpisodeAnalysisStatusResponse(
                jobId: 'job-1',
                status: EpisodeAnalysisJobStatus.completed,
                adSegments: const <AdSegment>[],
              ),
            ];

  @override
  Future<EpisodeAnalysisStatusResponse> poll({required String jobId}) async {
    return pollResponses.removeAt(0);
  }

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    submitCount++;
    return submitResponse;
  }

  @override
  void close() {}
}

class _FakePodcastService implements PodcastService {
  @override
  final _FakeRepository repository;

  final StreamController<EpisodeState> _episodeController = StreamController<EpisodeState>.broadcast();

  _FakePodcastService({
    required this.repository,
  });

  @override
  Future<Episode> saveEpisode(Episode episode) async {
    final savedEpisode = await repository.saveEpisode(episode);
    _episodeController.add(EpisodeUpdateState(savedEpisode));
    return savedEpisode;
  }

  @override
  Future<Transcript> saveTranscript(Transcript transcript) {
    return repository.saveTranscript(transcript);
  }

  @override
  Stream<EpisodeState> get episodeListener => _episodeController.stream;

  @override
  Stream<Podcast?> get podcastListener => const Stream<Podcast?>.empty();

  @override
  Stream<LibraryState> get libraryListener => const Stream<LibraryState>.empty();

  @override
  Future<void> saveQueue(List<Episode> queue) async {}

  Future<void> dispose() => _episodeController.close();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements Repository {
  final Map<String, Episode> episodesByGuid = <String, Episode>{};
  final Map<int, Transcript> transcriptsById = <int, Transcript>{};
  final Map<String, List<EpisodeAnalysisRecord>> analysisHistoryByEpisodeId =
      <String, List<EpisodeAnalysisRecord>>{};
  final List<String> backgroundAnalysisQueue = <String>[];
  int _nextTranscriptId = 100;

  @override
  Future<Episode?> findEpisodeByGuid(String guid) async {
    return episodesByGuid[guid];
  }

  @override
  Future<Episode> saveEpisode(Episode episode, [bool updateIfSame = false]) async {
    episodesByGuid[episode.guid] = episode;
    return episode;
  }

  @override
  Future<Transcript?> findTranscriptById(int id) async {
    return transcriptsById[id];
  }

  @override
  Future<Transcript> saveTranscript(Transcript transcript) async {
    final transcriptId = transcript.id == null || transcript.id == 0 ? _nextTranscriptId++ : transcript.id!;
    transcript.id = transcriptId;
    transcriptsById[transcriptId] = transcript;
    return transcript;
  }

  @override
  Future<void> deleteTranscriptById(int id) async {
    transcriptsById.remove(id);
  }

  @override
  Future<List<EpisodeAnalysisRecord>> findAnalysisHistory(String episodeId) async {
    return List<EpisodeAnalysisRecord>.from(
      analysisHistoryByEpisodeId[episodeId] ?? const <EpisodeAnalysisRecord>[],
    );
  }

  @override
  Future<void> replaceAnalysisHistory(String episodeId, List<EpisodeAnalysisRecord> records) async {
    analysisHistoryByEpisodeId[episodeId] = List<EpisodeAnalysisRecord>.from(records);
    final episode = episodesByGuid[episodeId];
    if (episode != null) {
      episode.analysisHistory = List<EpisodeAnalysisRecord>.unmodifiable(records);
    }
  }

  @override
  Future<void> enqueueBackgroundAnalysis(String episodeId) async {
    if (!backgroundAnalysisQueue.contains(episodeId)) {
      backgroundAnalysisQueue.add(episodeId);
    }
  }

  @override
  Future<void> dequeueBackgroundAnalysis(String episodeId) async {
    backgroundAnalysisQueue.remove(episodeId);
  }

  @override
  Future<List<String>> listBackgroundAnalysisQueue() async {
    return List<String>.from(backgroundAnalysisQueue);
  }

  @override
  Stream<Podcast> get podcastListener => const Stream<Podcast>.empty();

  @override
  Stream<EpisodeState> get episodeListener => const Stream<EpisodeState>.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioPlayerService implements AudioPlayerService {
  final StreamController<AdSkipState> _adSkipController = StreamController<AdSkipState>.broadcast();
  late final BehaviorSubject<Episode?> _episodeController;
  late final BehaviorSubject<PositionState> _playPositionController;
  late final BehaviorSubject<QueueListState> _queueStateController;
  late final BehaviorSubject<TranscriptState> _transcriptController;

  int skipActiveAdCallCount = 0;

  _FakeAudioPlayerService({
    Episode? episode,
    Transcript? transcript,
    List<Episode> queue = const <Episode>[],
  }) {
    nowPlaying = episode;
    playingState = const Stream<AudioState>.empty();
    playbackError = const Stream<int>.empty();
    sleepStream = const Stream<Sleep>.empty();

    _episodeController = BehaviorSubject<Episode?>.seeded(episode);
    _playPositionController = BehaviorSubject<PositionState>.seeded(
      PositionState(
        position: Duration(milliseconds: episode?.position ?? 0),
        length: Duration(seconds: episode?.duration ?? 1),
        percentage: 0,
        episode: episode,
      ),
    );
    _queueStateController = BehaviorSubject<QueueListState>.seeded(
      QueueListState(
        playing: episode,
        queue: queue,
      ),
    );
    _transcriptController = BehaviorSubject<TranscriptState>.seeded(
      transcript == null ? TranscriptUnavailableState() : TranscriptUpdateState(transcript: transcript),
    );

    episodeEvent = _episodeController.stream;
    playPosition = _playPositionController.stream;
    queueState = _queueStateController.stream;
    transcriptEvent = _transcriptController.stream;
  }

  void emitAdSkipEvent(AdSkipState event) {
    _adSkipController.add(event);
  }

  void dispose() {
    _adSkipController.close();
    _episodeController.close();
    _playPositionController.close();
    _queueStateController.close();
    _transcriptController.close();
  }

  @override
  Future<void> skipActiveAd() async {
    skipActiveAdCallCount++;
  }

  @override
  Stream<AdSkipState>? get adSkipEvent => _adSkipController.stream;

  @override
  Episode? nowPlaying;

  @override
  Stream<AudioState>? playingState;

  @override
  ValueStream<PositionState>? playPosition;

  @override
  ValueStream<Episode?>? episodeEvent;

  @override
  Stream<TranscriptState>? transcriptEvent;

  @override
  Stream<int>? playbackError;

  @override
  Stream<QueueListState>? queueState;

  @override
  Stream<Sleep>? sleepStream;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEpisodeTranscriptionService implements EpisodeTranscriptionService {
  final Transcript transcript;
  int callCount = 0;

  _FakeEpisodeTranscriptionService({
    Transcript? transcript,
  }) : transcript = transcript ?? Transcript(subtitles: const <Subtitle>[]);

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    callCount++;
    onProgress?.call(const EpisodeTranscriptionProgress(
      stage: EpisodeTranscriptionStage.completed,
      message: 'Transcript ready.',
      progress: 1,
    ));
    return transcript;
  }
}

class _FakeSettingsService implements SettingsService {
  @override
  TranscriptUploadProvider get transcriptUploadProvider => TranscriptUploadProvider.analysisBackend;

  @override
  TranscriptionProvider get transcriptionProvider => TranscriptionProvider.localAi;

  @override
  AdSkipMode get adSkipMode => AdSkipMode.prompt;

  @override
  String get geminiAnalysisModel => 'gemini-test-model';

  @override
  bool get showAnalysisHistory => false;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
