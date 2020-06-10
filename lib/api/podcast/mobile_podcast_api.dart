// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/api/podcast/podcast_api.dart';
import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

/// An implementation of the PodcastApi. A simple wrapper class that
/// interacts with the iTunes search API via the podcast_search package.
class MobilePodcastApi extends PodcastApi {
  final Search api = Search();

  @override
  Future<SearchResult> search(String term,
      {String country, String attribute, int limit, String language, int version = 0, bool explicit = false}) async {
    return compute(_search, term);
  }

  @override
  Future<SearchResult> charts(
    int size,
  ) async {
    return compute(_charts, 0);
  }

  static Future<SearchResult> _search(String term) {
    return Search().search(term).timeout(Duration(seconds: 10));
  }

  static Future<SearchResult> _charts(int size) {
    return Search().charts().timeout(Duration(seconds: 10));
  }
}
