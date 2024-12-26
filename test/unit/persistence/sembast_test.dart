// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../mocks/mock_path_provider.dart';

void main() {
  MockPathProvder mockPath;
  Repository? persistenceService;

  late Podcast podcast1;
  late Podcast podcast2;
  late Podcast podcast3;

  setUp(() async {
    mockPath = MockPathProvder();
    PathProviderPlatform.instance = mockPath;
    persistenceService = SembastRepository(cleanup: false);

    podcast1 = Podcast(
        title: 'Podcast 1',
        description: '1st podcast',
        guid: 'http://p1.com',
        link: 'http://p1.com',
        url: 'http://p1.com');

    podcast2 = Podcast(
        title: 'Podcast 2',
        description: '2nd podcast',
        guid: 'http://p2.com',
        link: 'http://p2.com',
        url: 'http://p2.com');

    podcast3 = Podcast(
        title: 'Podcast 3',
        description: '3rd podcast',
        guid: 'http://p3.com',
        link: 'http://p3.com',
        url: 'http://p3.com');
  });

  tearDown(() async {
    // Sembast will cache data so simply deleting the file and clearing the
    // object reference will not do. Close the database and delete the db file.
    await persistenceService!.close();

    persistenceService = null;

    final f = File('${Directory.systemTemp.path}/anytime.db');

    if (f.existsSync()) {
      f.deleteSync();
    }
  });

  test('Fetch podcast with non-existent ID', () async {
    final result = await persistenceService!.findPodcastById(123);

    expect(result, null);
  });

  /// Test the creation and retrieval of podcasts both with and without
  /// episodes. Ensure that data fetched is equal to the data originally
  /// stored.
  group('Podcast creation and retrieval', () {
    test('Create and save a single Podcast without episodes', () async {
      await persistenceService!.savePodcast(podcast1);

      expect(true, podcast1.id! > 0);
    }, skip: false);

    test('Create and save a single Podcast with episodes', () async {
      podcast2.episodes = <Episode>[
        Episode(guid: 'EP001', title: 'Episode 1', pguid: podcast2.guid, podcast: podcast2.title),
        Episode(guid: 'EP002', title: 'Episode 2', pguid: podcast2.guid, podcast: podcast2.title),
        Episode(guid: 'EP003', title: 'Episode 3', pguid: podcast2.guid, podcast: podcast2.title),
      ];

      podcast2 = await persistenceService!.savePodcast(podcast2);

      final result = (podcast2.id ?? 0) > 0;

      expect(result, true);
      expect(podcast2.episodes.isNotEmpty, true);
    });

    test('Create and save a single Podcast & attach episodes later', () async {
      podcast3 = await persistenceService!.savePodcast(podcast3);
      final result = (podcast3.id ?? 0) > 0;
      final previousId = podcast3.id;

      expect(result, true);
      expect(podcast3.episodes.isEmpty, true);

      podcast3.episodes = <Episode>[
        Episode(guid: 'EP001', title: 'Episode 1', pguid: podcast3.guid, podcast: podcast3.title),
        Episode(guid: 'EP002', title: 'Episode 2', pguid: podcast3.guid, podcast: podcast3.title),
        Episode(guid: 'EP003', title: 'Episode 3', pguid: podcast3.guid, podcast: podcast3.title),
      ];

      await persistenceService!.savePodcast(podcast3);

      expect(podcast3.id ?? 0, previousId);
      expect(podcast3.episodes.isNotEmpty, true);
    });

    test('Retrieve an existing Podcast without episodes', () async {
      final podcast1 = Podcast(
          title: 'Podcast 1B',
          description: '1st podcast',
          guid: 'http://p1.com',
          link: 'http://p1.com',
          url: 'http://p1.com');

      await persistenceService!.savePodcast(podcast1);

      expect(podcast1.id! > 0, true);

      final podcast = await persistenceService!.findPodcastById(podcast1.id!);

      expect(podcast == podcast1, true);
    });

    test('Retrieve an existing Podcast with episodes', () async {
      final podcast3 = Podcast(
          title: 'Podcast 3',
          description: '3rd podcast',
          guid: 'http://p3.com',
          link: 'http://p3.com',
          url: 'http://p3.com');

      podcast3.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast3.guid,
            podcast: podcast3.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast3.guid,
            podcast: podcast3.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast3.guid,
            podcast: podcast3.title,
            publicationDate: DateTime.now()),
      ];

      await persistenceService!.savePodcast(podcast3);

      final podcast = (await persistenceService!.findPodcastById(podcast3.id!))!;

      expect(podcast == podcast3, true);

      expect(listEquals(podcast.episodes, podcast3.episodes), true);

      // Retrieve same Podcast via GUID and test it is still the same.
      final podcastByGuid = await persistenceService!.findPodcastByGuid(podcast3.guid!);

      expect(podcastByGuid == podcast3, true);
      expect(listEquals(podcast.episodes, podcast3.episodes), true);
    });

    test('Retrieve an existing Podcast with episodes and update episodes', () async {
      final podcast4 = Podcast(
          title: 'Podcast 3',
          description: '3rd podcast',
          guid: 'http://p3.com',
          link: 'http://p3.com',
          url: 'http://p3.com');

      podcast4.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast4.guid,
            podcast: podcast4.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast4.guid,
            podcast: podcast4.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast4.guid,
            podcast: podcast4.title,
            publicationDate: DateTime.now()),
      ];

      await persistenceService!.savePodcast(podcast4);

      var podcast = (await persistenceService!.findPodcastById(podcast4.id!))!;

      expect(podcast == podcast4, true);
      expect(listEquals(podcast.episodes, podcast4.episodes), true);

      // Update episodes and save batch
      expect(true, podcast.episodes.length == 3);

      // Mark all as played
      podcast.episodes[0].played = true;
      podcast.episodes[1].played = true;
      podcast.episodes[2].played = true;

      await persistenceService!.savePodcast(podcast);

      // Re-fetch and ensure all episodes played.
      podcast = (await persistenceService!.findPodcastById(podcast4.id!))!;

      expect(podcast.episodes[0].played, true);
      expect(podcast.episodes[1].played, true);
      expect(podcast.episodes[2].played, true);
    });
  });

  group('Multiple Podcast subscription handling', () {
    test('Subscribe to 3 podcasts; one with episodes', () async {
      podcast2.episodes = <Episode>[
        Episode(guid: 'EP001', title: 'Episode 1', pguid: podcast2.guid, podcast: podcast2.title),
        Episode(guid: 'EP002', title: 'Episode 2', pguid: podcast2.guid, podcast: podcast2.title),
        Episode(guid: 'EP003', title: 'Episode 3', pguid: podcast2.guid, podcast: podcast2.title),
      ];

      await persistenceService!.savePodcast(podcast1);

      var results = await persistenceService!.subscriptions();

      expect(listEquals(results, [podcast1]), true);

      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      results = await persistenceService!.subscriptions();

      expect(
          listEquals(results, [
            podcast1,
            podcast2,
            podcast3,
          ]),
          true);

      await persistenceService!.deletePodcast(podcast2);

      results = await persistenceService!.subscriptions();

      expect(
          listEquals(results, [
            podcast1,
            podcast3,
          ]),
          true);
    });

    test('Podcast stream', () async {
      await persistenceService!.savePodcast(podcast1);

      persistenceService!.podcastListener!.listen(
        expectAsync1(
          (event) {
            expect(event, podcast1);
          },
        ),
      );
    });

    test('Episode stream', () async {
      final episode = Episode(
          guid: 'EP001',
          title: 'Episode 1',
          pguid: podcast2.guid,
          podcast: podcast2.title,
          publicationDate: DateTime.now());

      await persistenceService!.saveEpisode(episode);

      persistenceService!.episodeListener!.listen(
        expectAsync1(
          (event) {
            expect(event.episode, episode);
          },
        ),
      );
    });
  });

  group('Saving, updating and retrieving episodes', () {
    test('Subscribe to podcasts and retrieve', () async {
      podcast2.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
      ];

      final episode2 = podcast2.episodes[1];

      expect(episode2.id == null, true);

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      final podcast = (await persistenceService!.findPodcastByGuid(podcast2.guid!))!;

      expect(listEquals(podcast2.episodes, podcast.episodes), true);

      final episode = await persistenceService!.findEpisodeByGuid(podcast.episodes[1].guid);

      expect(episode == episode2, true);

      final episodeById = await persistenceService!.findEpisodeById(podcast.episodes[1].id!);

      expect(episode == episodeById, true);

      expect(podcast3.subscribed, true);
    });

    test('Fetch all episodes for all podcasts', () async {
      podcast1.episodes = <Episode>[
        Episode(
            guid: 'P01EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'P01EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'P01EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: DateTime.now()),
      ];

      podcast2.episodes = <Episode>[
        Episode(
            guid: 'P02EP001',
            title: 'Episode 1',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'P02EP002',
            title: 'Episode 2',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
        Episode(
            guid: 'P02EP003',
            title: 'Episode 3',
            pguid: podcast2.guid,
            podcast: podcast2.title,
            publicationDate: DateTime.now()),
      ];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);

      final episodes = await persistenceService!.findAllEpisodes();

      expect(episodes.length, 6);
    });

    test('Delete all episodes for a podcast', () async {
      /// Save > 100 episodes (to test chunking)
      final episodes = <Episode>[];

      for (var x = 0; x < 150; x++) {
        episodes.add(Episode(
            guid: 'P01EP$x',
            title: 'Episode $x',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: DateTime.now()));
      }

      podcast1.episodes = episodes;

      await persistenceService!.savePodcast(podcast1);

      final e = await persistenceService!.findAllEpisodes();

      expect(e.length, 150);

      await persistenceService!.deleteEpisodes(episodes);
    });

    test('Queue handling - existing episodes', () async {
      final p1e1 = Episode(
          guid: 'P01EP01',
          title: 'Episode 1',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: DateTime.now());

      final p1e2 = Episode(
          guid: 'P01EP02',
          title: 'Episode 2',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: DateTime.now());

      final p2e1 = Episode(
          guid: 'P02EP01',
          title: 'Episode 1',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: DateTime.now());

      final p2e2 = Episode(
          guid: 'P02EP02',
          title: 'Episode 2',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: DateTime.now());

      podcast1.episodes = [p1e1, p1e2];
      podcast2.episodes = [p2e1, p2e2];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);

      final queue = <Episode>[p1e1, p1e2, p2e1, p2e2];

      await persistenceService!.saveQueue(queue);

      final fetchedQueue = await persistenceService!.loadQueue();

      expect(listEquals(queue, fetchedQueue), true);
    });

    test('Queue handling - ad-hoc episodes', () async {
      final p1e1 = Episode(
        guid: 'P01EP01',
        title: 'Episode 1',
        pguid: podcast1.guid,
        podcast: podcast1.title,
        publicationDate: DateTime.now(),
      );

      final p1e2 = Episode(
          guid: 'P01EP02',
          title: 'Episode 2',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: DateTime.now());

      final p2e1 = Episode(
        guid: 'P02EP01',
        title: 'Episode 1',
        pguid: podcast1.guid,
        podcast: podcast1.title,
        publicationDate: DateTime.now(),
      );

      final p2e2 = Episode(
        guid: 'P02EP02',
        title: 'Episode 2',
        pguid: podcast1.guid,
        podcast: podcast1.title,
        publicationDate: DateTime.now(),
      );

      final adhoc = Episode(
        pguid: '',
        guid: 'A01EP01',
        title: 'Episode 1',
        podcast: podcast1.title,
        publicationDate: DateTime.now(),
      );

      podcast1.episodes = [p1e1, p1e2];
      podcast2.episodes = [p2e1, p2e2];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);

      final queue = <Episode>[p1e1, p1e2, p2e1, p2e2, adhoc];

      await persistenceService!.saveQueue(queue);

      final fetchedQueue = await persistenceService!.loadQueue();

      expect(listEquals(queue, fetchedQueue), true);
    });
  });

  group('Saving, updating and retrieving downloaded episodes', () {
    test('Episodes ordered by reverse publication-date', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3),
      ];

      final orderedEpisodes = <Episode>[
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2),
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1),
      ];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      // Episodes should be returned in reverse publication-date order.
      final episodes = await persistenceService!.findEpisodesByPodcastGuid(podcast1.guid!);

      expect(listEquals(episodes, orderedEpisodes), true);
    });

    test('Fetch downloaded episodes', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3),
      ];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      final noDownloads = await persistenceService!.findDownloads();
      final emptyDownloaded = <Episode>[];

      expect(noDownloads, emptyDownloaded);

      final episode1 = (await persistenceService!.findEpisodeByGuid('EP001'))!;
      final episode2 = (await persistenceService!.findEpisodeByGuid('EP002'))!;

      expect(episode1 == podcast1.episodes[0], true);
      expect(episode2 == podcast1.episodes[1], true);

      // Save one episode as downloaded and re-fetch
      episode1.downloadPercentage = 100;
      episode1.downloadState = DownloadState.downloaded;

      episode2.downloadPercentage = 95;
      episode2.downloadState = DownloadState.downloading;

      final episode1Comp = await persistenceService!.saveEpisode(episode1);
      final episode2Comp = await persistenceService!.saveEpisode(episode2);

      final downloaded = <Episode>[episode1];
      final singleDownload = await persistenceService!.findDownloads();

      expect(listEquals(singleDownload, downloaded), true);
      expect(episode1Comp, episode1);
      expect(episode2Comp, episode2);
    });

    test('Test download state', () async {
      final download = Downloadable(
        taskId: 'TEST1',
        guid: 'downloadguid1',
        url: 'http://localhost/episode1.mp3',
        directory: 'test1',
        filename: 'episode1.mp3',
        state: DownloadState.none,
        percentage: 0,
      );

      final json = download.toMap();

      // Reconstruct from the JSON.
      final d = Downloadable.fromMap(json);

      // Check they match
      expect(true, download == d);

      // Check states
      json['state'] = 0;
      expect(Downloadable.fromMap(json).state == DownloadState.none, true);

      json['state'] = 1;
      expect(Downloadable.fromMap(json).state == DownloadState.queued, true);

      json['state'] = 2;
      expect(Downloadable.fromMap(json).state == DownloadState.downloading, true);

      json['state'] = 3;
      expect(Downloadable.fromMap(json).state == DownloadState.failed, true);

      json['state'] = 4;
      expect(Downloadable.fromMap(json).state == DownloadState.cancelled, true);

      json['state'] = 5;
      expect(Downloadable.fromMap(json).state == DownloadState.paused, true);

      json['state'] = 6;
      expect(Downloadable.fromMap(json).state == DownloadState.downloaded, true);
    });

    test('Delete downloaded episodes', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3),
      ];

      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      final episode1 = (await persistenceService!.findEpisodeByGuid('EP001'))!;
      final episode2 = (await persistenceService!.findEpisodeByGuid('EP002'))!;

      expect(episode1 == podcast1.episodes[0], true);
      expect(episode2 == podcast1.episodes[1], true);

      episode1.downloadPercentage = 100;
      episode1.downloadState = DownloadState.downloaded;

      episode2.downloadPercentage = 100;
      episode2.downloadState = DownloadState.downloaded;

      await persistenceService!.saveEpisode(episode1);
      await persistenceService!.saveEpisode(episode2);

      var downloads = await persistenceService!.findDownloads();

      expect(listEquals(downloads, <Episode>[episode2, episode1]), true);

      await persistenceService!.deleteEpisode(episode1);

      downloads = await persistenceService!.findDownloads();

      expect(listEquals(downloads, <Episode>[episode2]), true);
    });

    test('Subscribe after downloading episodes', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            downloadPercentage: 0),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5,
            downloadPercentage: 0),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4,
            downloadPercentage: 0),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3,
            downloadPercentage: 0),
      ];

      final episode2 = Episode(
          guid: 'EP002',
          title: 'Episode 2',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: pubDate2,
          downloadPercentage: 100);

      final episode5 = Episode(
          guid: 'EP005',
          title: 'Episode 5',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: pubDate5,
          downloadPercentage: 100);

      // Save the downloaded episodes
      await persistenceService!.saveEpisode(episode2);
      await persistenceService!.saveEpisode(episode5);

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      // Fetch podcast1. Episodes should match.
      final p = (await persistenceService!.findPodcastByGuid(podcast1.guid!))!;

      // Episodes 2 and 5 will be the saved episodes rather than
      // the blank episodes.
      final ep1 = p.episodes.firstWhere((e) => e.guid == 'EP001');
      final ep2 = p.episodes.firstWhere((e) => e.guid == 'EP002');
      final ep3 = p.episodes.firstWhere((e) => e.guid == 'EP003');
      final ep4 = p.episodes.firstWhere((e) => e.guid == 'EP004');
      final ep5 = p.episodes.firstWhere((e) => e.guid == 'EP005');

      expect(ep1.downloadPercentage == 0, true);
      expect(ep2.downloadPercentage == 100, true);
      expect(ep3.downloadPercentage == 0, true);
      expect(ep4.downloadPercentage == 0, true);
      expect(ep5.downloadPercentage == 100, true);
    });

    test('Fetch downloads for podcast', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            downloadPercentage: 0),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5,
            downloadPercentage: 0),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4,
            downloadPercentage: 0),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3,
            downloadPercentage: 0),
      ];

      final episode2 = Episode(
          guid: 'EP002',
          title: 'Episode 2',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: pubDate2,
          downloadPercentage: 100);

      final episode5 = Episode(
          guid: 'EP005',
          title: 'Episode 5',
          pguid: podcast1.guid,
          podcast: podcast1.title,
          publicationDate: pubDate5,
          downloadPercentage: 100);

      // Save the downloaded episodes
      await persistenceService!.saveEpisode(episode2);
      await persistenceService!.saveEpisode(episode5);

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);
      await persistenceService!.savePodcast(podcast2);
      await persistenceService!.savePodcast(podcast3);

      final pd1 = await persistenceService!.findDownloadsByPodcastGuid(podcast1.guid!);
      final pd2 = await persistenceService!.findDownloadsByPodcastGuid(podcast2.guid!);

      expect(listEquals(pd1, <Episode>[episode5, episode2]), true);
      expect(listEquals(pd2, <Episode>[]), true);
    });

    test('Fetch downloads by task ID', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      const tid1 = 'AAAA-BBBB-CCCC-DDDD-1000';
      const tid2 = 'AAAA-BBBB-CCCC-DDDD-2000';

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            downloadState: DownloadState.none,
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            downloadState: DownloadState.downloaded,
            downloadPercentage: 100),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5,
            downloadState: DownloadState.downloading,
            downloadPercentage: 50),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4,
            downloadState: DownloadState.none,
            downloadPercentage: 0),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3,
            downloadState: DownloadState.none,
            downloadPercentage: 0),
      ];

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);

      final noDownload = await persistenceService!.findEpisodeByTaskId(tid1);

      expect(noDownload, null);

      final e1 = podcast1.episodes.firstWhere((e) => e.guid == 'EP002');
      final e2 = podcast1.episodes.firstWhere((e) => e.guid == 'EP005');

      e1.downloadTaskId = tid1;
      e2.downloadTaskId = tid2;

      await persistenceService!.saveEpisode(e1);
      await persistenceService!.saveEpisode(e2);

      final episode1 = (await persistenceService!.findEpisodeByTaskId(tid1))!;

      expect(episode1.downloadPercentage, 100);

      final episode2 = (await persistenceService!.findEpisodeByTaskId(tid2))!;

      expect(episode2.downloadPercentage, 50);
    });

    test('Test episode state', () async {
      final pubDate5 = DateTime.now();
      final pubDate4 = DateTime.now().subtract(const Duration(days: 1));
      final pubDate3 = DateTime.now().subtract(const Duration(days: 2));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            description: 'Episode 1 description',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            downloadPercentage: 0),
        Episode(
            guid: 'EP005',
            title: 'Episode 5',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate5,
            downloadPercentage: 0),
        Episode(
            guid: 'EP004',
            title: 'Episode 4',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate4,
            downloadPercentage: 0),
        Episode(
            guid: 'EP003',
            title: 'Episode 3',
            description: '<b>Episode 3</b> description',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate3,
            downloadPercentage: 100),
      ];

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);

      // Fetch the downloaded podcast
      var episode = (await persistenceService!.findEpisodeByGuid('EP001'))!;

      expect(episode.downloaded, false);
      expect(episode.descriptionText == 'Episode 1 description', true);

      episode = (await persistenceService!.findEpisodeByGuid('EP002'))!;

      expect(episode.descriptionText == '', true);

      episode = (await persistenceService!.findEpisodeByGuid('EP003'))!;

      expect(episode.downloaded, true);
      expect(episode.descriptionText == 'Episode 3 description', true);
    });

    test('Test episode duration', () async {
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            description: 'Episode 1 description',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            position: 60000,
            // 1 min in ms
            duration: 120,
            // 2 min in s
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            position: 0,
            duration: 240,
            downloadPercentage: 100),
      ];

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);

      // Fetch the downloaded podcast
      var episode = (await persistenceService!.findEpisodeByGuid('EP001'))!;

      expect(episode.timeRemaining.inSeconds == 60, true);
      expect(episode.percentagePlayed == 50.0, true);

      episode = (await persistenceService!.findEpisodeByGuid('EP002'))!;

      expect(episode.timeRemaining.inSeconds == 0, true);
      expect(episode.percentagePlayed == 0.0, true);

      // Invalid position
      episode.position = 500000;
      expect(episode.percentagePlayed == 100.0, true);
    });

    test('Test episode transcript read/write', () async {
      final transcript = Transcript(guid: 'GUID1', subtitles: <Subtitle>[
        Subtitle(
            index: 0,
            start: Duration.zero,
            data: 'This is line 1',
            end: const Duration(seconds: 10),
            speaker: 'Speaker 1'),
        Subtitle(
            index: 1,
            start: const Duration(seconds: 10),
            data: 'This is line 2',
            end: const Duration(seconds: 20),
            speaker: 'Speaker 2'),
      ]);

      final savedTranscript = await persistenceService!.saveTranscript(transcript);
      final fetchedTranscript = await persistenceService!.findTranscriptById(savedTranscript.id!);

      expect(savedTranscript == fetchedTranscript, true);

      await persistenceService!.deleteTranscriptById(savedTranscript.id!);

      final deletedTranscript = await persistenceService!.findTranscriptById(savedTranscript.id!);

      expect(deletedTranscript == null, true);
    });
    test('Test episode transcript read/write', () async {
      final transcript = Transcript(guid: 'GUID1', subtitles: <Subtitle>[
        Subtitle(
            index: 0,
            start: Duration.zero,
            data: 'This is line 1',
            end: const Duration(seconds: 10),
            speaker: 'Speaker 1'),
        Subtitle(
            index: 1,
            start: const Duration(seconds: 10),
            data: 'This is line 2',
            end: const Duration(seconds: 20),
            speaker: 'Speaker 2'),
      ]);

      final savedTranscript = await persistenceService!.saveTranscript(transcript);
      final fetchedTranscript = await persistenceService!.findTranscriptById(savedTranscript.id!);

      expect(savedTranscript == fetchedTranscript, true);

      await persistenceService!.deleteTranscriptById(savedTranscript.id!);

      final deletedTranscript = await persistenceService!.findTranscriptById(savedTranscript.id!);

      expect(deletedTranscript == null, true);
    });

    test('Test episode transcript read/write bulk', () async {
      final transcript1 = Transcript(guid: 'GUID1', subtitles: <Subtitle>[
        Subtitle(
            index: 0,
            start: Duration.zero,
            data: 'This is line 1',
            end: const Duration(seconds: 10),
            speaker: 'Speaker 1'),
        Subtitle(
            index: 1,
            start: const Duration(seconds: 10),
            data: 'This is line 2',
            end: const Duration(seconds: 20),
            speaker: 'Speaker 2'),
      ]);

      final transcript2 = Transcript(guid: 'GUID1', subtitles: <Subtitle>[
        Subtitle(
            index: 0,
            start: Duration.zero,
            data: 'This is line 1b',
            end: const Duration(seconds: 100),
            speaker: 'Speaker 1b'),
        Subtitle(
            index: 1,
            start: const Duration(seconds: 100),
            data: 'This is line 2b',
            end: const Duration(seconds: 200),
            speaker: 'Speaker 2b'),
      ]);

      final savedTranscript1 = await persistenceService!.saveTranscript(transcript1);
      final savedTranscript2 = await persistenceService!.saveTranscript(transcript2);

      var fetchedTranscript1 = await persistenceService!.findTranscriptById(savedTranscript1.id!);
      var fetchedTranscript2 = await persistenceService!.findTranscriptById(savedTranscript2.id!);

      expect(fetchedTranscript1?.id != null, true);
      expect(fetchedTranscript2?.id != null, true);
      expect(savedTranscript1 == fetchedTranscript1, true);
      expect(savedTranscript2 == fetchedTranscript2, true);

      await persistenceService!.deleteTranscriptsById(<int>[fetchedTranscript1?.id ?? 0, fetchedTranscript2?.id ?? 0]);

      fetchedTranscript1 = await persistenceService!.findTranscriptById(savedTranscript1.id!);
      fetchedTranscript2 = await persistenceService!.findTranscriptById(savedTranscript2.id!);

      expect(fetchedTranscript1 == null, true);
      expect(fetchedTranscript2 == null, true);
    });

    test('Test episode transcript data', () async {
      final pubDate1 = DateTime.now().subtract(const Duration(days: 4));
      final pubDate2 = DateTime.now().subtract(const Duration(days: 3));

      final transcript = Transcript(guid: 'GUID1', subtitles: <Subtitle>[
        Subtitle(
            index: 0,
            start: Duration.zero,
            data: 'This is line 1',
            end: const Duration(seconds: 10),
            speaker: 'Speaker 1'),
        Subtitle(
            index: 1,
            start: const Duration(seconds: 10),
            data: 'This is line 2',
            end: const Duration(seconds: 20),
            speaker: 'Speaker 2'),
      ]);

      final savedTranscript = await persistenceService!.saveTranscript(transcript);

      expect(savedTranscript.id != null, true);
      expect(transcript == savedTranscript, true);

      transcript.subtitles[0].data = 'This is line 1 updated';

      final updatedTranscript = await persistenceService!.saveTranscript(savedTranscript);

      expect(transcript == updatedTranscript, true);

      podcast1.episodes = <Episode>[
        Episode(
            guid: 'EP001',
            title: 'Episode 1',
            description: 'Episode 1 description',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate1,
            transcriptId: savedTranscript.id,
            position: 60000,
            // 1 min in ms
            duration: 120,
            // 2 min in s
            downloadPercentage: 0),
        Episode(
            guid: 'EP002',
            title: 'Episode 2',
            pguid: podcast1.guid,
            podcast: podcast1.title,
            publicationDate: pubDate2,
            position: 0,
            duration: 240,
            downloadPercentage: 100),
      ];

      // Save the podcasts.
      await persistenceService!.savePodcast(podcast1);

      // Fetch the downloaded podcast
      final episode1 = await persistenceService!.findEpisodeByGuid('EP001');
      final episode2 = await persistenceService!.findEpisodeByGuid('EP002');

      expect(episode1 == podcast1.episodes[0], true);
      expect(episode2 == podcast1.episodes[1], true);
    });
  });
}
