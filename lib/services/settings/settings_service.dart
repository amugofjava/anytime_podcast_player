// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/app_settings.dart';

abstract class SettingsService {
  AppSettings? get settings;

  set settings(AppSettings? settings);

  String get theme;

  set theme(String mode);

  bool get markDeletedEpisodesAsPlayed;

  set markDeletedEpisodesAsPlayed(bool value);

  bool get deleteDownloadedPlayedEpisodes;

  set deleteDownloadedPlayedEpisodes(bool value);

  bool get storeDownloadsSDCard;

  set storeDownloadsSDCard(bool value);

  set playbackSpeed(double playbackSpeed);

  double get playbackSpeed;

  set searchProvider(String provider);

  String get searchProvider;

  set externalLinkConsent(bool consent);

  bool get externalLinkConsent;

  set autoOpenNowPlaying(bool autoOpenNowPlaying);

  bool get autoOpenNowPlaying;

  set showFunding(bool show);

  bool get showFunding;

  set autoUpdateEpisodePeriod(int period);

  int get autoUpdateEpisodePeriod;

  set trimSilence(bool trim);

  bool get trimSilence;

  set volumeBoost(bool boost);

  bool get volumeBoost;

  set layoutMode(int mode);

  int get layoutMode;

  set layoutOrder(String order);

  String get layoutOrder;

  set layoutHighlight(bool highlight);

  bool get layoutHighlight;

  set layoutCount(bool count);

  bool get layoutCount;

  set autoPlay(bool autoPlay);

  bool get autoPlay;

  set backgroundUpdate(bool backgroundUpdate);

  bool get backgroundUpdate;

  set backgroundUpdateMobileData(bool backgroundUpdateMobileData);

  bool get backgroundUpdateMobileData;

  set updateNotification(bool updateNotification);

  bool get updateNotification;

  Stream<String> get settingsListener;

  set lastFeedRefresh(DateTime lastFeedRefresh);

  DateTime get lastFeedRefresh;
}
