// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/api/podcast/mobile_podcast_api.dart';
import 'package:podcast_search/podcast_search.dart';

/// This Mock version of the Podcast API replaces loading via URL
/// with loading via local file. This allows use to test API
/// loading without requiring an Internet connection.
class MockPodcastApi extends MobilePodcastApi {
  @override
  Future<Podcast> loadFeed(String? url) async {
    return _loadFeed(url!);
  }

  Future<Podcast> _loadFeed(String url) {
    return Podcast.loadFeedFile(file: url);
  }
}
