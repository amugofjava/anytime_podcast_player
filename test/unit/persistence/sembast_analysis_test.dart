// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/episode_analysis_record.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../mocks/mock_path_provider.dart';

void main() {
  const dbName = 'anytime-analysis-test.db';
  SembastRepository? repository;

  setUp(() async {
    PathProviderPlatform.instance = MockPathProvder();
    repository = SembastRepository(cleanup: false, databaseName: dbName);
  });

  tearDown(() async {
    await repository!.close();
    repository = null;

    final f = File('${Directory.systemTemp.path}/$dbName');
    if (f.existsSync()) {
      f.deleteSync();
    }
  });

  group('Analysis history store', () {
    test('saveAnalysisRecord then findAnalysisHistory returns record', () async {
      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1-flash-lite-preview',
        completedAtMs: 1_714_000_000_000,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 5_000, endMs: 45_000, reason: 'preroll'),
        ],
        active: true,
      );

      await repository!.saveAnalysisRecord('EP-1', record);

      final history = await repository!.findAnalysisHistory('EP-1');
      expect(history, [record]);
    });

    test('saveAnalysisRecord appends multiple records in order', () async {
      final first = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1-flash-lite-preview',
        completedAtMs: 100,
        adSegments: const <AdSegment>[],
        active: true,
      );
      final second = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 200,
        adSegments: const <AdSegment>[],
        active: true,
      );

      await repository!.saveAnalysisRecord('EP-2', first);
      await repository!.saveAnalysisRecord('EP-2', second);

      final history = await repository!.findAnalysisHistory('EP-2');
      expect(history, [first, second]);
    });

    test('findAnalysisHistory returns empty list when no records', () async {
      final history = await repository!.findAnalysisHistory('missing');
      expect(history, isEmpty);
    });

    test('deleteAnalysisHistory removes all records for an episode', () async {
      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1-flash-lite-preview',
        completedAtMs: 1,
        adSegments: const <AdSegment>[],
        active: true,
      );

      await repository!.saveAnalysisRecord('EP-3', record);
      await repository!.deleteAnalysisHistory('EP-3');

      final history = await repository!.findAnalysisHistory('EP-3');
      expect(history, isEmpty);
    });
  });

  group('Background analysis queue', () {
    test('enqueue then list returns episode id', () async {
      await repository!.enqueueBackgroundAnalysis('EP-Q1');

      final queued = await repository!.listBackgroundAnalysisQueue();
      expect(queued, ['EP-Q1']);
    });

    test('enqueue is idempotent per episode', () async {
      await repository!.enqueueBackgroundAnalysis('EP-Q2');
      await repository!.enqueueBackgroundAnalysis('EP-Q2');

      final queued = await repository!.listBackgroundAnalysisQueue();
      expect(queued, ['EP-Q2']);
    });

    test('dequeue removes the episode', () async {
      await repository!.enqueueBackgroundAnalysis('EP-Q3');
      await repository!.dequeueBackgroundAnalysis('EP-Q3');

      final queued = await repository!.listBackgroundAnalysisQueue();
      expect(queued, isEmpty);
    });

    test('dequeue on missing episode is a no-op', () async {
      await repository!.dequeueBackgroundAnalysis('never-queued');

      final queued = await repository!.listBackgroundAnalysisQueue();
      expect(queued, isEmpty);
    });

    test('listBackgroundAnalysisQueue is ordered by enqueue time', () async {
      await repository!.enqueueBackgroundAnalysis('EP-A');
      // Ensure enqueue timestamps differ by at least a millisecond.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository!.enqueueBackgroundAnalysis('EP-B');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository!.enqueueBackgroundAnalysis('EP-C');

      final queued = await repository!.listBackgroundAnalysisQueue();
      expect(queued, ['EP-A', 'EP-B', 'EP-C']);
    });
  });

  group('Background analysis checkpoint', () {
    test('findBackgroundAnalysisCheckpoint returns null when absent', () async {
      expect(await repository!.findBackgroundAnalysisCheckpoint('missing'), isNull);
    });

    test('record + find round-trips the stage token', () async {
      await repository!.recordBackgroundAnalysisCheckpoint('EP-CP1', 'transcribe');
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-CP1'), 'transcribe');
    });

    test('recording again overwrites the prior stage', () async {
      await repository!.recordBackgroundAnalysisCheckpoint('EP-CP2', 'transcribe');
      await repository!.recordBackgroundAnalysisCheckpoint('EP-CP2', 'analyze');
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-CP2'), 'analyze');
    });

    test('clear removes the checkpoint', () async {
      await repository!.recordBackgroundAnalysisCheckpoint('EP-CP3', 'transcribe');
      await repository!.clearBackgroundAnalysisCheckpoint('EP-CP3');
      expect(await repository!.findBackgroundAnalysisCheckpoint('EP-CP3'), isNull);
    });

    test('clear on absent checkpoint is a no-op', () async {
      await repository!.clearBackgroundAnalysisCheckpoint('never-set');
      expect(await repository!.findBackgroundAnalysisCheckpoint('never-set'), isNull);
    });
  });

  group('Legacy-unknown migration', () {
    test('backfills history for episodes with adSegments', () async {
      final episode = Episode(
        guid: 'EP-LEGACY-1',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'Legacy with ads',
        analysisUpdatedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
        adSegments: const <AdSegment>[
          AdSegment(startMs: 10_000, endMs: 40_000, reason: 'midroll', confidence: 0.9),
        ],
      );
      await repository!.saveEpisode(episode);

      await repository!.runAnalysisHistoryBackfill();

      final history = await repository!.findAnalysisHistory('EP-LEGACY-1');
      expect(history, hasLength(1));
      expect(history[0].provider, AnalysisProvider.legacyUnknown);
      expect(history[0].active, isTrue);
      expect(history[0].modelId, '');
      expect(history[0].completedAtMs, 1_700_000_000_000);
      expect(history[0].adSegments, episode.adSegments);
    });

    test('skips episodes without adSegments', () async {
      final episode = Episode(
        guid: 'EP-LEGACY-2',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'Legacy without ads',
      );
      await repository!.saveEpisode(episode);

      await repository!.runAnalysisHistoryBackfill();

      final history = await repository!.findAnalysisHistory('EP-LEGACY-2');
      expect(history, isEmpty);
    });

    test('is idempotent - running twice does not duplicate records', () async {
      final episode = Episode(
        guid: 'EP-LEGACY-3',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'Legacy idempotency',
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 10_000),
        ],
      );
      await repository!.saveEpisode(episode);

      await repository!.runAnalysisHistoryBackfill();
      await repository!.runAnalysisHistoryBackfill();

      final history = await repository!.findAnalysisHistory('EP-LEGACY-3');
      expect(history, hasLength(1));
    });

    test('does not overwrite existing history for an episode', () async {
      final episode = Episode(
        guid: 'EP-LEGACY-4',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'Legacy with prior history',
        adSegments: const <AdSegment>[
          AdSegment(startMs: 0, endMs: 10_000, reason: 'legacy-segment'),
        ],
      );
      await repository!.saveEpisode(episode);

      final preExisting = EpisodeAnalysisRecord(
        provider: AnalysisProvider.geminiAudio,
        modelId: 'gemini-3.1-flash-lite-preview',
        completedAtMs: 999,
        adSegments: const <AdSegment>[],
        active: true,
      );
      await repository!.saveAnalysisRecord('EP-LEGACY-4', preExisting);

      await repository!.runAnalysisHistoryBackfill();

      final history = await repository!.findAnalysisHistory('EP-LEGACY-4');
      expect(history, [preExisting]);
    });
  });

  group('Episode round-trip with history', () {
    test('saveEpisode / findEpisodeByGuid populates analysisHistory from store', () async {
      final episode = Episode(
        guid: 'EP-HIST-1',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'With history',
      );
      await repository!.saveEpisode(episode);

      final record = EpisodeAnalysisRecord(
        provider: AnalysisProvider.whisperGemma4,
        modelId: 'gemma-4-e2b',
        completedAtMs: 123,
        adSegments: const <AdSegment>[
          AdSegment(startMs: 1000, endMs: 5000),
        ],
        active: true,
      );
      await repository!.saveAnalysisRecord('EP-HIST-1', record);

      final loaded = await repository!.findEpisodeByGuid('EP-HIST-1');
      expect(loaded, isNotNull);
      expect(loaded!.analysisHistory, [record]);
    });
  });
}
