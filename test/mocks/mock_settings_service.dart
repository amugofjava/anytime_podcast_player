import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:rxdart/rxdart.dart';

class MockSettingsService extends SettingsService {
  @override
  bool autoOpenNowPlaying;

  @override
  int autoUpdateEpisodePeriod;

  @override
  bool externalLinkConsent;

  @override
  int layoutMode;

  @override
  bool markDeletedEpisodesAsPlayed;

  @override
  double playbackSpeed;

  @override
  String searchProvider;

  @override
  AppSettings settings;

  @override
  bool showFunding;

  @override
  bool storeDownloadsSDCard;

  @override
  bool themeDarkMode;

  @override
  bool trimSilence;

  @override
  bool volumeBoost;

  @override
  Stream<String> get settingsListener => PublishSubject<String>().stream;
}
