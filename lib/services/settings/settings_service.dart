import 'package:anytime/entities/app_settings.dart';

abstract class SettingsService {
  AppSettings get settings;

  set settings(AppSettings settings);

  bool get themeDarkMode;

  set themeDarkMode(bool value);

  bool get markDeletedEpisodesAsPlayed;

  set markDeletedEpisodesAsPlayed(bool value);

  bool get storeDownloadsSDCard;

  set storeDownloadsSDCard(bool value);

  set playbackSpeed(double playbackSpeed);

  double get playbackSpeed;

  set autoOpenNowPlaying(bool autoOpenNowPlaying);

  bool get autoOpenNowPlaying;
}
