// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/funding.dart';
import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart' as search;

import 'episode.dart';

/// A class that represents an instance of a podcast. When persisted to disk
/// this represents a podcast that is being followed.
class Podcast {
  /// Database ID
  int id;

  /// Unique identifier for podcast.
  final String guid;

  /// The link to the podcast RSS feed.
  final String url;

  /// RSS link URL.
  final String link;

  /// Podcast title.
  final String title;

  /// Podcast description. Can be either plain text or HTML.
  final String description;

  /// URL to the full size artwork image.
  final String imageUrl;

  /// URL for thumbnail version of artwork image. Not contained within
  /// the RSS but may be calculated or provided within search results.
  final String thumbImageUrl;

  /// Copyright owner of the podcast.
  final String copyright;

  /// Zero or more funding links.
  final List<Funding> funding;

  /// Date and time user subscribed to the podcast.
  DateTime subscribedDate;

  /// Date and time podcast was last updated/refreshed.
  DateTime _lastUpdated;

  /// One or more episodes for this podcast.
  List<Episode> episodes;

  bool newEpisodes;

  Podcast({
    @required this.guid,
    @required this.url,
    @required this.link,
    @required this.title,
    this.id,
    this.description,
    this.imageUrl,
    this.thumbImageUrl,
    this.copyright,
    this.subscribedDate,
    this.funding,
    this.episodes,
    this.newEpisodes = false,
    DateTime lastUpdated,
  }) {
    _lastUpdated = lastUpdated;
    episodes ??= [];
  }

  Podcast.fromUrl({@required String url})
      : guid = '',
        link = '',
        title = '',
        description = '',
        thumbImageUrl = null,
        imageUrl = null,
        copyright = '',
        funding = <Funding>[],
        url = url;

  Podcast.fromSearchResultItem(search.Item item)
      : guid = item.guid,
        url = item.feedUrl,
        link = item.feedUrl,
        title = item.trackName,
        description = '',
        imageUrl = item.bestArtworkUrl ?? item.artworkUrl,
        thumbImageUrl = item.thumbnailArtworkUrl,
        funding = const <Funding>[],
        copyright = item.artistName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'title': title ?? '',
      'copyright': copyright ?? '',
      'description': description ?? '',
      'url': url,
      'imageUrl': imageUrl ?? '',
      'thumbImageUrl': thumbImageUrl ?? '',
      'subscribedDate': subscribedDate?.millisecondsSinceEpoch.toString() ?? '',
      'funding': (funding ?? <Funding>[]).map((funding) => funding.toMap())?.toList(growable: false),
      'lastUpdated': _lastUpdated?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Podcast fromMap(int key, Map<String, dynamic> podcast) {
    final sds = podcast['subscribedDate'] as String;
    final lus = podcast['lastUpdated'] as int;
    final funding = <Funding>[];

    var sd = DateTime.now();
    var lastUpdated = DateTime(1971, 1, 1);

    if (sds != null && sds.isNotEmpty && int.tryParse(sds) != null) {
      sd = DateTime.fromMillisecondsSinceEpoch(int.parse(sds));
    }

    if (lus != null) {
      lastUpdated = DateTime.fromMillisecondsSinceEpoch(lus);
    }

    if (podcast['funding'] != null) {
      for (var chapter in (podcast['funding'] as List)) {
        if (chapter is Map<String, dynamic>) {
          funding.add(Funding.fromMap(chapter));
        }
      }
    }

    return Podcast(
      id: key,
      guid: podcast['guid'] as String,
      link: podcast['link'] as String,
      title: podcast['title'] as String,
      copyright: podcast['copyright'] as String,
      description: podcast['description'] as String,
      url: podcast['url'] as String,
      imageUrl: podcast['imageUrl'] as String,
      thumbImageUrl: podcast['thumbImageUrl'] as String,
      funding: funding,
      subscribedDate: sd,
      lastUpdated: lastUpdated,
    );
  }

  bool get subscribed => id != null;

  DateTime get lastUpdated => _lastUpdated ?? DateTime(1970, 1, 1);

  set lastUpdated(DateTime value) {
    _lastUpdated = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Podcast && runtimeType == other.runtimeType && guid == other.guid && url == other.url;

  @override
  int get hashCode => guid.hashCode ^ url.hashCode;
}
