// Copyright 2019 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:anytime/api/podcast/podcast_api.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/funding.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart';
import 'package:podcast_search/podcast_search.dart' as psapi;

class MobilePodcastService extends PodcastService {
  final _cache = _PodcastCache(maxItems: 10, expiration: Duration(minutes: 30));
  final Future<Map<String, dynamic>> Function(String url) loadMetadata;

  MobilePodcastService({
    @required PodcastApi api,
    @required Repository repository,
    @required SettingsService settingsService,
    this.loadMetadata,
  }) : super(api: api, repository: repository, settingsService: settingsService);

  @override
  Future<psapi.SearchResult> search({
    String term,
    String country,
    String attribute,
    int limit,
    String language,
    int version = 0,
    bool explicit = false,
  }) {
    return api.search(
      term,
      country: country,
      attribute: attribute,
      limit: limit,
      language: language,
      explicit: explicit,
      searchProvider: settingsService.searchProvider,
    );
  }

  @override
  Future<psapi.SearchResult> charts({
    int size,
  }) {
    return api.charts(size);
  }

  /// Loads the specified [Podcast]. If the Podcast instance has an ID we'll fetch
  /// it from storage. If not, we'll check the cache to see if we have seen it
  /// recently and return that if available. If not, we'll make a call to load
  /// it from the network.
  @override
  Future<Podcast> loadPodcast({@required Podcast podcast, bool refresh}) async {
    if (podcast.id == null || refresh) {
      psapi.Podcast loadedPodcast;
      var title = '';
      var description = '';
      var copyright = '';
      Map<String, dynamic> metadata;

      if (!refresh) {
        loadedPodcast = _cache.item(podcast.url);
      }

      // If we didn't get a cache hit load the podcast feed.
      if (loadedPodcast == null) {
        try {
          loadedPodcast = await _loadPodcastFeed(url: podcast.url);
        } on Exception {
          rethrow;
        }

        _cache.store(loadedPodcast);
      }

      // Sometimes, key values such as title, description etc contain new lines and empty
      // spaces. We need to ensure these are all trimmed before we make the data available
      // to the user.
      if (loadedPodcast.title != null) {
        title = loadedPodcast.title.replaceAll('\n', '').trim();
      }
      if (loadedPodcast.description != null) {
        description = loadedPodcast.description.replaceAll('\n', '').trim();
      }
      if (loadedPodcast.copyright != null) {
        copyright = loadedPodcast.copyright.replaceAll('\n', '').trim();
      }

      final existingEpisodes = await repository.findEpisodesByPodcastGuid(loadedPodcast.url);
      var funding = <Funding>[];

      loadedPodcast.funding?.forEach((f) => funding.add(Funding(url: f.url, value: f.value)));

      if (loadMetadata != null) {
        metadata = await loadMetadata(loadedPodcast.url);
      }
      final pc = Podcast(
        guid: loadedPodcast.url,
        url: loadedPodcast.url,
        link: loadedPodcast.link,
        title: title,
        description: description,
        imageUrl: podcast.imageUrl ?? loadedPodcast.image,
        thumbImageUrl: podcast.thumbImageUrl ?? loadedPodcast.image,
        copyright: copyright,
        funding: funding,
        episodes: <Episode>[],
        metadata: metadata,
      );

      /// We could be subscribed to this podcast already. Let's check.
      var r = await repository.findPodcastByGuid(loadedPodcast.url);

      if (r != null) {
        // We are, so swap in the stored ID so we update the saved version later.
        pc.id = r.id;
      }

      // Find all episodes from the feed.
      if (loadedPodcast.episodes != null) {
        // Usually, episodes are order by reverse publication date - but not always.
        // Enforce that ordering. To prevent unnecessary sorting, we'll sample the
        // first two episodes to see what order they are in.
        if (loadedPodcast.episodes.length > 1) {
          if (loadedPodcast.episodes[0].publicationDate.millisecondsSinceEpoch <
              loadedPodcast.episodes[1].publicationDate.millisecondsSinceEpoch) {
            loadedPodcast.episodes.sort((e1, e2) => e2.publicationDate.compareTo(e1.publicationDate));
          }
        }

        for (final episode in loadedPodcast.episodes) {
          var existingEpisode = existingEpisodes.firstWhere((ep) => ep.guid == episode.guid, orElse: () => null);

          if (existingEpisode == null) {
            var author = episode.author;
            var title = episode.title;
            var description = episode.description;

            if (author != null) {
              author = author.replaceAll('\n', '').trim();
            }

            if (title != null) {
              title = title.replaceAll('\n', '').trim();
            }

            if (description != null) {
              description = description.replaceAll('\n', '').trim();
            }

            pc.episodes.add(Episode(
              pguid: pc.guid,
              guid: episode.guid,
              podcast: pc.title,
              title: title,
              description: description,
              author: author,
              season: episode.season ?? 0,
              episode: episode.episode ?? 0,
              contentUrl: episode.contentUrl,
              link: episode.link,
              imageUrl: pc.imageUrl,
              thumbImageUrl: pc.thumbImageUrl,
              duration: episode.duration?.inSeconds ?? 0,
              publicationDate: episode.publicationDate,
              chaptersUrl: episode.chapters?.url,
              chapters: <Chapter>[],
              metadata: metadata,
            ));
          } else {
            pc.episodes.add(existingEpisode);
          }
        }
      }

      // Add any downloaded episodes that are no longer in the feed - they
      // may have expired but we still want them.
      for (final episode in existingEpisodes) {
        var feedEpisode = loadedPodcast.episodes.firstWhere((ep) => ep.guid == episode.guid, orElse: () => null);

        if (feedEpisode == null) {
          pc.episodes.add(episode);
        }
      }

      // If we are subscribed to this podcast and are simply refreshing we
      // need to save the updated subscription. A non-null ID indicates this
      // podcast is subscribed too.
      if (podcast.id != null && refresh) {
        await repository.savePodcast(pc);
      }

      return pc;
    } else {
      return await loadPodcastById(id: podcast.id);
    }
  }

