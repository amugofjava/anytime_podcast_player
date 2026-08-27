// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/search_providers.dart';

class AppSettings {
  /// The current theme name.
  final String theme;

  /// The display language: 'system' (follow device), 'en' or 'zh'.
  final String language;

  /// True if downloaded episodes are automatically transcoded to MP3.
  final bool convertToMp3;

  /// True if episodes are marked as played when deleted.
  final bool markDeletedEpisodesAsPlayed;

  /// True if downloaded played episodes must be deleted automatically.
  final bool deleteDownloadedPlayedEpisodes;

  /// True if downloads should be saved to the SD card.
  final bool storeDownloadsSDCard;

  /// Custom download root directory selected by user. Empty string means default.
  final String customDownloadPath;

  /// The default playback speed.
  final double playbackSpeed;

  /// The search provider: itunes or podcastindex.
  final String? searchProvider;

  /// List of search providers: currently itunes or podcastindex.
  final List<SearchProvider> searchProviders;

  /// True if the user has confirmed dialog accepting funding links.
  final bool externalLinkConsent;

  /// If true the main player window will open as soon as an episode starts.
  final bool autoOpenNowPlaying;

  /// If true the funding link icon will appear (if the podcast supports it).
  final bool showFunding;

  /// If -1 never; 0 always; otherwise time in minutes.
  final int autoUpdateEpisodePeriod;

  /// If true, silence in audio playback is trimmed. Currently Android only.
  final bool trimSilence;

  /// If true, volume is boosted. Currently Android only.
  final bool volumeBoost;

  /// If 0, list view; else grid view.
  final int layoutMode;

  /// If 0, list view; else grid view.
  final String layoutOrder;

  /// True if we highlight new episodes.
  final bool layoutHighlight;

  /// True if we display the unplayed episode count.
  final bool layoutCount;

  /// True if auto play is enabled.
  final bool autoPlay;

  /// True if background updating of episodes is enabled.
  final bool backgroundUpdate;

  /// True if background updating of episodes is enabled when on mobile data.
  final bool backgroundUpdateMobileData;

  /// True if showing a status icon in the notification bar during fetch is enabled
  final bool updatesNotification;

  /// True if newly detected episodes should be automatically downloaded.
  final bool autoDownloadEpisodes;

  /// List of podcast GUIDs selected for auto-downloading. Empty means all subscribed.
  final List<String> autoDownloadPodcastGuids;

  AppSettings({
    required this.theme,
    required this.language,
    required this.convertToMp3,
    required this.markDeletedEpisodesAsPlayed,
    required this.deleteDownloadedPlayedEpisodes,
    required this.storeDownloadsSDCard,
    this.customDownloadPath = '',
    required this.playbackSpeed,
    required this.searchProvider,
    required this.searchProviders,
    required this.externalLinkConsent,
    required this.autoOpenNowPlaying,
    required this.showFunding,
    required this.autoUpdateEpisodePeriod,
    required this.trimSilence,
    required this.volumeBoost,
    required this.layoutMode,
    required this.layoutOrder,
    required this.layoutHighlight,
    required this.layoutCount,
    required this.autoPlay,
    required this.backgroundUpdate,
    required this.backgroundUpdateMobileData,
    required this.updatesNotification,
    this.autoDownloadEpisodes = false,
    this.autoDownloadPodcastGuids = const <String>[],
  });

  AppSettings.sensibleDefaults()
      : theme = 'dark',
        language = 'system',
        convertToMp3 = true,
        markDeletedEpisodesAsPlayed = false,
        deleteDownloadedPlayedEpisodes = false,
        storeDownloadsSDCard = false,
        customDownloadPath = '',
        playbackSpeed = 1.0,
        searchProvider = 'itunes',
        searchProviders = <SearchProvider>[],
        externalLinkConsent = false,
        autoOpenNowPlaying = false,
        showFunding = true,
        autoUpdateEpisodePeriod = -1,
        trimSilence = false,
        volumeBoost = false,
        layoutMode = 0,
        layoutOrder = 'alphabetical',
        layoutHighlight = false,
        layoutCount = false,
        autoPlay = false,
        backgroundUpdate = false,
        backgroundUpdateMobileData = false,
        updatesNotification = false,
        autoDownloadEpisodes = false,
        autoDownloadPodcastGuids = const <String>[];

  AppSettings copyWith({
    String? theme,
    String? language,
    bool? convertToMp3,
    String? selectedTheme,
    bool? markDeletedEpisodesAsPlayed,
    bool? deleteDownloadedPlayedEpisodes,
    bool? storeDownloadsSDCard,
    String? customDownloadPath,
    double? playbackSpeed,
    String? searchProvider,
    List<SearchProvider>? searchProviders,
    bool? externalLinkConsent,
    bool? autoOpenNowPlaying,
    bool? showFunding,
    int? autoUpdateEpisodePeriod,
    bool? trimSilence,
    bool? volumeBoost,
    int? layoutMode,
    String? layoutOrder,
    bool? layoutHighlight,
    bool? layoutCount,
    bool? autoPlay,
    bool? backgroundUpdate,
    bool? backgroundUpdateMobileData,
    bool? updatesNotification,
    bool? autoDownloadEpisodes,
    List<String>? autoDownloadPodcastGuids,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        language: language ?? this.language,
        convertToMp3: convertToMp3 ?? this.convertToMp3,
        markDeletedEpisodesAsPlayed: markDeletedEpisodesAsPlayed ?? this.markDeletedEpisodesAsPlayed,
        deleteDownloadedPlayedEpisodes: deleteDownloadedPlayedEpisodes ?? this.deleteDownloadedPlayedEpisodes,
        storeDownloadsSDCard: storeDownloadsSDCard ?? this.storeDownloadsSDCard,
        customDownloadPath: customDownloadPath ?? this.customDownloadPath,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        searchProvider: searchProvider ?? this.searchProvider,
        searchProviders: searchProviders ?? this.searchProviders,
        externalLinkConsent: externalLinkConsent ?? this.externalLinkConsent,
        autoOpenNowPlaying: autoOpenNowPlaying ?? this.autoOpenNowPlaying,
        showFunding: showFunding ?? this.showFunding,
        autoUpdateEpisodePeriod: autoUpdateEpisodePeriod ?? this.autoUpdateEpisodePeriod,
        trimSilence: trimSilence ?? this.trimSilence,
        volumeBoost: volumeBoost ?? this.volumeBoost,
        layoutMode: layoutMode ?? this.layoutMode,
        layoutOrder: layoutOrder ?? this.layoutOrder,
        layoutHighlight: layoutHighlight ?? this.layoutHighlight,
        layoutCount: layoutCount ?? this.layoutCount,
        autoPlay: autoPlay ?? this.autoPlay,
        backgroundUpdate: backgroundUpdate ?? this.backgroundUpdate,
        backgroundUpdateMobileData: backgroundUpdateMobileData ?? this.backgroundUpdateMobileData,
        updatesNotification: updatesNotification ?? this.updatesNotification,
        autoDownloadEpisodes: autoDownloadEpisodes ?? this.autoDownloadEpisodes,
        autoDownloadPodcastGuids: autoDownloadPodcastGuids ?? this.autoDownloadPodcastGuids,
      );
}
