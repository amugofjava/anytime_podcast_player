// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/search_providers.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

// TODO: This needs to be refactored to make it simpler. We will soon reach
//       enough settings as to make having a stream for each one no longer
//       maintainable or efficient.
class SettingsBloc extends Bloc {
  final log = Logger('SettingsBloc');
  final SettingsService _settingsService;

  final BehaviorSubject<AppSettings> _settings = BehaviorSubject<AppSettings>.seeded(AppSettings.sensibleDefaults());
  final BehaviorSubject<bool> _darkMode = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _markDeletedAsPlayed = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _storeDownloadonSDCard = BehaviorSubject<bool>();
  final BehaviorSubject<double> _playbackSpeed = BehaviorSubject<double>();
  final BehaviorSubject<String> _searchProvider = BehaviorSubject<String>();
  final BehaviorSubject<bool> _externalLinkConsent = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _autoOpenNowPlaying = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _showFunding = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _trimSilence = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _volumeBoost = BehaviorSubject<bool>();
  final BehaviorSubject<int> _autoUpdatePeriod = BehaviorSubject<int>();
  final BehaviorSubject<int> _layoutMode = BehaviorSubject<int>();

  SettingsBloc(this._settingsService) {
    _init();
  }

  void _init() {
    /// Load all settings
    var themeDarkMode = _settingsService.themeDarkMode;
    var markDeletedEpisodesAsPlayed = _settingsService.markDeletedEpisodesAsPlayed;
    var storeDownloadsSDCard = _settingsService.storeDownloadsSDCard;
    var playbackSpeed = _settingsService.playbackSpeed;
    var autoOpenNowPlaying = _settingsService.autoOpenNowPlaying;
    var themeName = themeDarkMode ? 'dark' : 'light';
    var searchProvider = _settingsService.searchProvider;
    var externalLinkConsent = _settingsService.externalLinkConsent;
    var showFunding = _settingsService.showFunding;
    var autoUpdateEpisodePeriod = _settingsService.autoUpdateEpisodePeriod;
    var trimSilence = _settingsService.trimSilence;
    var volumeBoost = _settingsService.volumeBoost;
    var layoutMode = _settingsService.layoutMode;

    // Add our available search providers.
    var providers = <SearchProvider>[SearchProvider(key: 'itunes', name: 'iTunes')];

    if (podcastIndexKey.isNotEmpty) {
      providers.add(SearchProvider(key: 'podcastindex', name: 'PodcastIndex'));
    }

    var s = AppSettings(
      theme: themeDarkMode ? 'dark' : 'light',
      markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
      storeDownloadsSDCard: storeDownloadsSDCard,
      playbackSpeed: playbackSpeed,
      searchProvider: searchProvider,
      searchProviders: providers,
      externalLinkConsent: externalLinkConsent,
      autoOpenNowPlaying: autoOpenNowPlaying,
      showFunding: showFunding,
      autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
      trimSilence: trimSilence,
      volumeBoost: volumeBoost,
      layout: layoutMode,
    );

    _settings.add(s);

    _darkMode.listen((bool darkMode) {
      themeName = darkMode ? 'dark' : 'light';

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.themeDarkMode = darkMode;
    });

    _markDeletedAsPlayed.listen((bool mark) {
      markDeletedEpisodesAsPlayed = mark;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: mark,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.markDeletedEpisodesAsPlayed = mark;
    });

    _storeDownloadonSDCard.listen((bool sdcard) {
      storeDownloadsSDCard = sdcard;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.storeDownloadsSDCard = sdcard;
    });

    _playbackSpeed.listen((double speed) {
      playbackSpeed = speed;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: speed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.playbackSpeed = speed;
    });

    _autoOpenNowPlaying.listen((bool autoOpen) {
      autoOpenNowPlaying = autoOpen;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpen,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.autoOpenNowPlaying = autoOpen;
    });

    _showFunding.listen((show) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: show,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (show != showFunding) {
        _settingsService.showFunding = show;
      }

      showFunding = show;
    });

    _searchProvider.listen((search) {
      searchProvider = search;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: search,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.searchProvider = search;
    });

    _externalLinkConsent.listen((consent) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: consent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (consent != externalLinkConsent) {
        _settingsService.externalLinkConsent = consent;
      }

      externalLinkConsent = consent;
    });

    _autoUpdatePeriod.listen((period) {
      autoUpdateEpisodePeriod = period;

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: period,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      _settingsService.autoUpdateEpisodePeriod = period;
    });

    _externalLinkConsent.listen((consent) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: consent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (consent != externalLinkConsent) {
        _settingsService.externalLinkConsent = consent;
      }

      externalLinkConsent = consent;
    });

    _trimSilence.listen((trim) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trim,
        volumeBoost: volumeBoost,
        layout: layoutMode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (trim != trimSilence) {
        _settingsService.trimSilence = trim;
      }

      trimSilence = trim;
    });

    _volumeBoost.listen((boost) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: boost,
        layout: layoutMode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (boost != volumeBoost) {
        _settingsService.volumeBoost = boost;
      }

      volumeBoost = boost;
    });

    _layoutMode.listen((mode) {
      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
        playbackSpeed: playbackSpeed,
        searchProvider: searchProvider,
        searchProviders: providers,
        externalLinkConsent: externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying,
        showFunding: showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod,
        trimSilence: trimSilence,
        volumeBoost: volumeBoost,
        layout: mode,
      );

      _settings.add(s);

      // If the setting has not changed, don't bother updating it
      if (mode != layoutMode) {
        _settingsService.layoutMode = mode;
      }

      layoutMode = mode;
    });
  }

  Stream<AppSettings> get settings => _settings.stream;

  void Function(bool) get darkMode => _darkMode.add;

  void Function(bool) get storeDownloadonSDCard => _storeDownloadonSDCard.add;

  void Function(bool) get markDeletedAsPlayed => _markDeletedAsPlayed.add;

  void Function(double) get setPlaybackSpeed => _playbackSpeed.add;

  void Function(bool) get setAutoOpenNowPlaying => _autoOpenNowPlaying.add;

  void Function(String) get setSearchProvider => _searchProvider.add;

  void Function(bool) get setExternalLinkConsent => _externalLinkConsent.add;

  void Function(bool) get setShowFunding => _showFunding.add;

  void Function(int) get autoUpdatePeriod => _autoUpdatePeriod.add;

  void Function(bool) get trimSilence => _trimSilence.add;

  void Function(bool) get volumeBoost => _volumeBoost.add;

  void Function(int) get layoutMode => _layoutMode.add;

  AppSettings get currentSettings => _settings.value;

  @override
  void dispose() {
    _darkMode.close();
    _markDeletedAsPlayed.close();
    _storeDownloadonSDCard.close();
    _playbackSpeed.close();
    _searchProvider.close();
    _externalLinkConsent.close();
    _autoOpenNowPlaying.close();
    _showFunding.close();
    _trimSilence.close();
    _volumeBoost.close();
    _autoUpdatePeriod.close();
    _layoutMode.close();
    _settings.close();
  }
}
