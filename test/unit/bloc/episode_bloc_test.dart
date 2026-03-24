// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/sleep.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/library_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/state/ad_skip_state.dart';
import 'package:anytime/state/transcript_state_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  group('EpisodeBloc analyzeAds', () {
    test('submits, polls, persists analysis data, and keeps the generated AI transcript association', () async {
      final repository = _FakeRepository();
      final oldTranscript = Transcript(
        id: 3,
        guid: 'ep-1',
        provenance: TranscriptProvenance.localAi,
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 1),
            data: 'Old transcript',
          ),
        ],
      );

      repository.transcriptsById[3] = oldTranscript;

      final episode = Episode(
        id: 1,
        guid: 'ep-1',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode 1',
        contentUrl: 'https://cdn.example.com/episode.mp3',
        transcriptId: 3,
      );

      repository.episodesByGuid[episode.guid] = episode;

      final analysisService = _FakeEpisodeAnalysisService(
        submitResponse: EpisodeAnalysisSubmitResponse(
          jobId: 'job-1',
          status: EpisodeAnalysisJobStatus.queued,
        ),
        pollResponses: <EpisodeAnalysisStatusResponse>[
          EpisodeAnalysisStatusResponse(
            jobId: 'job-1',
            status: EpisodeAnalysisJobStatus.processing,
          ),
          EpisodeAnalysisStatusResponse(
            jobId: 'job-1',
            status: EpisodeAnalysisJobStatus.completed,
            transcript: EpisodeAnalysisTranscriptDto(
              format: 'srt',
              content: '1\n00:00:00,000 --> 00:00:01,000\nHello world',
            ),
            adSegments: const <AdSegment>[
              AdSegment(
                startMs: 1000,
                endMs: 5000,
                reason: 'preroll',
                confidence: 0.9,
                flags: <String>['music'],
              ),
            ],
          ),
        ],
      );

      final podcastService = _FakePodcastService(repository: repository);
      final bloc = EpisodeBloc(
        podcastService: podcastService,
        audioPlayerService: _FakeAudioPlayerService(),
        analysisService: analysisService,
        settingsService: _FakeSettingsService(),
        transcriptionService: _FakeEpisodeTranscriptionService(),
        analysisPollInterval: Duration.zero,
      );

      final updatedEpisode = await bloc.analyzeAds(episode, consentToUpload: true);

      expect(analysisService.submitCount, 1);
      expect(analysisService.pollCount, 2);
      expect(updatedEpisode.analysisStatus, 'completed');
      expect(updatedEpisode.analysisJobId, 'job-1');
      expect(updatedEpisode.analysisError, isNull);
      expect(updatedEpisode.adSegments, hasLength(1));
      expect(updatedEpisode.transcriptId, 3);
      expect(repository.deletedTranscriptIds, isEmpty);
      expect(repository.transcriptsById[updatedEpisode.transcriptId]!.subtitles.single.data, 'Old transcript');
      expect(
        podcastService.savedEpisodeStatuses,
        <String?>['queued', 'processing', 'completed'],
      );

      bloc.dispose();
    });

    test('rejects feed transcripts for analysis upload', () async {
      final repository = _FakeRepository();
      final feedTranscript = Transcript(
        id: 55,
        guid: 'ep-2',
        provenance: TranscriptProvenance.feed,
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 1),
            data: 'Feed line',
          ),
        ],
      );
      final episode = Episode(
        id: 2,
        guid: 'ep-2',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode 2',
        contentUrl: 'https://cdn.example.com/episode-2.mp3',
        transcriptId: 55,
      );

      repository.transcriptsById[55] = feedTranscript;
      repository.episodesByGuid[episode.guid] = episode;
      final podcastService = _FakePodcastService(repository: repository);

      final analysisService = _FakeEpisodeAnalysisService(
        submitResponse: EpisodeAnalysisSubmitResponse(
          jobId: 'job-2',
          status: EpisodeAnalysisJobStatus.queued,
        ),
        pollResponses: <EpisodeAnalysisStatusResponse>[
          EpisodeAnalysisStatusResponse(
            jobId: 'job-2',
            status: EpisodeAnalysisJobStatus.completed,
            transcript: EpisodeAnalysisTranscriptDto(
              format: 'srt',
              content: '1\n00:00:00,000 --> 00:00:01,000\nBackend line',
            ),
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

      await expectLater(
        () => bloc.analyzeAds(episode, consentToUpload: true),
        throwsA(
          isA<EpisodeAnalysisFailedException>().having(
            (error) => error.message,
            'message',
            'Generate an AI transcript before analyzing ads.',
          ),
        ),
      );

      expect(analysisService.lastSubmitTranscript, isNull);

      bloc.dispose();
    });

    test('generates and persists a local AI transcript for a downloaded episode', () async {
      final repository = _FakeRepository();
      final episode = Episode(
        id: 3,
        guid: 'ep-3',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode 3',
        contentUrl: 'https://cdn.example.com/episode-3.mp3',
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

      final bloc = EpisodeBloc(
        podcastService: _FakePodcastService(repository: repository),
        audioPlayerService: _FakeAudioPlayerService(),
        analysisService: _FakeEpisodeAnalysisService(
          submitResponse: EpisodeAnalysisSubmitResponse(jobId: 'unused'),
          pollResponses: <EpisodeAnalysisStatusResponse>[],
        ),
        settingsService: _FakeSettingsService(),
        transcriptionService: transcriptionService,
        analysisPollInterval: Duration.zero,
      );

      final updatedEpisode = await bloc.generateLocalTranscript(episode);

      expect(updatedEpisode.transcriptId, isNotNull);
      expect(updatedEpisode.transcript?.provenance, TranscriptProvenance.localAi);
      expect(updatedEpisode.transcript?.provider, 'whisper');
      expect(repository.transcriptsById[updatedEpisode.transcriptId]!.subtitles.single.data, 'Local AI line');

      bloc.dispose();
    });

    test('accepts an OpenAI-generated transcript for ad analysis', () async {
      final repository = _FakeRepository();
      final openAiTranscript = Transcript(
        id: 77,
        guid: 'ep-openai',
        provenance: TranscriptProvenance.openAi,
        provider: 'whisper-1',
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 2),
            data: 'OpenAI transcript line',
          ),
        ],
      );
      final episode = Episode(
        id: 5,
        guid: 'ep-openai',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode OpenAI',
        contentUrl: 'https://cdn.example.com/openai.mp3',
        transcriptId: 77,
      );

      repository.transcriptsById[77] = openAiTranscript;
      repository.episodesByGuid[episode.guid] = episode..transcript = openAiTranscript;

      final analysisService = _FakeEpisodeAnalysisService(
        submitResponse: EpisodeAnalysisSubmitResponse(
          jobId: 'job-openai',
          status: EpisodeAnalysisJobStatus.queued,
        ),
        pollResponses: <EpisodeAnalysisStatusResponse>[
          EpisodeAnalysisStatusResponse(
            jobId: 'job-openai',
            status: EpisodeAnalysisJobStatus.completed,
            adSegments: const <AdSegment>[
              AdSegment(startMs: 1000, endMs: 3000),
            ],
          ),
        ],
      );

      final bloc = EpisodeBloc(
        podcastService: _FakePodcastService(repository: repository),
        audioPlayerService: _FakeAudioPlayerService(),
        analysisService: analysisService,
        settingsService: _FakeSettingsService(),
        transcriptionService: _FakeEpisodeTranscriptionService(),
        analysisPollInterval: Duration.zero,
      );

      final updatedEpisode = await bloc.analyzeAds(episode, consentToUpload: true);

      expect(analysisService.lastSubmitTranscript, isNotNull);
      expect(analysisService.lastSubmitTranscript!.provenance, 'openAi');
      expect(updatedEpisode.adSegments, hasLength(1));

      bloc.dispose();
    });

    test('replacing an existing local transcript deletes the old transcript and clears analysis data', () async {
      final repository = _FakeRepository();
      final oldTranscript = Transcript(
        id: 88,
        guid: 'ep-4',
        provenance: TranscriptProvenance.localAi,
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 1),
            data: 'Old local transcript',
          ),
        ],
      );

      final episode = Episode(
        id: 4,
        guid: 'ep-4',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode 4',
        contentUrl: 'https://cdn.example.com/episode-4.mp3',
        downloadPercentage: 100,
        transcriptId: 88,
        analysisStatus: 'completed',
        analysisJobId: 'job-previous',
        analysisError: 'stale',
        analysisUpdatedAt: DateTime(2026, 3, 22),
        adSegments: const <AdSegment>[
          AdSegment(startMs: 1000, endMs: 5000),
        ],
      );

      repository.transcriptsById[88] = oldTranscript;
      repository.episodesByGuid[episode.guid] = episode;

      final bloc = EpisodeBloc(
        podcastService: _FakePodcastService(repository: repository),
        audioPlayerService: _FakeAudioPlayerService(),
        analysisService: _FakeEpisodeAnalysisService(
          submitResponse: EpisodeAnalysisSubmitResponse(jobId: 'unused'),
          pollResponses: <EpisodeAnalysisStatusResponse>[],
        ),
        settingsService: _FakeSettingsService(),
        transcriptionService: _FakeEpisodeTranscriptionService(
          transcript: Transcript(
            subtitles: <Subtitle>[
              Subtitle(
                index: 1,
                start: Duration.zero,
                end: const Duration(seconds: 2),
                data: 'New local transcript',
              ),
            ],
          ),
        ),
        analysisPollInterval: Duration.zero,
      );

      final updatedEpisode = await bloc.generateLocalTranscript(episode);

      expect(updatedEpisode.transcriptId, isNot(88));
      expect(updatedEpisode.transcript?.guid, 'ep-4');
      expect(updatedEpisode.analysisStatus, isNull);
      expect(updatedEpisode.analysisJobId, isNull);
      expect(updatedEpisode.analysisError, isNull);
      expect(updatedEpisode.analysisUpdatedAt, isNull);
      expect(updatedEpisode.adSegments, isEmpty);
      expect(repository.deletedTranscriptIds, <int>[88]);
      expect(repository.transcriptsById.containsKey(88), isFalse);
      expect(repository.transcriptsById[updatedEpisode.transcriptId]!.subtitles.single.data, 'New local transcript');

      bloc.dispose();
    });
  });
}

