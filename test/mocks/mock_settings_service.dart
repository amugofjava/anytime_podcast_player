// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
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
  bool markDeletedEpisodesAsPlayed = false;

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
  bool themeDarkMode = true;

  @override
  bool trimSilence = false;

  @override
  bool volumeBoost = false;

  @override
  Stream<String> get settingsListener => PublishSubject<String>().stream;
}
