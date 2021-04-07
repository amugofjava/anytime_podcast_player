// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/search_providers.dart';
import 'package:flutter/foundation.dart';

class AppSettings {
  /// The current theme name.
  final String theme;

  /// True if episodes are marked as played when deleted.
  final bool markDeletedEpisodesAsPlayed;

  /// True if downloads should be saved to the SD card.
  final bool storeDownloadsSDCard;

  /// The default playback speed.
  final double playbackSpeed;

  /// The search provider: itunes or podcastindex.
  final String searchProvider;

  /// List of search providers: currently itunes or podcastindex.
  final List<SearchProvider> searchProviders;

  /// True if the user has confirmed dialog accepting funding links.
  final bool externalLinkConsent;

  /// If true the main player window will open as soon as an episode starts.
  final bool autoOpenNowPlaying;

  /// If true the funding link icon will appear (if the podcast supports it).
  final bool showFunding;

  AppSettings({
    @required this.theme,
    @required this.markDeletedEpisodesAsPlayed,
    @required this.storeDownloadsSDCard,
    @required this.playbackSpeed,
    @required this.searchProvider,
    @required this.searchProviders,
    @required this.externalLinkConsent,
    @required this.autoOpenNowPlaying,
    @required this.showFunding,
  });

  AppSettings.sensibleDefaults()
      : theme = 'dark',
        markDeletedEpisodesAsPlayed = false,
        storeDownloadsSDCard = false,
        playbackSpeed = 1.0,
        searchProvider = 'itunes',
        searchProviders = <SearchProvider>[],
        externalLinkConsent = false,
        autoOpenNowPlaying = false,
        showFunding = true;
}