class _FakeEpisodeAnalysisService implements EpisodeAnalysisService {
  final EpisodeAnalysisSubmitResponse submitResponse;
  final List<EpisodeAnalysisStatusResponse> pollResponses;
  int submitCount = 0;
  int pollCount = 0;
  EpisodeAnalysisTranscriptPayload? lastSubmitTranscript;

  _FakeEpisodeAnalysisService({
    required this.submitResponse,
    required this.pollResponses,
  });

  @override
  Future<EpisodeAnalysisStatusResponse> poll({required String jobId}) async {
    pollCount++;
    return pollResponses.removeAt(0);
  }

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    submitCount++;
    lastSubmitTranscript = transcript;
    return submitResponse;
  }

  @override
  void close() {}
}

class _FakePodcastService implements PodcastService {
  @override
  final _FakeRepository repository;

  final _episodeController = StreamController<EpisodeState>.broadcast();
  int loadTranscriptCallCount = 0;
  final List<String?> savedEpisodeStatuses = <String?>[];

  _FakePodcastService({
    required this.repository,
  });

  @override
  Future<Episode> saveEpisode(Episode episode) async {
    final savedEpisode = await repository.saveEpisode(episode);
    savedEpisodeStatuses.add(savedEpisode.analysisStatus);
    _episodeController.add(EpisodeUpdateState(savedEpisode));
    return savedEpisode;
  }

