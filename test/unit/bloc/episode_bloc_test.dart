// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/sleep.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/library_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/state/transcript_state_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  group('EpisodeBloc analyzeAds', () {
    test('submits, polls, persists analysis data, and replaces stored transcript association', () async {
      final repository = _FakeRepository();
      final oldTranscript = Transcript(
        id: 3,
        guid: 'ep-1',
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: Duration(seconds: 1),
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
        analysisPollInterval: Duration.zero,
      );

      final updatedEpisode = await bloc.analyzeAds(episode);

      expect(analysisService.submitCount, 1);
      expect(analysisService.pollCount, 2);
      expect(updatedEpisode.analysisStatus, 'completed');
      expect(updatedEpisode.analysisJobId, 'job-1');
      expect(updatedEpisode.analysisError, isNull);
      expect(updatedEpisode.adSegments, hasLength(1));
      expect(updatedEpisode.transcriptId, isNot(3));
      expect(updatedEpisode.transcriptId, isNotNull);
      expect(repository.deletedTranscriptIds, <int>[3]);
      expect(repository.transcriptsById[updatedEpisode.transcriptId]!.guid, 'ep-1');
      expect(repository.transcriptsById[updatedEpisode.transcriptId]!.subtitles.single.data, 'Hello world');
      expect(
        podcastService.savedEpisodeStatuses,
        <String?>['queued', 'processing', 'completed'],
      );

      bloc.dispose();
    });

    test('uses feed transcript for submit payload when available', () async {
      final repository = _FakeRepository();
      final episode = Episode(
        id: 2,
        guid: 'ep-2',
        pguid: 'pod-1',
        podcast: 'Podcast',
        title: 'Episode 2',
        contentUrl: 'https://cdn.example.com/episode-2.mp3',
        transcriptUrls: <TranscriptUrl>[
          TranscriptUrl(
            url: 'https://cdn.example.com/episode-2.srt',
            type: TranscriptFormat.subrip,
          ),
        ],
      );

      repository.episodesByGuid[episode.guid] = episode;

      final podcastService = _FakePodcastService(
        repository: repository,
        transcriptToLoad: Transcript(
          subtitles: <Subtitle>[
            Subtitle(
              index: 1,
              start: Duration.zero,
              end: Duration(seconds: 1),
              data: 'Feed line',
            ),
          ],
        ),
      );

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
        analysisPollInterval: Duration.zero,
      );

      await bloc.analyzeAds(episode);

      expect(podcastService.loadTranscriptCallCount, 1);
      expect(analysisService.lastSubmitTranscript, isNotNull);
      expect(analysisService.lastSubmitTranscript!.format, 'srt');
      expect(analysisService.lastSubmitTranscript!.content, contains('Feed line'));

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
  final Transcript? transcriptToLoad;
  int loadTranscriptCallCount = 0;
  final List<String?> savedEpisodeStatuses = <String?>[];

  _FakePodcastService({
    required this.repository,
    this.transcriptToLoad,
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
    return transcriptToLoad!;
  }

  @override
  Stream<EpisodeState> get episodeListener => _episodeController.stream;

  @override
  Stream<Podcast?> get podcastListener => Stream<Podcast?>.empty();

  @override
  Stream<LibraryState> get libraryListener => Stream<LibraryState>.empty();

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
  Stream<Podcast> get podcastListener => Stream<Podcast>.empty();

  @override
  Stream<EpisodeState> get episodeListener => Stream<EpisodeState>.empty();

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
  Stream<int>? playbackError;

  @override
  Stream<QueueListState>? queueState;

  @override
  Stream<Sleep>? sleepStream;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
