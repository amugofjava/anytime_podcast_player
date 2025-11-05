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
import 'package:anytime/entities/person.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/library_state.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:podcast_search/podcast_search.dart' as podcast_search;
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

class MobilePodcastService extends PodcastService {
  final _log = Logger('MobilePodcastService');
  final _descriptionRegExp1 = RegExp(r'(</p><br>|</p></br>|<p><br></p>|<p></br></p>)');
  final _descriptionRegExp2 = RegExp(r'(<p><br></p>|<p></br></p>)');
  final _cache = _PodcastCache(maxItems: 10, expiration: const Duration(minutes: 30));
  final _lock = Lock();
  final _libraryState = BehaviorSubject<LibraryState>();

  var _categories = <String>[];
  var _intlCategories = <String?>[];
  var _intlCategoriesSorted = <String>[];

  MobilePodcastService({
    required super.api,
    required super.repository,
    required super.notificationService,
    required super.settingsService,
  }) {
    _init();
  }

  Future<void> _init() async {
    final locale = await currentLocale();

    _setupGenres(locale);

    /// Setup background update handling if the repository supports it.
    await initBackgroundFetch();

    /// Listen for user changes in search provider. If changed, reload the genre list
    settingsService.settingsListener.where((event) => event == 'search').listen((event) {
      _setupGenres(locale);
    });
  }

  /// We fetch the fixed list of Genre's for the search engine provider we are using. These
  /// lists are always in English; therefore, we also fetch the translated version if available.
  /// We can the use these two lists to present the user with a list of genres in the correct
  /// language whilst submitting the English version to the API.
  void _setupGenres(String locale) {
    var categoryList = '';

    /// Fetch the correct categories for the current local and selected provider.
    if (settingsService.searchProvider == 'itunes') {
      _categories = PodcastService.itunesGenres;
      categoryList = Intl.message('discovery_categories_itunes', locale: locale);
    } else {
      _categories = PodcastService.podcastIndexGenres;
      categoryList = Intl.message('discovery_categories_pindex', locale: locale);
    }

    _intlCategories = categoryList.split(',');
    _intlCategoriesSorted = categoryList.split(',');

    // The very first item in the list should be 'All' (in the appropriate language).
    var firstItem = _intlCategories[0] ?? 'All';

    // Sort the rest of the list and then insert All at the start.
    _intlCategoriesSorted = _intlCategories.sublist(1).nonNulls.toList();

    _intlCategoriesSorted.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _intlCategoriesSorted.insert(0, firstItem);

    assert(_intlCategoriesSorted.length == _intlCategories.length);
  }

