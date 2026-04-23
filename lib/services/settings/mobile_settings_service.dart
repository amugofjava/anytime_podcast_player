// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An implementation [SettingsService] for mobile devices backed by
/// shared preferences.
class MobileSettingsService extends SettingsService {
  static late SharedPreferences _sharedPreferences;
  static MobileSettingsService? _instance;

  final settingsNotifier = PublishSubject<String>();

  MobileSettingsService._create();

  static Future<MobileSettingsService?> instance() async {
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
    settingsNotifier.sink.add('markplayedasdeleted');
  }

  @override
  bool get deleteDownloadedPlayedEpisodes => _sharedPreferences.getBool('deleteDownloadedPlayedEpisodes') ?? false;

  @override
  set deleteDownloadedPlayedEpisodes(bool value) {
    _sharedPreferences.setBool('deleteDownloadedPlayedEpisodes', value);
    settingsNotifier.sink.add('deleteDownloadedPlayedEpisodes');
  }

  @override
  bool get storeDownloadsSDCard => _sharedPreferences.getBool('savesdcard') ?? false;

  @override
  set storeDownloadsSDCard(bool value) {
    _sharedPreferences.setBool('savesdcard', value);
    settingsNotifier.sink.add('savesdcard');
  }

  @override
  String get theme => _sharedPreferences.getString('theme') ?? 'dark';

  @override
  set theme(String mode) {
    _sharedPreferences.setString('theme', mode);

    settingsNotifier.sink.add('theme');
  }

  @override
  set playbackSpeed(double playbackSpeed) {
    _sharedPreferences.setDouble('speed', playbackSpeed);
    settingsNotifier.sink.add('speed');
  }

  @override
  double get playbackSpeed {
    var speed = _sharedPreferences.getDouble('speed') ?? 1.0;

    // We used to use 0.25 increments and now we use 0.1. Round
    // any setting that uses the old 0.25.
    var mod = pow(10.0, 1).toDouble();
    return ((speed * mod).round().toDouble() / mod);
  }

  @override
  set searchProvider(String provider) {
    _sharedPreferences.setString('search', provider);
    settingsNotifier.sink.add('search');
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
    settingsNotifier.sink.add('elconsent');
  }

  @override
  bool get externalLinkConsent {
    return _sharedPreferences.getBool('elconsent') ?? false;
  }

  @override
  set autoOpenNowPlaying(bool autoOpenNowPlaying) {
    _sharedPreferences.setBool('autoopennowplaying', autoOpenNowPlaying);
    settingsNotifier.sink.add('autoopennowplaying');
  }

  @override
  bool get autoOpenNowPlaying {
    return _sharedPreferences.getBool('autoopennowplaying') ?? false;
  }

  @override
  set showFunding(bool show) {
    _sharedPreferences.setBool('showFunding', show);
    settingsNotifier.sink.add('showFunding');
  }

  @override
  bool get showFunding {
    return _sharedPreferences.getBool('showFunding') ?? true;
  }

  @override
  set autoUpdateEpisodePeriod(int period) {
    _sharedPreferences.setInt('autoUpdateEpisodePeriod_v2', period);
    settingsNotifier.sink.add('autoUpdateEpisodePeriod');
  }

  @override
  int get autoUpdateEpisodePeriod {
    /// Default to 3 hours.
    return _sharedPreferences.getInt('autoUpdateEpisodePeriod_v2') ?? 180;
  }

  @override
  set trimSilence(bool trim) {
    _sharedPreferences.setBool('trimSilence', trim);
    settingsNotifier.sink.add('trimSilence');
  }

  @override
  bool get trimSilence {
    return _sharedPreferences.getBool('trimSilence') ?? false;
  }

  @override
  set volumeBoost(bool boost) {
    _sharedPreferences.setBool('volumeBoost', boost);
    settingsNotifier.sink.add('volumeBoost');
  }

  @override
  bool get volumeBoost {
    return _sharedPreferences.getBool('volumeBoost') ?? false;
  }

  @override
  set layoutMode(int mode) {
    _sharedPreferences.setInt('layout', mode);
    settingsNotifier.sink.add('layout');
  }

  @override
  int get layoutMode {
    return _sharedPreferences.getInt('layout') ?? 0;
  }

