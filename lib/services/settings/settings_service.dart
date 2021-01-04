import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/repository/repository.dart';
import 'package:flutter/foundation.dart';

abstract class SettingsService {
  final Repository repository;

  SettingsService({
    @required this.repository,
  });

  AppSettings get settings;

  set settings(AppSettings settings);

  bool get themeDarkMode;

  set themeDarkMode(bool value);

  bool get markDeletedEpisodesAsPlayed;

  set markDeletedEpisodesAsPlayed(bool value);

  bool get storeDownloadsSDCard;

  set storeDownloadsSDCard(bool value);
}
