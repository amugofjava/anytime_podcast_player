// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/search_providers.dart';
import 'package:anytime/services/notifications/notification_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class SettingsBloc extends Bloc {
  final log = Logger('SettingsBloc');
  final SettingsService settingsService;
  final NotificationService notificationService;
  final BehaviorSubject<AppSettings> _settings = BehaviorSubject<AppSettings>.seeded(AppSettings.sensibleDefaults());
  final BehaviorSubject<String> _theme = BehaviorSubject<String>();
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
  final BehaviorSubject<String> _layoutOrder = BehaviorSubject<String>();
  final BehaviorSubject<bool> _layoutHighlight = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _layoutCount = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _autoPlay = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _backgroundUpdate = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _backgroundUpdateMobileData = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _updateNotification = BehaviorSubject<bool>();

  var _currentSettings = AppSettings.sensibleDefaults();

  SettingsBloc({
    required this.settingsService,
    required this.notificationService,
  }) {
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
      theme: settingsService.theme,
      markDeletedEpisodesAsPlayed: settingsService.markDeletedEpisodesAsPlayed,
      deleteDownloadedPlayedEpisodes: settingsService.deleteDownloadedPlayedEpisodes,
      storeDownloadsSDCard: settingsService.storeDownloadsSDCard,
      playbackSpeed: settingsService.playbackSpeed,
      searchProvider: settingsService.searchProvider,
      searchProviders: providers,
      externalLinkConsent: settingsService.externalLinkConsent,
      autoOpenNowPlaying: settingsService.autoOpenNowPlaying,
      showFunding: settingsService.showFunding,
      autoUpdateEpisodePeriod: settingsService.autoUpdateEpisodePeriod,
      trimSilence: settingsService.trimSilence,
      volumeBoost: settingsService.volumeBoost,
      layoutMode: settingsService.layoutMode,
      layoutOrder: settingsService.layoutOrder,
      layoutHighlight: settingsService.layoutHighlight,
      layoutCount: settingsService.layoutCount,
      autoPlay: settingsService.autoPlay,
      backgroundUpdate: settingsService.backgroundUpdate,
      backgroundUpdateMobileData: settingsService.backgroundUpdateMobileData,
      updatesNotification: settingsService.updateNotification,
    );

    _settings.add(_currentSettings);

    _theme.listen((String mode) {
      _currentSettings = _currentSettings.copyWith(theme: mode);
      _settings.add(_currentSettings);
      settingsService.theme = mode;
    });

    _markDeletedAsPlayed.listen((bool mark) {
      _currentSettings = _currentSettings.copyWith(markDeletedEpisodesAsPlayed: mark);
      _settings.add(_currentSettings);
      settingsService.markDeletedEpisodesAsPlayed = mark;
    });

    _deleteDownloadedPlayedEpisodes.listen((bool delete) {
      _currentSettings = _currentSettings.copyWith(deleteDownloadedPlayedEpisodes: delete);
      _settings.add(_currentSettings);
      settingsService.deleteDownloadedPlayedEpisodes = delete;
    });

    _storeDownloadOnSDCard.listen((bool sdcard) {
      _currentSettings = _currentSettings.copyWith(storeDownloadsSDCard: sdcard);
      _settings.add(_currentSettings);
      settingsService.storeDownloadsSDCard = sdcard;
    });

    _playbackSpeed.listen((double speed) {
      _currentSettings = _currentSettings.copyWith(playbackSpeed: speed);
      _settings.add(_currentSettings);
      settingsService.playbackSpeed = speed;
    });

    _autoOpenNowPlaying.listen((bool autoOpen) {
      _currentSettings = _currentSettings.copyWith(autoOpenNowPlaying: autoOpen);
      _settings.add(_currentSettings);
      settingsService.autoOpenNowPlaying = autoOpen;
    });

    _showFunding.listen((show) {
      // If the setting has not changed, don't bother updating it
      if (show != _currentSettings.showFunding) {
        _currentSettings = _currentSettings.copyWith(showFunding: show);
        settingsService.showFunding = show;
      }

      _settings.add(_currentSettings);
    });

    _searchProvider.listen((search) {
      _currentSettings = _currentSettings.copyWith(searchProvider: search);
      _settings.add(_currentSettings);
      settingsService.searchProvider = search;
    });

    _externalLinkConsent.listen((consent) {
      // If the setting has not changed, don't bother updating it
      if (consent != settingsService.externalLinkConsent) {
        _currentSettings = _currentSettings.copyWith(externalLinkConsent: consent);
        settingsService.externalLinkConsent = consent;
      }

      _settings.add(_currentSettings);
    });

    _autoUpdatePeriod.listen((period) {
      _currentSettings = _currentSettings.copyWith(autoUpdateEpisodePeriod: period);
      _settings.add(_currentSettings);
      settingsService.autoUpdateEpisodePeriod = period;
    });

    _trimSilence.listen((trim) {
      _currentSettings = _currentSettings.copyWith(trimSilence: trim);
      _settings.add(_currentSettings);
      settingsService.trimSilence = trim;
    });

    _volumeBoost.listen((boost) {
      _currentSettings = _currentSettings.copyWith(volumeBoost: boost);
      _settings.add(_currentSettings);
      settingsService.volumeBoost = boost;
    });

    _layoutMode.listen((mode) {
      _currentSettings = _currentSettings.copyWith(layoutMode: mode);
      _settings.add(_currentSettings);
      settingsService.layoutMode = mode;
    });

    _layoutOrder.listen((order) {
      _currentSettings = _currentSettings.copyWith(layoutOrder: order);
      _settings.add(_currentSettings);
      settingsService.layoutOrder = order;
    });

    _layoutHighlight.listen((highlight) {
      _currentSettings = _currentSettings.copyWith(layoutHighlight: highlight);
      _settings.add(_currentSettings);
      settingsService.layoutHighlight = highlight;
    });

    _layoutCount.listen((count) {
      _currentSettings = _currentSettings.copyWith(layoutCount: count);
      _settings.add(_currentSettings);
      settingsService.layoutCount = count;
    });

    _autoPlay.listen((autoPlay) {
      _currentSettings = _currentSettings.copyWith(autoPlay: autoPlay);
      _settings.add(_currentSettings);
      settingsService.autoPlay = autoPlay;
    });

    _backgroundUpdate.listen((backgroundUpdates) {
      _currentSettings = _currentSettings.copyWith(backgroundUpdate: backgroundUpdates);
      _settings.add(_currentSettings);
      settingsService.backgroundUpdate = backgroundUpdates;
    });

    _backgroundUpdateMobileData.listen((backgroundUpdatesMobileData) {
      _currentSettings = _currentSettings.copyWith(backgroundUpdateMobileData: backgroundUpdatesMobileData);
      _settings.add(_currentSettings);
      settingsService.backgroundUpdateMobileData = backgroundUpdatesMobileData;
    });

    _updateNotification.listen((updateNotification) {
      _currentSettings = _currentSettings.copyWith(updatesNotification: updateNotification);
      _settings.add(_currentSettings);
      settingsService.updateNotification = updateNotification;

      if (updateNotification) {
        _initNotifications();
      }
    });
  }

  void _initNotifications() async {
    notificationService.requestPermissionsIfNotGranted().then((allow) {
      if (!allow) {
        _currentSettings = _currentSettings.copyWith(updatesNotification: false);
        _settings.add(_currentSettings);
        settingsService.updateNotification = false;
      }
    });
  }

  Stream<AppSettings> get settings => _settings.stream;

  void Function(String) get theme => _theme.add;

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

  void Function(String) get layoutOrder => _layoutOrder.add;

  void Function(bool) get layoutHighlight => _layoutHighlight.add;

  void Function(bool) get layoutCount => _layoutCount.add;

  void Function(bool) get autoPlay => _autoPlay.add;

  void Function(bool) get backgroundUpdates => _backgroundUpdate.add;

  void Function(bool) get backgroundUpdatesMobileData => _backgroundUpdateMobileData.add;

  void Function(bool) get updateNotification => _updateNotification.add;

  AppSettings get currentSettings => _settings.value;

  @override
  void dispose() {
    _theme.close();
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
    _layoutOrder.close();
    _layoutHighlight.close();
    _layoutCount.close();
    _backgroundUpdate.close();
    _updateNotification.close();
    _settings.close();
  }
}
