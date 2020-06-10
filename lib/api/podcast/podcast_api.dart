// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:podcast_search/podcast_search.dart';

/// A simple wrapper class that interacts with the iTunes search API via
/// the podcast_search package.
abstract class PodcastApi {
  /// Search iTunes for podcasts matching the search criteria. Returns a
  /// [SearchResult] instance.
  Future<SearchResult> search(
    String term, {
    String country,
    String attribute,
    int limit,
    String language,
    int version = 0,
    bool explicit = false,
  });

  /// Request the top podcast charts from iTunes, and at most [size] records.
  Future<SearchResult> charts(int size);
}