  @override
  Future<podcast_search.SearchResult> search({
    required String term,
    String? country,
    String? attribute,
    int? limit,
    String? language,
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
  Future<podcast_search.SearchResult> charts({
    int size = 20,
    String? genre,
    String? countryCode = '',
    String? languageCode = '',
  }) {
    var providerGenre = _decodeGenre(genre);

    return api.charts(
      size: size,
      searchProvider: settingsService.searchProvider,
      genre: providerGenre,
      countryCode: countryCode,
      languageCode: languageCode,
    );
  }

  @override
  List<String> genres() {
    return _intlCategoriesSorted;
  }

  /// Loads the specified [Podcast] from an RSS feed. If [ignoreCache] is set to try we will
  /// always attempt to fetch the podcast from the RSS feed. If not, we have a couple of
  /// mechanisms to attempt to reduce unnecessary fetching, such as checking our local
  /// cache for the podcast and using the last updated date stored in the HTTP header.
  ///
  /// TODO: The complexity of this method is now too high - needs to be refactored.
  @override
  Future<Podcast?> loadPodcast({
    required Podcast podcast,
    bool highlightNewEpisodes = false,
    bool ignoreCache = false,
  }) async {
    DateTime? rssLastUpdated;
    var fetch = false;

    _log.fine('loadPodcast. ID ${podcast.id} (refresh $ignoreCache)');

    // Do we have this podcast in our cache?
    final cachedPodcast = _cache.item(podcast.url);

    if (cachedPodcast != null && !ignoreCache) {
      _log.fine('Returning cached podcast');

      return cachedPodcast;
    } else if (podcast.id != null && podcast.etag.isEmpty) {
      _log.fine('We are checking the feed for an existing podcast,');

      final storedPodcast = await repository.findPodcastById(podcast.id!);
      var headUrl = podcast.url;

      int tries = 2;

      while (tries-- > 0) {
        try {
          rssLastUpdated = await api.feedLastUpdated(headUrl);
          tries = 0;
        } catch (e) {
          if (tries > 0) {
            //TODO: Needs improving to only fall back if original URL was http and we forced it up to https.
            if ((e is podcast_search.PodcastCertificateException || e is podcast_search.PodcastFailedException) &&
                headUrl.startsWith('https')) {
              _log.fine('Certificate error whilst fetching podcast. Fallback to http and try again');

              headUrl = headUrl.replaceFirst('https', 'http');
            }
          } else {
            rethrow;
          }
        }
      }

      if (rssLastUpdated == null || rssLastUpdated.isAfter(storedPodcast!.rssFeedLastUpdated)) {
        fetch = true;
      } else {
        // Just update the last updated value.
        save(storedPodcast, withEpisodes: false);

        return storedPodcast;
      }
    } else {
      fetch = true;
    }

    if (fetch) {
      return await _fetchPodcastFromFeed(podcast, ignoreCache, highlightNewEpisodes);
    }

    return null;
  }

  Future<Podcast?> _fetchPodcastFromFeed(Podcast podcast, bool ignoreCache, bool highlightNewEpisodes) async {
    var imageUrl = podcast.imageUrl;
    var thumbImageUrl = podcast.thumbImageUrl;
    var sourceUrl = podcast.url;

    podcast_search.Podcast? loadedPodcast;

    var tries = 3;
    var url = podcast.url;

    while (tries-- > 0) {
      try {
        _log.fine('Loading podcast from feed $url with etag ${podcast.etag}.');

        loadedPodcast = await _loadPodcastFeed(url: url, etag: podcast.etag);
        tries = 0;
      } catch (e) {
        if (tries > 0) {
          //TODO: Needs improving to only fall back if original URL was http and we forced it up to https.
          if ((e is podcast_search.PodcastCertificateException || e is podcast_search.PodcastFailedException) &&
              url.startsWith('https')) {
            _log.fine('Certificate error whilst fetching podcast. Fallback to http and try again');

            url = url.replaceFirst('https', 'http');
          } else if (e is podcast_search.PodcastNotChangedException) {
            /// The podcast has not been updated since we last checked, just return the stored copy.
            _log.fine('This podcast has not updated since we last checked.');

            final storedPodcast = await repository.findPodcastById(podcast.id!);

            // Just update the last updated value.
            if (storedPodcast != null) {
              save(storedPodcast, withEpisodes: false);
            }

            return storedPodcast;
          } else {
            _log.fine('Failed to load podcast.  $tries attempts remaining.');
            _log.fine(e);
          }
        } else {
          rethrow;
        }
      }
    }

    if (loadedPodcast == null) return null;

    final funding = <Funding>[];
    final persons = <Person>[];
    final existingEpisodes = await repository.findEpisodesByPodcastGuid(sourceUrl);

    // If imageUrl is null we have not loaded the podcast as a result of a search.
    if (imageUrl == null || imageUrl.isEmpty || ignoreCache) {
      imageUrl = loadedPodcast.image;
      thumbImageUrl = loadedPodcast.image;
    }

    for (var f in loadedPodcast.funding) {
      if (f.url != null) {
        funding.add(Funding(url: f.url!, value: f.value ?? ''));
      }
    }

    for (var p in loadedPodcast.persons) {
      persons.add(Person(
        name: p.name,
        role: p.role ?? '',
        group: p.group ?? '',
        image: p.image ?? '',
        link: p.link ?? '',
      ));
    }

    Podcast pc = Podcast(
      guid: sourceUrl,
      url: sourceUrl,
      link: loadedPodcast.link,
      etag: loadedPodcast.etag,
      title: _format(loadedPodcast.title),
      description: _format(loadedPodcast.description),
      imageUrl: imageUrl,
      thumbImageUrl: thumbImageUrl,
      copyright: _format(loadedPodcast.copyright),
      rssFeedLastUpdated: loadedPodcast.dateTimeModified,
      funding: funding,
      persons: persons,
      episodes: <Episode>[],
    );

    print('Got etag ${loadedPodcast.etag} for ${loadedPodcast.title}');

    /// We could be following this podcast already. Let's check.
    var follow = await repository.findPodcastByGuid(sourceUrl);

    if (follow != null) {
      // We are, so swap in the stored ID so we update the saved version later.
      pc.id = follow.id;

      // And preserve any filter & sort applied
      pc.filter = follow.filter;
      pc.sort = follow.sort;
    }

    // Usually, episodes are order by reverse publication date - but not always.
    // Enforce that ordering. To prevent unnecessary sorting, we'll sample the
    // first two episodes to see what order they are in.
    if (loadedPodcast.episodes.length > 1) {
      if (loadedPodcast.episodes[0].publicationDate!.millisecondsSinceEpoch <
          loadedPodcast.episodes[1].publicationDate!.millisecondsSinceEpoch) {
        loadedPodcast.episodes.sort((e1, e2) => e2.publicationDate!.compareTo(e1.publicationDate!));
      }
    }

    // Loop through all episodes in the feed and check to see if we already have that episode
    // stored. If we don't, it's a new episode so add it; if we do update our copy in case it's changed.
    for (final episode in loadedPodcast.episodes) {
      final existingEpisode = existingEpisodes.firstWhereOrNull((ep) => ep.guid == episode.guid);
      final author = episode.author?.replaceAll('\n', '').trim() ?? '';
      final title = _format(episode.title);
      final description = _format(episode.description);
      final content = episode.content;

      final episodeImage = episode.imageUrl == null || episode.imageUrl!.isEmpty ? pc.imageUrl : episode.imageUrl;
      final episodeThumbImage =
          episode.imageUrl == null || episode.imageUrl!.isEmpty ? pc.thumbImageUrl : episode.imageUrl;
      final duration = episode.duration?.inSeconds ?? 0;
      final transcriptUrls = <TranscriptUrl>[];
      final episodePersons = <Person>[];

      for (var t in episode.transcripts) {
        late TranscriptFormat type;

        switch (t.type) {
          case podcast_search.TranscriptFormat.subrip:
            type = TranscriptFormat.subrip;
            break;
          case podcast_search.TranscriptFormat.json:
            type = TranscriptFormat.json;
            break;
          case podcast_search.TranscriptFormat.vtt:
            type = TranscriptFormat.vtt;
            break;
          case podcast_search.TranscriptFormat.unsupported:
            type = TranscriptFormat.unsupported;
            break;
        }

        transcriptUrls.add(TranscriptUrl(url: t.url, type: type));
      }

      if (episode.persons.isNotEmpty) {
        for (var p in episode.persons) {
          episodePersons.add(Person(
            name: p.name,
            role: p.role ?? '',
            group: p.group ?? '',
            image: p.image ?? '',
            link: p.link ?? '',
          ));
        }
      } else if (persons.isNotEmpty) {
        episodePersons.addAll(persons);
      }

      /// Store the latest episode date against the podcast for later sorting.
      if (episode.publicationDate != null && episode.publicationDate!.isAfter(pc.latestEpisodeDate)) {
        pc.latestEpisodeDate = episode.publicationDate;
      }

      if (existingEpisode == null) {
        if (highlightNewEpisodes && pc.id != null) {
          pc.newEpisodes++;
        }

        pc.episodes.add(Episode(
          highlight: pc.newEpisodes > 0,
          pguid: pc.guid,
          guid: episode.guid,
          podcast: pc.title,
          title: title,
          description: description,
          content: content,
          author: author,
          season: episode.season ?? 0,
          episode: episode.episode ?? 0,
          contentUrl: episode.contentUrl,
          link: episode.link,
          imageUrl: episodeImage,
          thumbImageUrl: episodeThumbImage,
          duration: duration,
          length: episode.length,
          mimeType: episode.mimeType,
          publicationDate: episode.publicationDate,
          chaptersUrl: episode.chapters?.url,
          transcriptUrls: transcriptUrls,
          persons: episodePersons,
          chapters: <Chapter>[],
        ));
      } else {
        /// Check if the ancillary episode data has changed.
        if (!listEquals(existingEpisode.persons, episodePersons) ||
            !listEquals(existingEpisode.transcriptUrls, transcriptUrls)) {
          pc.updatedEpisodes = true;
        }

        existingEpisode.title = title;
        existingEpisode.description = description;
        existingEpisode.content = content;
        existingEpisode.author = author;
        existingEpisode.season = episode.season ?? 0;
        existingEpisode.episode = episode.episode ?? 0;
        existingEpisode.contentUrl = episode.contentUrl;
        existingEpisode.length = episode.length;
        existingEpisode.mimeType = episode.mimeType;
        existingEpisode.link = episode.link;
        existingEpisode.imageUrl = episodeImage;
        existingEpisode.thumbImageUrl = episodeThumbImage;
        existingEpisode.publicationDate = episode.publicationDate;
        existingEpisode.chaptersUrl = episode.chapters?.url;
        existingEpisode.transcriptUrls = transcriptUrls;
        existingEpisode.persons = episodePersons;

        // If the source duration is 0 do not update any saved, calculated duration.
        if (duration > 0) {
          existingEpisode.duration = duration;
        }

        pc.episodes.add(existingEpisode);

        // Clear this episode from our existing list
        existingEpisodes.remove(existingEpisode);
      }
    }

    // Add any downloaded episodes that are no longer in the feed - they
    // may have expired but we still want them.
    var expired = <Episode>[];

    for (final episode in existingEpisodes) {
      var feedEpisode = loadedPodcast.episodes.firstWhereOrNull((ep) => ep.guid == episode.guid);

      if (feedEpisode == null && episode.downloaded) {
        pc.episodes.add(episode);
      } else {
        expired.add(episode);
      }
    }

    // If we are subscribed to this podcast and are simply refreshing we need to save the updated subscription.
    // A non-null ID indicates this podcast is subscribed too. We also need to delete any expired episodes.
    if (podcast.id != null) {
      await repository.deleteEpisodes(expired);

      pc = await repository.savePodcast(pc);

      // Phew! Now, after all that, we have have a podcast filter in place. All episodes will have
      // been saved, but we might not want to display them all. Let's filter.
      pc.episodes = _sortAndFilterEpisodes(pc);
    }

    // All done, now cache the podcast in case we need to fetch this again shortly.
    _cache.store(pc);

    return pc;
  }

  @override
  Future<Podcast?> loadPodcastById({required int id}) {
    return repository.findPodcastById(id);
  }

  @override
  Future<List<Chapter>> loadChaptersByUrl({required String url}) async {
    var c = await _loadChaptersByUrl(url);
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

  /// This method will load either of the supported transcript types. Currently, we do not support
  /// word level highlighting of transcripts, therefore this routine will also group transcript
  /// lines together by speaker and/or timeframe.
  @override
  Future<Transcript> loadTranscriptByUrl({required TranscriptUrl transcriptUrl}) async {
    var subtitles = <Subtitle>[];
    var result = await _loadTranscriptByUrl(transcriptUrl);
    var threshold = const Duration(seconds: 5);
    Subtitle? groupSubtitle;

    if (result != null) {
      for (var index = 0; index < result.subtitles.length; index++) {
        var subtitle = result.subtitles[index];
        var completeGroup = true;
        var data = subtitle.data;

        if (groupSubtitle != null) {
          if (transcriptUrl.type == TranscriptFormat.json) {
            if (groupSubtitle.speaker == subtitle.speaker &&
                (subtitle.start.compareTo(groupSubtitle.start + threshold) < 0 || subtitle.data.length == 1)) {
              /// We need to handle transcripts that have spaces between sentences, and those
              /// which do not.
              if (groupSubtitle.data != null &&
                  (groupSubtitle.data!.endsWith(' ') || subtitle.data.startsWith(' ') || subtitle.data.length == 1)) {
                data = '${groupSubtitle.data}${subtitle.data}';
              } else {
                data = '${groupSubtitle.data} ${subtitle.data.trim()}';
              }
              completeGroup = false;
            }
          } else {
            if (groupSubtitle.start == subtitle.start) {
              if (groupSubtitle.data != null &&
                  (groupSubtitle.data!.endsWith(' ') || subtitle.data.startsWith(' ') || subtitle.data.length == 1)) {
                data = '${groupSubtitle.data}${subtitle.data}';
              } else {
                data = '${groupSubtitle.data} ${subtitle.data.trim()}';
              }
              completeGroup = false;
            }
          }
        } else {
          completeGroup = false;
          groupSubtitle = Subtitle(
            data: subtitle.data,
            speaker: subtitle.speaker,
            start: subtitle.start,
            end: subtitle.end,
            index: subtitle.index,
          );
        }

        /// If we have a complete group, or we're the very last subtitle - add it.
        if (completeGroup || index == result.subtitles.length - 1) {
          groupSubtitle.data = groupSubtitle.data?.trim();

          subtitles.add(groupSubtitle);

          groupSubtitle = Subtitle(
            data: subtitle.data,
            speaker: subtitle.speaker,
            start: subtitle.start,
            end: subtitle.end,
            index: subtitle.index,
          );
        } else {
          groupSubtitle = Subtitle(
            data: data,
            speaker: subtitle.speaker,
            start: groupSubtitle.start,
            end: subtitle.end,
            index: groupSubtitle.index,
          );
        }
      }
    }

    return Transcript(subtitles: subtitles);
  }

  @override
  Future<List<Episode>> loadDownloads() async {
    return repository.findDownloads();
  }

  @override
  Future<List<Episode>> loadEpisodes() async {
    return repository.findAllEpisodes();
  }

  @override
  Future<void> deleteDownload(Episode episode) async {
    // If this episode is currently downloading, cancel the download first.
    if (episode.downloadState == DownloadState.downloaded) {
      if (settingsService.markDeletedEpisodesAsPlayed) {
        episode.played = true;
      }
    } else if (episode.downloadState == DownloadState.downloading && episode.downloadPercentage! < 100) {
      await FlutterDownloader.cancel(taskId: episode.downloadTaskId!);
    }

    episode.downloadTaskId = null;
    episode.downloadPercentage = 0;
    episode.position = 0;
    episode.downloadState = DownloadState.none;

    if (episode.transcriptId != null && episode.transcriptId! > 0) {
      await repository.deleteTranscriptById(episode.transcriptId!);
    }

    await repository.saveEpisode(episode);

    final f = File.fromUri(Uri.file(await resolvePath(episode)));

    _log.fine('Deleting file ${f.path}');

    if (await f.exists()) {
      f.delete();
    }

    return;
  }

  @override
  Future<void> toggleEpisodePlayed(Episode episode) async {
    episode.played = !episode.played;
    episode.position = 0;

    repository.saveEpisode(episode);
  }

  @override
  Future<List<Podcast>> subscriptions() async {
    final subs = await repository.subscriptions();
    final orderBy = settingsService.layoutOrder;
    final unreadMap = await repository.findEpisodeCountByPodcast(filter: PodcastEpisodeFilter.notPlayed);

    for (var s in subs.where((p) => p.id != null)) {
      s.episodeCount = unreadMap[s.guid] ?? 0;
    }

    // Now order the subs
    switch (orderBy) {
      case 'alphabetical':
        subs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'followed':
        subs.sort((a, b) => a.subscribedDate!.compareTo(b.subscribedDate!));
        break;
      case 'unplayed':
        subs.sort((a, b) => b.episodeCount.compareTo(a.episodeCount));
        break;
      case 'episodes':
        subs.sort((a, b) => b.latestEpisodeDate.compareTo(a.latestEpisodeDate));
        break;
    }

    return subs;
  }

  @override
  Future<void> unsubscribe(Podcast podcast) async {
    final filename = join(await getStorageDirectory(), safeFile(podcast.title));

    final d = Directory.fromUri(Uri.file(filename));

    if (await d.exists()) {
      await d.delete(recursive: true);
    }

    /// Remove the podcast from the cache if it exists
    _cache.remove(podcast);

    return repository.deletePodcast(podcast);
  }

  @override
  Future<Podcast?> subscribe(Podcast? podcast) async {
    // We may already have episodes download for this podcast before the user
    // hit subscribe.
    if (podcast != null && podcast.guid != null) {
      var savedEpisodes = await repository.findEpisodesByPodcastGuid(podcast.guid!);

      if (podcast.episodes.isNotEmpty) {
        for (var episode in podcast.episodes) {
          var savedEpisode = savedEpisodes.firstWhereOrNull((ep) => ep.guid == episode.guid);

          if (savedEpisode != null) {
            episode.pguid = podcast.guid;
          }
        }
      }

      return repository.savePodcast(podcast);
    }

    return Future.value(null);
  }

  @override
  Future<Podcast?> save(Podcast podcast, {bool withEpisodes = true}) async {
    return repository.savePodcast(podcast, withEpisodes: withEpisodes);
  }

  @override
  Future<Episode> saveEpisode(Episode episode) async {
    return repository.saveEpisode(episode);
  }

  @override
  Future<List<Episode>> saveEpisodes(List<Episode> episodes) async {
    return repository.saveEpisodes(episodes);
  }

  @override
  Future<Transcript> saveTranscript(Transcript transcript) async {
    return repository.saveTranscript(transcript);
  }

  @override
  Future<void> saveQueue(List<Episode> episodes) async {
    await repository.saveQueue(episodes);
  }

  @override
  Future<List<Episode>> loadQueue() async {
    return await repository.loadQueue();
  }

  // TODO: Handle feed update timeout and using up all available fetch time.
  @override
  Future<void> refreshFeeds({bool manual = false, background = false}) async {
    if (_lock.inLock) {
      _log.fine('We are already refreshing feeds and currently locked. Sorry about that!');
      return;
    }

    /// If set to never, do not bother to continue
    if (settingsService.autoUpdateEpisodePeriod == -1) {
      _log.fine('Automatic library refresh is disabled.');
      return;
    }

    await _lock.synchronized(() async {
      // Are we due an update yet?
      final lastUpdate = settingsService.lastFeedRefresh;
      final feedPeriod = settingsService.autoUpdateEpisodePeriod;
      final updateDue = lastUpdate.add(Duration(minutes: feedPeriod));
      final canRun = (settingsService.backgroundUpdate && background) || !background;

      /// If we have triggered a manual refresh, or we are running in the background and have background update
      /// on, or we're running in the foreground.
      if (manual || (canRun && DateTime.now().isAfter(updateDue))) {
        // Check we have network
        var connectivityResult = await Connectivity().checkConnectivity();
        var connectivity = !connectivityResult.contains(ConnectivityResult.none);
        var allowConnectivity = connectivityResult.contains(ConnectivityResult.wifi) ||
            (settingsService.backgroundUpdateMobileData && connectivityResult.contains(ConnectivityResult.mobile));

        // If we have connectivity and we're either on wifi or we allow mobile data, continue.
        if (connectivity && allowConnectivity) {
          bool newOrUpdatedEpisodes = false;

          _libraryState.add(LibraryRefreshingState());

          /// According to iOS docs, we have up to 30 seconds. We'll limit it to 20 to be sure:
          /// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:performfetchwithcompletionhandler:)?language=objc
          final timeout = manual ? const Duration(seconds: 30) : const Duration(seconds: 20);

          _log.fine('Feed update triggered. We have ${timeout.inSeconds} seconds to get stuff done!');

          if (settingsService.updateNotification) {
            notificationService.isAllowed().then((isAllowed) {
              notificationService.createRefreshNotification();
            });
          }

          final startTime = DateTime.now();
          final subs = await subscriptions();

          /// Sort by last updated ASC - we will improve this in time.
          subs.sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));

          for (var sub in subs) {
            _log.fine('Loading ${sub.title}');

            try {
              final p = await loadPodcast(podcast: sub, ignoreCache: true, highlightNewEpisodes: true);

              if (p != null) {
                if (p.newEpisodes > 0 || p.updatedEpisodes) {
                  newOrUpdatedEpisodes = true;
                }
              }
            } catch (e) {
              _log.warning('Failed to load podcast ${sub.title}. Will try again on next run');
            }

            // Do we have any time left?
            final endTime = DateTime.now();
            final milliDiff = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;

            if (milliDiff >= timeout.inMilliseconds) {
              _log.fine('We are out of time. Update stopping.');
              break;
            }
          }

          if (settingsService.updateNotification) {
            notificationService.isAllowed().then((isAllowed) {
              notificationService.clearRefreshNotification();
            });
          }

          if (newOrUpdatedEpisodes) {
            _libraryState.add(LibraryUpdatedState());
          }

          _libraryState.add(LibraryReadyState());
          settingsService.lastFeedRefresh = DateTime.now();
        } else {
          _log.fine('We do not have suitable connectivity available. Skipping update:');
          _log.fine(
              ' - Connectivity: ${!connectivityResult.contains(ConnectivityResult.none)}, Wifi: WIFI: ${connectivityResult.contains(ConnectivityResult.wifi)}, Mobile: ${connectivityResult.contains(ConnectivityResult.mobile)}');
        }
      } else {
        _log.fine('Feed update not due until $updateDue');
      }
    });
  }

  /// Remove HTML padding from the content. The padding may look fine within
  /// the context of a browser, but can look out of place on a mobile screen.
  String _format(String? input) {
    return input?.trim().replaceAll(_descriptionRegExp2, '').replaceAll(_descriptionRegExp1, '</p>') ?? '';
  }

  Future<podcast_search.Chapters?> _loadChaptersByUrl(String url) {
    return compute<_FeedComputer, podcast_search.Chapters?>(
        _loadChaptersByUrlCompute, _FeedComputer(api: api, url: url));
  }

  static Future<podcast_search.Chapters?> _loadChaptersByUrlCompute(_FeedComputer c) async {
    podcast_search.Chapters? result;

    try {
      result = await c.api.loadChapters(c.url);
    } catch (e) {
      final log = Logger('MobilePodcastService');

      log.fine('Failed to download chapters');
      log.fine(e);
    }

    return result;
  }

  Future<podcast_search.Transcript?> _loadTranscriptByUrl(TranscriptUrl transcriptUrl) {
    return compute<_TranscriptComputer, podcast_search.Transcript?>(
        _loadTranscriptByUrlCompute, _TranscriptComputer(api: api, transcriptUrl: transcriptUrl));
  }

  static Future<podcast_search.Transcript?> _loadTranscriptByUrlCompute(_TranscriptComputer c) async {
    podcast_search.Transcript? result;

    try {
      result = await c.api.loadTranscript(c.transcriptUrl);
    } catch (e) {
      final log = Logger('MobilePodcastService');

      log.fine('Failed to download transcript');
      log.fine(e);
    }

    return result;
  }

  /// Loading and parsing a podcast feed can take several seconds. Larger feeds
  /// can end up blocking the UI thread. We perform our feed load in a
  /// separate isolate so that the UI can continue to present a loading
  /// indicator whilst the data is fetched without locking the UI.
  Future<podcast_search.Podcast> _loadPodcastFeed({required String url, required String etag}) {
    return compute<_FeedComputer, podcast_search.Podcast>(
        _loadPodcastFeedCompute, _FeedComputer(api: api, url: url, etag: etag));
  }

  /// We have to separate the process of calling compute as you cannot use
  /// named parameters with compute. The podcast feed load API uses named
  /// parameters so we need to change it to a single, positional parameter.
  static Future<podcast_search.Podcast> _loadPodcastFeedCompute(_FeedComputer c) {
    return c.api.loadFeed(c.url, c.etag);
  }

  /// The service providers expect the genre to be passed in English. This function takes
  /// the selected genre and returns the English version.
  String _decodeGenre(String? genre) {
    var index = _intlCategories.indexOf(genre);
    var decodedGenre = '';

    if (index >= 0) {
      decodedGenre = _categories[index];

      if (decodedGenre == '<All>') {
        decodedGenre = '';
      }
    }

    return decodedGenre;
  }

  List<Episode> _sortAndFilterEpisodes(Podcast podcast) {
    var filteredEpisodes = <Episode>[];

    switch (podcast.filter) {
      case PodcastEpisodeFilter.none:
        filteredEpisodes = podcast.episodes;
        break;
      case PodcastEpisodeFilter.started:
        filteredEpisodes = podcast.episodes.where((e) => e.highlight || e.position > 0).toList();
        break;
      case PodcastEpisodeFilter.played:
        filteredEpisodes = podcast.episodes.where((e) => e.highlight || e.played).toList();
        break;
      case PodcastEpisodeFilter.notPlayed:
        filteredEpisodes = podcast.episodes.where((e) => e.highlight || !e.played).toList();
        break;
    }

    switch (podcast.sort) {
      case PodcastEpisodeSort.none:
      case PodcastEpisodeSort.latestFirst:
        filteredEpisodes.sort((e1, e2) => e2.publicationDate!.compareTo(e1.publicationDate!));
      case PodcastEpisodeSort.earliestFirst:
        filteredEpisodes.sort((e1, e2) => e1.publicationDate!.compareTo(e2.publicationDate!));
      case PodcastEpisodeSort.alphabeticalAscending:
        filteredEpisodes.sort((e1, e2) => e1.title!.toLowerCase().compareTo(e2.title!.toLowerCase()));
      case PodcastEpisodeSort.alphabeticalDescending:
        filteredEpisodes.sort((e1, e2) => e2.title!.toLowerCase().compareTo(e1.title!.toLowerCase()));
    }

    return filteredEpisodes;
  }

  // TODO: Set correct fetch internal - defined in settings.
  Future<void> initBackgroundFetch() async {
    if (Platform.isIOS || Platform.isAndroid) {
      _log.info('Setting up background fetch for $defaultTargetPlatform');

      // Configure BackgroundFetch.
      int status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: kDebugMode ? 15 : 60,
              stopOnTerminate: true,
              enableHeadless: false,
              requiresBatteryNotLow: true,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.ANY), (String taskId) async {
        _log.fine("Background event received $taskId");

        refreshFeeds(background: true).then((_) {
          BackgroundFetch.finish(taskId);
        });
      }, (String taskId) async {
        _log.fine("Task timed out - taskId: $taskId");

        BackgroundFetch.finish(taskId);
      });
      _log.fine('Background library update configured: $status');
    } else {
      _log.fine('Skipping setup of background fetch as it is not supported on this platform');
    }
  }

  @override
  Stream<Podcast?> get podcastListener => repository.podcastListener;

  @override
  Stream<EpisodeState> get episodeListener => repository.episodeListener;

  @override
  Stream<LibraryState> get libraryListener => _libraryState.stream;
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

  _PodcastCache({required this.maxItems, required this.expiration}) : _queue = Queue<_CacheItem>();

  Podcast? item(String key) {
    var hit = _queue.firstWhereOrNull((_CacheItem i) => i.podcast.url == key);
    Podcast? p;

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

  void store(Podcast podcast) {
    if (_queue.length == maxItems) {
      _queue.removeFirst();
    }

    _queue.addLast(_CacheItem(podcast));
  }

  void remove(Podcast podcast) {
    _queue.removeWhere((_CacheItem i) => i.podcast.url == podcast.url);
  }
}

/// A simple class that stores an instance of a Podcast and the
/// date and time it was added. This can be used by the cache to
/// keep a small and up-to-date list of searched for Podcasts.
class _CacheItem {
  final Podcast podcast;
  final DateTime dateAdded;

  _CacheItem(this.podcast) : dateAdded = DateTime.now();
}

class _FeedComputer {
  final PodcastApi api;
  final String url;
  final String etag;

  _FeedComputer({
    required this.api,
    required this.url,
    this.etag = '',
  });
}

class _TranscriptComputer {
  final PodcastApi api;
  final TranscriptUrl transcriptUrl;

  _TranscriptComputer({required this.api, required this.transcriptUrl});
}