  @override
  set layoutOrder(String order) {
    _sharedPreferences.setString('layoutOrder', order);
    settingsNotifier.sink.add('layoutOrder');
  }

  @override
  String get layoutOrder {
    return _sharedPreferences.getString('layoutOrder') ?? 'alphabetical';
  }

  @override
  set layoutHighlight(bool highlight) {
    _sharedPreferences.setBool('layoutHighlight', highlight);
    settingsNotifier.sink.add('layoutHighlight');
  }

  @override
  bool get layoutHighlight {
    return _sharedPreferences.getBool('layoutHighlight') ?? false;
  }

  @override
  set layoutCount(bool count) {
    _sharedPreferences.setBool('layoutCount', count);
    settingsNotifier.sink.add('layoutCount');
  }

  @override
  bool get layoutCount {
    return _sharedPreferences.getBool('layoutCount') ?? false;
  }

  @override
  set autoPlay(bool autoPlay) {
    _sharedPreferences.setBool('autoplay', autoPlay);
    settingsNotifier.sink.add('autoplay');
  }

  @override
  bool get autoPlay {
    return _sharedPreferences.getBool('autoplay') ?? false;
  }

  @override
  set backgroundUpdate(bool backgroundUpdate) {
    _sharedPreferences.setBool('backgroundUpdate', backgroundUpdate);
    settingsNotifier.sink.add('backgroundUpdate');
  }

  @override
  bool get backgroundUpdate {
    return _sharedPreferences.getBool('backgroundUpdate') ?? false;
  }

  @override
  set backgroundUpdateMobileData(bool backgroundUpdate) {
    _sharedPreferences.setBool('backgroundUpdateMobileData', backgroundUpdate);
    settingsNotifier.sink.add('backgroundUpdateMobileData');
  }

  @override
  bool get backgroundUpdateMobileData {
    return _sharedPreferences.getBool('backgroundUpdateMobileData') ?? false;
  }

  @override
  set updateNotification(bool updateNotification) {
    _sharedPreferences.setBool('updateNotification', updateNotification);
    settingsNotifier.sink.add('updateNotification');
  }

  @override
  bool get updateNotification {
    return _sharedPreferences.getBool('updateNotification') ?? false;
  }

  @override
  set transcriptUploadProvider(TranscriptUploadProvider provider) {
    _sharedPreferences.setString('transcriptUploadProvider', provider.name);
    settingsNotifier.sink.add('transcriptUploadProvider');
  }

