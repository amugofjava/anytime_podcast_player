// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class SettingsBloc extends Bloc {
  final log = Logger('SettingsBloc');
  final SettingsService _settingsService;

  final BehaviorSubject<AppSettings> _settings = BehaviorSubject<AppSettings>();
  final BehaviorSubject<bool> _darkMode = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _markDeletedAsPlayed = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _storeDownloadonSDCard = BehaviorSubject<bool>();

  SettingsBloc(this._settingsService) {
    _init();
  }

  void _init() {
    /// Load all settings
    var themeDarkMode = _settingsService.themeDarkMode;
    var markDeletedEpisodesAsPlayed = _settingsService.markDeletedEpisodesAsPlayed;
    var storeDownloadsSDCard = _settingsService.storeDownloadsSDCard;
    var themeName = themeDarkMode ? 'dark' : 'light';

    var s = AppSettings(
      theme: themeDarkMode ? 'dark' : 'light',
      markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
      storeDownloadsSDCard: storeDownloadsSDCard,
    );

    _settings.add(s);

    _darkMode.listen((bool darkMode) {
      themeName = darkMode ? 'dark' : 'light';

      s = AppSettings(
        theme: themeName,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed,
        storeDownloadsSDCard: storeDownloadsSDCard,
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
      );

      _settings.add(s);

      _settingsService.storeDownloadsSDCard = sdcard;
    });
  }

  Stream<AppSettings> get settings => _settings.stream;

  void Function(bool) get darkMode => _darkMode.add;

  void Function(bool) get storeDownloadonSDCard => _storeDownloadonSDCard.add;

  void Function(bool) get markDeletedAsPlayed => _markDeletedAsPlayed.add;

  @override
  void dispose() {
    _settings.close();
  }
}