  @override
  Future<Podcast> loadPodcastById({@required int id}) {
    return repository.findPodcastById(id);
  }

  @override
  Future<List<Chapter>> loadChaptersByUrl({@required String url}) async {
    var c = await psapi.Podcast.loadChaptersByUrl(url: url);
    var chapters = <Chapter>[];

    if (c != null) {
      for (var chapter in c.chapters) {
        chapters.add(Chapter(
          title: chapter.title,
          url: chapter.url,
          imageUrl: chapter.imageUrl,
          startTime: chapter.startTime,
          endTime: chapter.endTime,
          toc: chapter.toc,
        ));
      }
    }

    return chapters;
  }

  @override
  Future<List<Episode>> loadDownloads() async {
    return repository.findDownloads();
  }

  @override
  Future<void> deleteDownload(Episode episode) async {
    // If this episode is currently downloading, cancel the download first.
    if (episode.downloadPercentage < 100) {
      await FlutterDownloader.cancel(taskId: episode.downloadTaskId);
    }

    episode.downloadTaskId = null;
    episode.downloadPercentage = 0;
    episode.position = 0;
    episode.downloadState = DownloadState.none;

    if (settingsService.markDeletedEpisodesAsPlayed) {
      episode.played = true;
    }

    await repository.saveEpisode(episode);

    if (await hasStoragePermission()) {
      final filepath = episode.filepath == null || episode.filepath.isEmpty ? await getStorageDirectory() : episode.filepath;
      final filename = join(filepath, episode.filename);

      var f = File.fromUri(Uri.file(filename));

      if (await f.exists()) {
        return f.delete();
      }
    }

    return null;
  }

