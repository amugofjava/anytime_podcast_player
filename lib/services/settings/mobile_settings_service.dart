import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An implementation [SettingService] for mobile devices backed by
/// shared preferences.
class MobileSettingsService extends SettingsService {
  static SharedPreferences _sharedPreferences;
  static MobileSettingsService _instance;

  MobileSettingsService._create();

  static Future<MobileSettingsService> instance() async {
    if (_instance == null) {
      _instance = MobileSettingsService._create();

      _sharedPreferences = await SharedPreferences.getInstance();
    }

    return _instance;
  }

  @override
  bool get markDeletedEpisodesAsPlayed => _sharedPreferences.getBool('markplayedasdeleted') ?? false;

  @override
  set markDeletedEpisodesAsPlayed(bool value) {
    _sharedPreferences.setBool('markplayedasdeleted', value);
  }

  @override
  bool get storeDownloadsSDCard => _sharedPreferences.getBool('savesdcard') ?? false;

  @override
  set storeDownloadsSDCard(bool value) {
    _sharedPreferences.setBool('savesdcard', value);
  }

  @override
  bool get themeDarkMode {
    var theme = _sharedPreferences.getString('theme') ?? 'light';

    return theme == 'dark';
  }

  @override
  set themeDarkMode(bool value) {
    _sharedPreferences.setString('theme', value ? 'dark' : 'light');
  }

  @override
  set playbackSpeed(double playbackSpeed) {
    _sharedPreferences.setDouble('speed', playbackSpeed);
  }

  @override
  double get playbackSpeed {
    return _sharedPreferences.getDouble('speed') ?? 1.0;
  }

  @override
  set searchProvider(String provider) {
    _sharedPreferences.setString('search', provider);
  }

  @override
  String get searchProvider {
    // If we do not have PodcastIndex key, fallback to iTunes
    if (podcastIndexKey.isEmpty) {
      return 'itunes';
    } else {
      return _sharedPreferences.getString('search') ?? 'itunes';
    }
  }

  @override
  set externalLinkConsent(bool consent) {
    _sharedPreferences.setBool('elconsent', consent);
  }

  @override
  bool get externalLinkConsent {
    return _sharedPreferences.getBool('elconsent') ?? false;
  }

  @override
  set autoOpenNowPlaying(bool autoOpenNowPlaying) {
    _sharedPreferences.setBool('autoopennowplaying', autoOpenNowPlaying);
  }

  @override
  bool get autoOpenNowPlaying {
    return _sharedPreferences.getBool('autoopennowplaying') ?? false;
  }

  @override
  set showFunding(bool show) {
    _sharedPreferences.setBool('showFunding', show);
  }

  @override
  bool get showFunding {
    return _sharedPreferences.getBool('showFunding') ?? true;
  }

  @override
  set autoUpdateEpisodePeriod(int period) {
    _sharedPreferences.setInt('autoUpdateEpisodePeriod', period);
  }

  @override
  int get autoUpdateEpisodePeriod {
    /// Default to 3 hours.
    return _sharedPreferences.getInt('autoUpdateEpisodePeriod') ?? 180;
  }

  @override
  set trimSilence(bool trim) {
    _sharedPreferences.setBool('trimSilence', trim);
  }

  @override
  bool get trimSilence {
    return _sharedPreferences.getBool('trimSilence') ?? false;
  }

  @override
  set volumeBoost(bool boost) {
    _sharedPreferences.setBool('volumeBoost', boost);
  }

  @override
  bool get volumeBoost {
    return _sharedPreferences.getBool('volumeBoost') ?? false;
  }

  @override
  set layoutMode(int mode) {
    _sharedPreferences.setInt('layout', mode);
  }

  @override
  int get layoutMode {
    return _sharedPreferences.getInt('layout') ?? 0;
  }

  @override
  AppSettings settings;
}
