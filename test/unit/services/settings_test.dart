// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This set of tests ensures that we can set and get each setting and, more
/// importantly, we get the correct notification in the settings stream as
/// each is updated.
void main() {
  const int timeout = 500;
  final Map<String, Object> settings = <String, Object>{'dummy': 1};
  SettingsService? mobileSettingsService;
  late Stream<String>? settingsListener;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(settings);
    mobileSettingsService = await MobileSettingsService.instance();
    settingsListener = mobileSettingsService?.settingsListener;

    assert(mobileSettingsService != null);
    assert(settingsListener != null);
  });

  test('Test mark deleted episodes as played', () async {
    expect(mobileSettingsService?.markDeletedEpisodesAsPlayed, false);
    unawaited(expectLater(settingsListener, emits('markplayedasdeleted')));
    mobileSettingsService?.markDeletedEpisodesAsPlayed = true;
    expect(mobileSettingsService?.markDeletedEpisodesAsPlayed, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test SD card', () async {
    expect(mobileSettingsService?.storeDownloadsSDCard, false);
    unawaited(expectLater(settingsListener, emits('savesdcard')));
    mobileSettingsService?.storeDownloadsSDCard = true;
    expect(mobileSettingsService?.storeDownloadsSDCard, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test theme', () async {
    expect(mobileSettingsService?.theme, 'dark');
    expectLater(settingsListener, emits('theme'));
    mobileSettingsService?.theme = 'dark';
    expect(mobileSettingsService?.theme, 'dark');
    mobileSettingsService?.theme = 'light';
    expect(mobileSettingsService?.theme, 'light');
    mobileSettingsService?.theme = 'system';
    expect(mobileSettingsService?.theme, 'system');
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test playback speed', () async {
    expect(mobileSettingsService?.playbackSpeed, 1.0);
    unawaited(expectLater(settingsListener, emits('speed')));
    mobileSettingsService?.playbackSpeed = 1.2;
    expect(mobileSettingsService?.playbackSpeed, 1.2);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test search provider', () async {
    expect(mobileSettingsService?.searchProvider, 'itunes');
    unawaited(expectLater(settingsListener, emits('search')));
    // Key not set so should still return itunes.
    mobileSettingsService?.searchProvider = 'itunes';
    expect(mobileSettingsService?.searchProvider, 'itunes');
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test external link consent', () async {
    expect(mobileSettingsService?.externalLinkConsent, false);
    unawaited(expectLater(settingsListener, emits('elconsent')));
    mobileSettingsService?.externalLinkConsent = true;
    expect(mobileSettingsService?.externalLinkConsent, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test auto-open now playing screen', () async {
    expect(mobileSettingsService?.autoOpenNowPlaying, false);
    unawaited(expectLater(settingsListener, emits('autoopennowplaying')));
    mobileSettingsService?.autoOpenNowPlaying = true;
    expect(mobileSettingsService?.autoOpenNowPlaying, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test show funding', () async {
    expect(mobileSettingsService?.showFunding, true);
    unawaited(expectLater(settingsListener, emits('showFunding')));
    mobileSettingsService?.showFunding = false;
    expect(mobileSettingsService?.showFunding, false);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test episode refresh time', () async {
    expect(mobileSettingsService?.autoUpdateEpisodePeriod, 180);
    unawaited(expectLater(settingsListener, emits('autoUpdateEpisodePeriod')));
    mobileSettingsService?.autoUpdateEpisodePeriod = 60;
    expect(mobileSettingsService?.autoUpdateEpisodePeriod, 60);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test trim silence', () async {
    expect(mobileSettingsService?.trimSilence, false);
    unawaited(expectLater(settingsListener, emits('trimSilence')));
    mobileSettingsService?.trimSilence = true;
    expect(mobileSettingsService?.trimSilence, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test volume boost', () async {
    expect(mobileSettingsService?.volumeBoost, false);
    unawaited(expectLater(settingsListener, emits('volumeBoost')));
    mobileSettingsService?.volumeBoost = true;
    expect(mobileSettingsService?.volumeBoost, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test layout mode', () async {
    expect(mobileSettingsService?.layoutMode, 0);
    unawaited(expectLater(settingsListener, emits('layout')));
    mobileSettingsService?.layoutMode = 1;
    expect(mobileSettingsService?.layoutMode, 1);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test delete played downloaded episodes', () async {
    expect(mobileSettingsService?.deleteDownloadedPlayedEpisodes, false);
    unawaited(expectLater(settingsListener, emits('deleteDownloadedPlayedEpisodes')));
    mobileSettingsService?.deleteDownloadedPlayedEpisodes = true;
    expect(mobileSettingsService?.deleteDownloadedPlayedEpisodes, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));
}
