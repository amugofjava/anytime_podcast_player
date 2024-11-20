// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
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

  setUp(() async {
    SharedPreferences.setMockInitialValues(settings);
    mobileSettingsService = await MobileSettingsService.instance();
    settingsListener = mobileSettingsService?.settingsListener;

    assert(mobileSettingsService != null);
    assert(settingsListener != null);
  });

  test('Test mark deleted episodes as played', () async {
    expect(mobileSettingsService?.markDeletedEpisodesAsPlayed, false);
    expectLater(settingsListener, emits('markplayedasdeleted'));
    mobileSettingsService?.markDeletedEpisodesAsPlayed = true;
    expect(mobileSettingsService?.markDeletedEpisodesAsPlayed, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test SD card', () async {
    expect(mobileSettingsService?.storeDownloadsSDCard, false);
    expectLater(settingsListener, emits('savesdcard'));
    mobileSettingsService?.storeDownloadsSDCard = true;
    expect(mobileSettingsService?.storeDownloadsSDCard, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test dark mode', () async {
    expect(mobileSettingsService?.themeDarkMode, true);
    expectLater(settingsListener, emits('theme'));
    mobileSettingsService?.themeDarkMode = false;
    expect(mobileSettingsService?.themeDarkMode, false);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test playback speed', () async {
    expect(mobileSettingsService?.playbackSpeed, 1.0);
    expectLater(settingsListener, emits('speed'));
    mobileSettingsService?.playbackSpeed = 1.2;
    expect(mobileSettingsService?.playbackSpeed, 1.2);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test search provider', () async {
    expect(mobileSettingsService?.searchProvider, 'itunes');
    expectLater(settingsListener, emits('search'));
    // Key not set so should still return itunes.
    mobileSettingsService?.searchProvider = 'itunes';
    expect(mobileSettingsService?.searchProvider, 'itunes');
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test external link consent', () async {
    expect(mobileSettingsService?.externalLinkConsent, false);
    expectLater(settingsListener, emits('elconsent'));
    mobileSettingsService?.externalLinkConsent = true;
    expect(mobileSettingsService?.externalLinkConsent, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test auto-open now playing screen', () async {
    expect(mobileSettingsService?.autoOpenNowPlaying, false);
    expectLater(settingsListener, emits('autoopennowplaying'));
    mobileSettingsService?.autoOpenNowPlaying = true;
    expect(mobileSettingsService?.autoOpenNowPlaying, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test show funding', () async {
    expect(mobileSettingsService?.showFunding, true);
    expectLater(settingsListener, emits('showFunding'));
    mobileSettingsService?.showFunding = false;
    expect(mobileSettingsService?.showFunding, false);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test episode refresh time', () async {
    expect(mobileSettingsService?.autoUpdateEpisodePeriod, 180);
    expectLater(settingsListener, emits('autoUpdateEpisodePeriod'));
    mobileSettingsService?.autoUpdateEpisodePeriod = 60;
    expect(mobileSettingsService?.autoUpdateEpisodePeriod, 60);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test trim silence', () async {
    expect(mobileSettingsService?.trimSilence, false);
    expectLater(settingsListener, emits('trimSilence'));
    mobileSettingsService?.trimSilence = true;
    expect(mobileSettingsService?.trimSilence, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test volume boost', () async {
    expect(mobileSettingsService?.volumeBoost, false);
    expectLater(settingsListener, emits('volumeBoost'));
    mobileSettingsService?.volumeBoost = true;
    expect(mobileSettingsService?.volumeBoost, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test layout mode', () async {
    expect(mobileSettingsService?.layoutMode, 0);
    expectLater(settingsListener, emits('layout'));
    mobileSettingsService?.layoutMode = 1;
    expect(mobileSettingsService?.layoutMode, 1);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));

  test('Test delete played downloaded episodes', () async {
    expect(mobileSettingsService?.deleteDownloadedPlayedEpisodes, false);
    expectLater(settingsListener, emits('deleteDownloadedPlayedEpisodes'));
    mobileSettingsService?.deleteDownloadedPlayedEpisodes = true;
    expect(mobileSettingsService?.deleteDownloadedPlayedEpisodes, true);
  }, timeout: const Timeout(Duration(milliseconds: timeout)));
}
