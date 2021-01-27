// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

class AppSettings {
  final String theme;
  final bool markDeletedEpisodesAsPlayed;
  final bool storeDownloadsSDCard;
  final double playbackSpeed;
  final bool autoOpenNowPlaying;

  AppSettings({
    @required this.theme,
    @required this.markDeletedEpisodesAsPlayed,
    @required this.storeDownloadsSDCard,
    @required this.playbackSpeed,
    @required this.autoOpenNowPlaying,
  });

  AppSettings.sensibleDefaults()
      : theme = 'dark',
        markDeletedEpisodesAsPlayed = false,
        storeDownloadsSDCard = false,
        playbackSpeed = 1.0,
        autoOpenNowPlaying = false;
}