  @override
  Future<void> toggleEpisodePlayed(Episode episode) async {
    episode.played = !episode.played;
    episode.position = 0;

    return repository.saveEpisode(episode);
  }

  @override
  Future<List<Podcast>> subscriptions() {
    return repository.subscriptions();
  }

  @override
  Future<void> unsubscribe(Podcast podcast) async {
    if (await hasStoragePermission()) {
      final filename = join(await getStorageDirectory(), safePath(podcast.title));

      final d = Directory.fromUri(Uri.file(filename));

      if (await d.exists()) {
        await d.delete(recursive: true);
      }
    }

    return repository.deletePodcast(podcast);
  }

  @override
  Future<Podcast> subscribe(Podcast podcast) async {
    // We may already have episodes download for this podcast before the user
    // hit subscribe.
    var savedEpisodes = await repository.findEpisodesByPodcastGuid(podcast.guid);

    for (var episode in podcast.episodes) {
      episode = savedEpisodes?.firstWhere((ep) => ep.guid == episode.guid, orElse: () => episode);

      episode.pguid = podcast.guid;
    }

    return repository.savePodcast(podcast);
  }

  @override
  Future<Podcast> save(Podcast podcast) async {
    return repository.savePodcast(podcast);
  }

  @override
  Future<Episode> saveEpisode(Episode episode) async {
    return repository.saveEpisode(episode);
  }

  /// Loading and parsing a podcast feed can take several seconds. Larger feeds
  /// can end up blocking the UI thread. We perform our feed load in a
  /// separate isolate so that the UI can continue to present a loading
  /// indicator whilst the data is fetched without locking the UI.
  Future<psapi.Podcast> _loadPodcastFeed({@required String url}) {
    return compute<_FeedComputer, psapi.Podcast>(_loadPodcastFeedCompute, _FeedComputer(api: api, url: url));
  }

  /// We have to separate the process of calling compute as you cannot use
  /// named parameters with compute. The podcast feed load API uses named
  /// parameters so we need to change it to a single, positional parameter.
  static Future<psapi.Podcast> _loadPodcastFeedCompute(_FeedComputer c) {
    return c.api.loadFeed(c.url);
  }

  @override
  Stream<Podcast> get podcastListener => repository.podcastListener;

  @override
  Stream<EpisodeState> get episodeListener => repository.episodeListener;
}

/// A simple cache to reduce the number of network calls when loading podcast
/// feeds. We can cache up to [maxItems] items with each item having an
/// expiration time of [expiration]. The cache works as a FIFO queue, so if we
/// attempt to store a new item in the cache and it is full we remove the
/// first (and therefore oldest) item from the cache. Cache misses are returned
/// as null.
class _PodcastCache {
  final int maxItems;
  final Duration expiration;
  final Queue<_CacheItem> _queue;

  _PodcastCache({@required this.maxItems, @required this.expiration}) : _queue = Queue<_CacheItem>();

  psapi.Podcast item(String key) {
    var hit = _queue.firstWhere((_CacheItem i) => i.podcast.url == key, orElse: () => null);
    psapi.Podcast p;

    if (hit != null) {
      var now = DateTime.now();

      if (now.difference(hit.dateAdded) <= expiration) {
        p = hit.podcast;
      } else {
        _queue.remove(hit);
      }
    }

    return p;
  }

  void store(psapi.Podcast podcast) {
    if (_queue.length == maxItems) {
      _queue.removeFirst();
    }

    _queue.addLast(_CacheItem(podcast));
  }
}

/// A simple class that stores an instance of a Postcast and the
/// date and time it was added. This can be used by the cache to
/// keep a small and up-to-date list of searched for Podcasts.
class _CacheItem {
  final psapi.Podcast podcast;
  final DateTime dateAdded;

  _CacheItem(this.podcast) : dateAdded = DateTime.now();
}

class _FeedComputer {
  final PodcastApi api;
  final String url;

  _FeedComputer({@required this.api, @required this.url});
}
