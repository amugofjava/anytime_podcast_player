// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/search_providers.dart';
import 'package:flutter/foundation.dart';

class AppSettings {
  final String theme;
  final bool markDeletedEpisodesAsPlayed;
  final bool storeDownloadsSDCard;
  final double playbackSpeed;
  final String searchProvider;
  final List<SearchProvider> searchProviders;
  final bool externalLinkConsent;
  final bool autoOpenNowPlaying;
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