  @override
  TranscriptUploadProvider get transcriptUploadProvider {
    final stored = _sharedPreferences.getString('transcriptUploadProvider');

    if (stored == null || stored.isEmpty) {
      return Environment.hasAnalysisBackend
          ? TranscriptUploadProvider.analysisBackend
          : TranscriptUploadProvider.disabled;
    }

    return TranscriptUploadProvider.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => TranscriptUploadProvider.disabled,
    );
  }

  @override
  set transcriptionProvider(TranscriptionProvider provider) {
    _sharedPreferences.setString('transcriptionProvider', provider.name);
    settingsNotifier.sink.add('transcriptionProvider');
  }

  @override
  TranscriptionProvider get transcriptionProvider {
    final stored = _sharedPreferences.getString('transcriptionProvider');

    if (stored == null || stored.isEmpty) {
      return TranscriptionProvider.localAi;
    }

    return TranscriptionProvider.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => TranscriptionProvider.localAi,
    );
  }

  @override
  set adSkipMode(AdSkipMode mode) {
    _sharedPreferences.setString('adSkipMode', mode.name);
    settingsNotifier.sink.add('adSkipMode');
  }

  @override
  AdSkipMode get adSkipMode {
    final stored = _sharedPreferences.getString('adSkipMode');

    if (stored == null || stored.isEmpty) {
      return AdSkipMode.prompt;
    }

    return AdSkipMode.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => AdSkipMode.prompt,
    );
  }

  @override
  set openAiAnalysisModel(String model) {
    _sharedPreferences.setString('openAiAnalysisModel', model);
    settingsNotifier.sink.add('openAiAnalysisModel');
  }

  @override
  String get openAiAnalysisModel {
    final stored = _sharedPreferences.getString('openAiAnalysisModel')?.trim() ?? '';
    return stored.isEmpty ? 'gpt-4.1-mini' : stored;
  }

  @override
  set grokAnalysisModel(String model) {
    _sharedPreferences.setString('grokAnalysisModel', model);
    settingsNotifier.sink.add('grokAnalysisModel');
  }

  @override
  String get grokAnalysisModel {
    final stored = _sharedPreferences.getString('grokAnalysisModel')?.trim() ?? '';
    return stored.isEmpty ? 'grok-3' : stored;
  }

  @override
  set geminiAnalysisModel(String model) {
    _sharedPreferences.setString('geminiAnalysisModel', model);
    settingsNotifier.sink.add('geminiAnalysisModel');
  }

  @override
  String get geminiAnalysisModel {
    final stored = _sharedPreferences.getString('geminiAnalysisModel')?.trim() ?? '';
    return stored.isEmpty ? 'gemini-3.1-flash-lite-preview' : stored;
  }

  @override
  set backgroundAnalysisEnabled(bool enabled) {
    _sharedPreferences.setBool('backgroundAnalysisEnabled', enabled);
    settingsNotifier.sink.add('backgroundAnalysisEnabled');
  }

  @override
  bool get backgroundAnalysisEnabled {
    return _sharedPreferences.getBool('backgroundAnalysisEnabled') ?? false;
  }

  @override
  set backgroundLocalModel(BackgroundAnalysisLocalModel model) {
    _sharedPreferences.setString('backgroundLocalModel', model.name);
    settingsNotifier.sink.add('backgroundLocalModel');
  }

  @override
  BackgroundAnalysisLocalModel get backgroundLocalModel {
    final stored = _sharedPreferences.getString('backgroundLocalModel');

    if (stored == null || stored.isEmpty) {
      return BackgroundAnalysisLocalModel.gemma4E2B;
    }

    return BackgroundAnalysisLocalModel.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => BackgroundAnalysisLocalModel.gemma4E2B,
    );
  }

  @override
  set backgroundAnalysisDiskCostAccepted(bool accepted) {
    _sharedPreferences.setBool('backgroundAnalysisDiskCostAccepted', accepted);
    settingsNotifier.sink.add('backgroundAnalysisDiskCostAccepted');
  }

  @override
  bool get backgroundAnalysisDiskCostAccepted {
    return _sharedPreferences.getBool('backgroundAnalysisDiskCostAccepted') ?? false;
  }

  @override
  set onDemandAnalysisEnabled(bool enabled) {
    _sharedPreferences.setBool('onDemandAnalysisEnabled', enabled);
    settingsNotifier.sink.add('onDemandAnalysisEnabled');
  }

  @override
  bool get onDemandAnalysisEnabled {
    return _sharedPreferences.getBool('onDemandAnalysisEnabled') ?? true;
  }

  @override
  set showAnalysisHistory(bool show) {
    _sharedPreferences.setBool('showAnalysisHistory', show);
    settingsNotifier.sink.add('showAnalysisHistory');
  }

  @override
  bool get showAnalysisHistory {
    return _sharedPreferences.getBool('showAnalysisHistory') ?? false;
  }

  @override
  set huggingFaceAccessToken(String token) {
    _sharedPreferences.setString('huggingFaceAccessToken', token);
    settingsNotifier.sink.add('huggingFaceAccessToken');
  }

  @override
  String get huggingFaceAccessToken {
    return _sharedPreferences.getString('huggingFaceAccessToken') ?? '';
  }

  @override
  set lastFeedRefresh(DateTime lastFeedRefresh) {
    _sharedPreferences.setInt('lastFeedRefresh', lastFeedRefresh.millisecondsSinceEpoch);
    settingsNotifier.sink.add('lastFeedRefresh');
  }

  @override
  DateTime get lastFeedRefresh {
    final int lastUpdate =
        _sharedPreferences.getInt('lastFeedRefresh') ?? DateTime.utc(1970, 1, 1).millisecondsSinceEpoch;

    return DateTime.fromMillisecondsSinceEpoch(lastUpdate);
  }

  @override
  AppSettings? settings;

  @override
  Stream<String> get settingsListener => settingsNotifier.stream;
}
