// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/search_providers.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class SettingsBloc extends Bloc {
  final log = Logger('SettingsBloc');
  final SettingsService _settingsService;
  final BehaviorSubject<AppSettings> _settings = BehaviorSubject<AppSettings>.seeded(AppSettings.sensibleDefaults());
  final BehaviorSubject<bool> _darkMode = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _markDeletedAsPlayed = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _deleteDownloadedPlayedEpisodes = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _storeDownloadOnSDCard = BehaviorSubject<bool>();
  final BehaviorSubject<double> _playbackSpeed = BehaviorSubject<double>();
  final BehaviorSubject<String> _searchProvider = BehaviorSubject<String>();
  final BehaviorSubject<bool> _externalLinkConsent = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _autoOpenNowPlaying = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _showFunding = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _trimSilence = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _volumeBoost = BehaviorSubject<bool>();
  final BehaviorSubject<int> _autoUpdatePeriod = BehaviorSubject<int>();
  final BehaviorSubject<int> _layoutMode = BehaviorSubject<int>();
  var _currentSettings = AppSettings.sensibleDefaults();

  SettingsBloc(this._settingsService) {
    _init();
  }

  void _init() {
    /// Load all settings
    // Add our available search providers.
    var providers = <SearchProvider>[SearchProvider(key: 'itunes', name: 'iTunes')];

    if (podcastIndexKey.isNotEmpty) {
      providers.add(SearchProvider(key: 'podcastindex', name: 'PodcastIndex'));
    }

    _currentSettings = AppSettings(
      theme: _settingsService.themeDarkMode ? 'dark' : 'light',
      markDeletedEpisodesAsPlayed: _settingsService.markDeletedEpisodesAsPlayed,
      deleteDownloadedPlayedEpisodes: _settingsService.deleteDownloadedPlayedEpisodes,
      storeDownloadsSDCard: _settingsService.storeDownloadsSDCard,
      playbackSpeed: _settingsService.playbackSpeed,
      searchProvider: _settingsService.searchProvider,
      searchProviders: providers,
      externalLinkConsent: _settingsService.externalLinkConsent,
      autoOpenNowPlaying: _settingsService.autoOpenNowPlaying,
      showFunding: _settingsService.showFunding,
      autoUpdateEpisodePeriod: _settingsService.autoUpdateEpisodePeriod,
      trimSilence: _settingsService.trimSilence,
      volumeBoost: _settingsService.volumeBoost,
      layout: _settingsService.layoutMode,
    );

    _settings.add(_currentSettings);

    _darkMode.listen((bool darkMode) {
      _currentSettings = _currentSettings.copyWith(theme: darkMode ? 'dark' : 'light');
      _settings.add(_currentSettings);
      _settingsService.themeDarkMode = darkMode;
    });

    _markDeletedAsPlayed.listen((bool mark) {
      _currentSettings = _currentSettings.copyWith(markDeletedEpisodesAsPlayed: mark);
      _settings.add(_currentSettings);
      _settingsService.markDeletedEpisodesAsPlayed = mark;
    });

    _deleteDownloadedPlayedEpisodes.listen((bool delete) {
      _currentSettings = _currentSettings.copyWith(deleteDownloadedPlayedEpisodes: delete);
      _settings.add(_currentSettings);
      _settingsService.deleteDownloadedPlayedEpisodes = delete;
    });

    _storeDownloadOnSDCard.listen((bool sdcard) {
      _currentSettings = _currentSettings.copyWith(storeDownloadsSDCard: sdcard);
      _settings.add(_currentSettings);
      _settingsService.storeDownloadsSDCard = sdcard;
    });

    _playbackSpeed.listen((double speed) {
      _currentSettings = _currentSettings.copyWith(playbackSpeed: speed);
      _settings.add(_currentSettings);
      _settingsService.playbackSpeed = speed;
    });

    _autoOpenNowPlaying.listen((bool autoOpen) {
      _currentSettings = _currentSettings.copyWith(autoOpenNowPlaying: autoOpen);
      _settings.add(_currentSettings);
      _settingsService.autoOpenNowPlaying = autoOpen;
    });

    _showFunding.listen((show) {
      // If the setting has not changed, don't bother updating it
      if (show != _currentSettings.showFunding) {
        _currentSettings = _currentSettings.copyWith(showFunding: show);
        _settingsService.showFunding = show;
      }

      _settings.add(_currentSettings);
    });

    _searchProvider.listen((search) {
      _currentSettings = _currentSettings.copyWith(searchProvider: search);
      _settings.add(_currentSettings);
      _settingsService.searchProvider = search;
    });

    _externalLinkConsent.listen((consent) {
      // If the setting has not changed, don't bother updating it
      if (consent != _settingsService.externalLinkConsent) {
        _currentSettings = _currentSettings.copyWith(externalLinkConsent: consent);
        _settingsService.externalLinkConsent = consent;
      }

      _settings.add(_currentSettings);
    });

    _autoUpdatePeriod.listen((period) {
      _currentSettings = _currentSettings.copyWith(autoUpdateEpisodePeriod: period);
      _settings.add(_currentSettings);
      _settingsService.autoUpdateEpisodePeriod = period;
    });

    _trimSilence.listen((trim) {
      _currentSettings = _currentSettings.copyWith(trimSilence: trim);
      _settings.add(_currentSettings);
      _settingsService.trimSilence = trim;
    });

    _volumeBoost.listen((boost) {
      _currentSettings = _currentSettings.copyWith(volumeBoost: boost);
      _settings.add(_currentSettings);
      _settingsService.volumeBoost = boost;
    });

    _layoutMode.listen((mode) {
      _currentSettings = _currentSettings.copyWith(layout: mode);
      _settings.add(_currentSettings);
      _settingsService.layoutMode = mode;
    });
  }

  Stream<AppSettings> get settings => _settings.stream;

  void Function(bool) get darkMode => _darkMode.add;

  void Function(bool) get storeDownloadonSDCard => _storeDownloadOnSDCard.add;

  void Function(bool) get markDeletedAsPlayed => _markDeletedAsPlayed.add;

  void Function(bool) get deleteDownloadedPlayedEpisodes => _deleteDownloadedPlayedEpisodes.add;

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
    _deleteDownloadedPlayedEpisodes.close();
    _storeDownloadOnSDCard.close();
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