  @override
  Future<Transcript> saveTranscript(Transcript transcript) {
    return repository.saveTranscript(transcript);
  }

  @override
  Future<Transcript> loadTranscriptByUrl({required TranscriptUrl transcriptUrl}) async {
    loadTranscriptCallCount++;
    return Transcript(subtitles: const <Subtitle>[]);
  }

  @override
  Stream<EpisodeState> get episodeListener => _episodeController.stream;

  @override
  Stream<Podcast?> get podcastListener => const Stream<Podcast?>.empty();

  @override
  Stream<LibraryState> get libraryListener => const Stream<LibraryState>.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements Repository {
  final Map<String, Episode> episodesByGuid = <String, Episode>{};
  final Map<int, Transcript> transcriptsById = <int, Transcript>{};
  final List<int> deletedTranscriptIds = <int>[];
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
    final transcriptId = transcript.id ?? _nextTranscriptId++;
    transcript.id = transcriptId;
    transcriptsById[transcriptId] = transcript;
    return transcript;
  }

  @override
  Future<void> deleteTranscriptById(int id) async {
    deletedTranscriptIds.add(id);
    transcriptsById.remove(id);
  }

  @override
  Stream<Podcast> get podcastListener => const Stream<Podcast>.empty();

  @override
  Stream<EpisodeState> get episodeListener => const Stream<EpisodeState>.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioPlayerService implements AudioPlayerService {
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
  Stream<AdSkipState>? adSkipEvent;

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

  _FakeEpisodeTranscriptionService({
    Transcript? transcript,
  }) : transcript = transcript ?? Transcript(subtitles: const <Subtitle>[]);

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
