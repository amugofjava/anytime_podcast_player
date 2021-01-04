// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/repository/sembast/sembast_database_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

/// An implementation of [Repository] that is backed by Sembast.
class SembastRepository extends Repository {
  final _podcastSubject = BehaviorSubject<Podcast>();
  final _episodeSubject = BehaviorSubject<EpisodeState>();

  final _podcastStore = intMapStoreFactory.store('podcast');
  final _episodeStore = intMapStoreFactory.store('episode');
  final DatabaseService _databaseService = DatabaseService();

  Future<Database> get _db async => _databaseService.database;

  /// Saves the [Podcast] instance and associated [Epsiode]s. Podcasts are
  /// only stored when we subscribe to them, so at the point we store a
  /// new podcast we store the current [DateTime] to mark the
  /// subscription date.
  @override
  Future<Podcast> savePodcast(Podcast podcast) async {
    final finder = Finder(filter: Filter.equals('guid', podcast.guid));
    final snapshot = await _podcastStore.findFirst(await _db, finder: finder);

    if (snapshot == null) {
      podcast.subscribedDate = DateTime.now();
      podcast.id = await _podcastStore.add(await _db, podcast.toMap());
    } else {
      await _podcastStore.update(await _db, podcast.toMap(), finder: finder);
    }

    await _saveEpisodes(podcast.episodes);

    _podcastSubject.add(podcast);

    return podcast;
  }

  @override
  Future<List<Podcast>> subscriptions() async {
    final finder = Finder(sortOrders: [
      SortOrder('title'),
    ]);

    final subscriptionSnapshot = await _podcastStore.find(
      await _db,
      finder: finder,
    );

    final subs = subscriptionSnapshot.map((snapshot) {
      final subscription = Podcast.fromMap(snapshot.key, snapshot.value);

      return subscription;
    }).toList();

    return subs;
  }

  @override
  Future<void> deletePodcast(Podcast podcast) async {
    final db = await _db;

    await db.transaction((txn) async {
      final podcastFinder = Finder(filter: Filter.byKey(podcast.id));
      final episodeFinder = Finder(filter: Filter.equals('pguid', podcast.guid));

      await _podcastStore.delete(
        txn,
        finder: podcastFinder,
      );

      await _episodeStore.delete(
        txn,
        finder: episodeFinder,
      );
    });
  }

  @override
  Future<Podcast> findPodcastById(num id) async {
    final finder = Finder(filter: Filter.byKey(id));

    final snapshot = await _podcastStore.findFirst(await _db, finder: finder);

    if (snapshot != null) {
      var p = Podcast.fromMap(snapshot.key, snapshot.value);

      // Now attach all episodes for this podcast
      p.episodes = await findEpisodesByPodcastGuid(p.guid);

      return p;
    }

    return null;
  }

  @override
  Future<Podcast> findPodcastByGuid(String guid) async {
    final finder = Finder(filter: Filter.equals('guid', guid));

    final snapshot = await _podcastStore.findFirst(await _db, finder: finder);

    if (snapshot != null) {
      var p = Podcast.fromMap(snapshot.key, snapshot.value);

      // Now attach all episodes for this podcast
      p.episodes = await findEpisodesByPodcastGuid(p.guid);

      return p;
    }

    return null;
  }

  @override
  Future<Episode> findEpisodeByGuid(String guid) async {
    final finder = Finder(filter: Filter.equals('guid', guid));

    final snapshot = await _episodeStore.findFirst(await _db, finder: finder);

    return snapshot == null ? null : Episode.fromMap(snapshot.key, snapshot.value);
  }

  @override
  Future<List<Episode>> findEpisodesByPodcastGuid(String pguid) async {
    final finder = Finder(
      filter: Filter.equals('pguid', pguid),
      sortOrders: [SortOrder('publicationDate', false)],
    );

    final recordSnapshots = await _episodeStore.find(await _db, finder: finder);

    final results = recordSnapshots.map((snapshot) {
      final episode = Episode.fromMap(snapshot.key, snapshot.value);

      return episode;
    }).toList();

    return results;
  }

  @override
  Future<List<Episode>> findDownloadsByPodcastGuid(String pguid) async {
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('pguid', pguid),
        Filter.equals('downloadPercentage', '100'),
      ]),
      sortOrders: [SortOrder('publicationDate', false)],
    );

    final recordSnapshots = await _episodeStore.find(await _db, finder: finder);

    final results = recordSnapshots.map((snapshot) {
      final episode = Episode.fromMap(snapshot.key, snapshot.value);

      return episode;
    }).toList();

    return results;
  }

  @override
  Future<List<Episode>> findDownloads() async {
    final finder = Finder(filter: Filter.equals('downloadPercentage', '100'), sortOrders: [SortOrder('publicationDate', false)]);

    final recordSnapshots = await _episodeStore.find(await _db, finder: finder);

    final results = recordSnapshots.map((snapshot) {
      final episode = Episode.fromMap(snapshot.key, snapshot.value);

      return episode;
    }).toList();

    return results;
  }

  @override
  Future<void> deleteEpisode(Episode episode) async {
    final finder = Finder(filter: Filter.byKey(episode.id));

    final snapshot = await _episodeStore.findFirst(await _db, finder: finder);

    if (snapshot == null) {
      // Oops!
    } else {
      await _episodeStore.delete(await _db, finder: finder);
      _episodeSubject.add(EpisodeDeleteState(episode));
    }
  }

  @override
  Future<Episode> saveEpisode(Episode episode) async {
    var e = await _saveEpisode(episode);

    _episodeSubject.add(EpisodeUpdateState(episode));

    return e;
  }

  Future<void> _saveEpisodes(List<Episode> episodes) async {
    var d = await _db;

    await d.transaction((txn) async {
      var futures = <Future<int>>[];

      for (var e in episodes) {
        if (e.id == null) {
          e.id = await _episodeStore.add(txn, e.toMap());
        } else {
          final finder = Finder(filter: Filter.byKey(e.id));

          futures.add(_episodeStore.update(txn, e.toMap(), finder: finder));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    });
  }

  Future<Episode> _saveEpisode(Episode episode) async {
    final finder = Finder(filter: Filter.byKey(episode.id));

    final snapshot = await _episodeStore.findFirst(await _db, finder: finder);

    if (snapshot == null) {
      episode.id = await _episodeStore.add(await _db, episode.toMap());
    } else {
      await _episodeStore.update(await _db, episode.toMap(), finder: finder);
    }

    return episode;
  }

  @override
  Future<Episode> findEpisodeByTaskId(String id) async {
    final finder = Finder(filter: Filter.equals('downloadTaskId', id));
    final snapshot = await _episodeStore.findFirst(await _db, finder: finder);

    return snapshot == null ? null : Episode.fromMap(snapshot.key, snapshot.value);
  }

  @override
  Future<void> close() async {
    final d = await _db;

    return d.close();
  }

  @override
  Stream<EpisodeState> get episodeListener => _episodeSubject.stream;

  @override
  Stream<Podcast> get podcastListener => _podcastSubject.stream;
}
