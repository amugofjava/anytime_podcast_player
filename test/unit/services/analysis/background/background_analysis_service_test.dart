// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/analysis/background/background_analysis_progress.dart';
import 'package:anytime/services/analysis/background/background_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../mocks/mock_path_provider.dart';

void main() {
  const dbName = 'anytime-bg-service-test.db';
  SembastRepository? repository;
  DefaultBackgroundAnalysisService? service;

  setUp(() async {
    PathProviderPlatform.instance = MockPathProvder();
    repository = SembastRepository(cleanup: false, databaseName: dbName);
    service = DefaultBackgroundAnalysisService(repository!);
  });

  tearDown(() async {
    await service!.dispose();
    await repository!.close();
    service = null;
    repository = null;

    final f = File('${Directory.systemTemp.path}/$dbName');
    if (f.existsSync()) {
      f.deleteSync();
    }
  });

  group('queue delegation', () {
    test('enqueue forwards to the repository', () async {
      await service!.enqueue('EP-1');

      expect(await service!.listQueued(), ['EP-1']);
      expect(await repository!.listBackgroundAnalysisQueue(), ['EP-1']);
    });

    test('dequeue forwards to the repository', () async {
      await service!.enqueue('EP-2');
      await service!.dequeue('EP-2');

      expect(await service!.listQueued(), isEmpty);
    });
  });

  group('progress stream', () {
    test('enqueue publishes a queued progress event', () async {
      final stream = service!.progress();
      final first = stream.first;

      await service!.enqueue('EP-3');

      final update = await first.timeout(const Duration(seconds: 1));
      expect(update.episodeId, 'EP-3');
      expect(update.stage, BackgroundAnalysisStage.queued);
    });

    test('reportProgress publishes to subscribers', () async {
      final received = <BackgroundAnalysisProgress>[];
      final sub = service!.progress().listen(received.add);

      service!.reportProgress(const BackgroundAnalysisProgress(
        episodeId: 'EP-4',
        stage: BackgroundAnalysisStage.transcribing,
        fraction: 0.5,
      ));
      service!.reportProgress(const BackgroundAnalysisProgress(
        episodeId: 'EP-4',
        stage: BackgroundAnalysisStage.completed,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0].stage, BackgroundAnalysisStage.transcribing);
      expect(received[0].fraction, 0.5);
      expect(received[1].stage, BackgroundAnalysisStage.completed);

      await sub.cancel();
    });

    test('progress is broadcast (supports multiple listeners)', () async {
      final a = <BackgroundAnalysisProgress>[];
      final b = <BackgroundAnalysisProgress>[];
      final subA = service!.progress().listen(a.add);
      final subB = service!.progress().listen(b.add);

      service!.reportProgress(const BackgroundAnalysisProgress(
        episodeId: 'EP-5',
        stage: BackgroundAnalysisStage.analyzing,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(a, hasLength(1));
      expect(b, hasLength(1));

      await subA.cancel();
      await subB.cancel();
    });
  });

  group('commitResult', () {
    test('first record becomes active and updates episode.adSegments', () async {
      final episode = Episode(
        guid: 'EP-C1',
        pguid: 'POD',
        podcast: 'Podcast',
        title: 'Commit result',
      );
      await repository!.saveEpisode(episode);

      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 100,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 30_000, reason: 'preroll'),
        ],
        active: false,
      );

      final committed = await service!.commitResult(episodeId: 'EP-C1', record: record);

      expect(committed.active, isTrue);
      expect(committed.provider, AnalysisProvider.whisperGemma4);

      final loaded = await repository!.findEpisodeByGuid('EP-C1');
      expect(loaded!.adSegments, hasLength(1));
      expect(loaded.adSegments.single.reason, 'preroll');
      expect(loaded.analysisHistory, hasLength(1));
      expect(loaded.analysisHistory.single.active, isTrue);
    });

    test('supersession: whisper+gemma4 over gemini demotes gemini and syncs adSegments', () async {
      final episode = Episode(
        guid: 'EP-C2',
        pguid: 'POD',
        podcast: 'Podcast',
        title: 'Supersession',
      );
      await repository!.saveEpisode(episode);

      final gemini = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1',
        completedAtMs: 100,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 20_000, reason: 'gemini'),
        ],
        active: false,
      );
      await service!.commitResult(episodeId: 'EP-C2', record: gemini);

      final whisper = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 200,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 5_000, endMs: 45_000, reason: 'whisper'),
        ],
        active: false,
      );
      final committed = await service!.commitResult(episodeId: 'EP-C2', record: whisper);

      expect(committed.active, isTrue);
      expect(committed.provider, AnalysisProvider.whisperGemma4);

      final loaded = await repository!.findEpisodeByGuid('EP-C2');
      expect(loaded!.analysisHistory, hasLength(2));
      expect(loaded.analysisHistory[0].provider, AnalysisProvider.geminiAudio);
      expect(loaded.analysisHistory[0].active, isFalse, reason: 'gemini demoted');
      expect(loaded.analysisHistory[1].provider, AnalysisProvider.whisperGemma4);
      expect(loaded.analysisHistory[1].active, isTrue);
      expect(loaded.adSegments.single.reason, 'whisper');
    });

    test('new gemini-audio does NOT supersede active whisper+gemma4', () async {
      final episode = Episode(
        guid: 'EP-C3',
        pguid: 'POD',
        podcast: 'Podcast',
        title: 'No supersession',
      );
      await repository!.saveEpisode(episode);

      final whisper = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 100,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 40_000, reason: 'whisper'),
        ],
        active: false,
      );
      await service!.commitResult(episodeId: 'EP-C3', record: whisper);

      final gemini = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1',
        completedAtMs: 200,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 30_000, reason: 'gemini'),
        ],
        active: false,
      );
      final committed = await service!.commitResult(episodeId: 'EP-C3', record: gemini);

      expect(committed.active, isFalse, reason: 'gemini arriving after whisper stays inactive');

      final loaded = await repository!.findEpisodeByGuid('EP-C3');
      expect(loaded!.analysisHistory, hasLength(2));
      expect(loaded.analysisHistory[0].active, isTrue, reason: 'whisper retained as active');
      expect(loaded.analysisHistory[1].active, isFalse);
      expect(loaded.adSegments.single.reason, 'whisper', reason: 'episode.adSegments still reflects whisper');
    });

    test('commit works even if no Episode row exists (history-only path)', () async {
      // Should not throw — episode update is a soft sync.
      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini',
        completedAtMs: 1,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 10_000),
        ],
        active: false,
      );

      final committed = await service!.commitResult(episodeId: 'EP-MISSING', record: record);

      expect(committed.active, isTrue);
      expect(await repository!.findAnalysisHistory('EP-MISSING'), hasLength(1));
    });
  });
}
