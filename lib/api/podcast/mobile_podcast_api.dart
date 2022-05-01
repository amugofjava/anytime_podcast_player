// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/api/podcast/podcast_api.dart';
import 'package:anytime/core/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

/// An implementation of the PodcastApi. A simple wrapper class that
/// interacts with the iTunes/Podcastindex search API via the
/// podcast_search package.
class MobilePodcastApi extends PodcastApi {
  SecurityContext _defaultSecurityContext;
  List<int> _certificateAuthorityBytes = [];

  @override
  Future<SearchResult> search(
    String term, {
    String country,
    String attribute,
    int limit,
    String language,
    int version = 0,
    bool explicit = false,
    String searchProvider,
  }) async {
    var searchParams = {
      'term': term,
      'searchProvider': searchProvider,
    };

    return compute(_search, searchParams);
  }

  @override
  Future<SearchResult> charts({
    int size = 20,
    String genre,
    String searchProvider,
  }) async {
    var searchParams = {
      'size': size.toString(),
      'genre': genre,
      'searchProvider': searchProvider,
    };

    return compute(_charts, searchParams);
  }

  @override
  List<String> genres(String searchProvider) {
    var provider = searchProvider == 'itunes'
        ? ITunesProvider()
        : PodcastIndexProvider(
            key: podcastIndexKey,
            secret: podcastIndexSecret,
          );

    return Search(
      userAgent: Environment.userAgent(),
      searchProvider: provider,
    ).genres();
  }

  @override
  Future<Podcast> loadFeed(String url) async {
    return _loadFeed(url);
  }

  @override
  Future<Chapters> loadChapters(String url) async {
    return Podcast.loadChaptersByUrl(url: url);
  }

  static Future<SearchResult> _search(Map<String, String> searchParams) {
    var term = searchParams['term'];
    var provider = searchParams['searchProvider'] == 'itunes'
        ? ITunesProvider()
        : PodcastIndexProvider(
            key: podcastIndexKey,
            secret: podcastIndexSecret,
          );

    return Search(
      userAgent: Environment.userAgent(),
      searchProvider: provider,
    ).search(term).timeout(Duration(seconds: 30));
  }

  static Future<SearchResult> _charts(Map<String, String> searchParams) {
    var provider = searchParams['searchProvider'] == 'itunes'
        ? ITunesProvider()
        : PodcastIndexProvider(
            key: podcastIndexKey,
            secret: podcastIndexSecret,
          );

    return Search(userAgent: Environment.userAgent(), searchProvider: provider)
        .charts(genre: searchParams['genre'])
        .timeout(Duration(seconds: 30));
  }

  Future<Podcast> _loadFeed(String url) {
    _setupSecurityContext();
    return Podcast.loadFeed(url: url, userAgent: Environment.userAgent());
  }

  void _setupSecurityContext() {
    if (_certificateAuthorityBytes.isNotEmpty &&
        _defaultSecurityContext == null) {
      SecurityContext.defaultContext
          .setTrustedCertificatesBytes(_certificateAuthorityBytes);
      _defaultSecurityContext = SecurityContext.defaultContext;
    }
  }

  @override
  void addClientAuthorityBytes(List<int> certificateAuthorityBytes) {
    _certificateAuthorityBytes = certificateAuthorityBytes;
  }
}
