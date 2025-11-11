// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MockSettingsService extends SettingsService {
  @override
  bool autoOpenNowPlaying = false;

  @override
  int autoUpdateEpisodePeriod = 1;

  @override
  bool externalLinkConsent = false;

  @override
  int layoutMode = 1;

  @override
  String layoutOrder = 'followed';

  @override
  bool layoutHighlight = false;

  @override
  bool layoutCount = false;

  @override
  bool markDeletedEpisodesAsPlayed = false;

  @override
  bool deleteDownloadedPlayedEpisodes = false;

  @override
  double playbackSpeed = 1;

  @override
  String searchProvider = 'itunes';

  @override
  AppSettings? settings;

  @override
  bool showFunding = true;

  @override
  bool storeDownloadsSDCard = false;

  @override
  String theme = ThemeMode.dark.name;

  @override
  bool trimSilence = false;

  @override
  bool volumeBoost = false;

  @override
  bool autoPlay = false;

  @override
  bool backgroundUpdate = false;

  @override
  bool backgroundUpdateMobileData = false;

  @override
  bool updateNotification = false;

  @override
  DateTime lastFeedRefresh = DateTime.utc(1970, 1, 1);

  @override
  Stream<String> get settingsListener => PublishSubject<String>().stream;
}
