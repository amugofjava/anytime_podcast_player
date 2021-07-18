// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

class L {
  L(this.localeName, this.overrides);

  static Future<L> load(Locale locale, Map<String, Map<String, String>> overrides) {
    final name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      return L(localeName, overrides);
    });
  }

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L);
  }

  final String localeName;
  Map<String, Map<String, String>> overrides;

  /// Message definitions start here
  String message(String name) {
    if (overrides == null || overrides.isEmpty || !overrides.containsKey(name)) {
      return null;
    } else {
      return overrides[name][localeName] ?? 'Missing translation for $name and locale $localeName';
    }
  }

  /// General
  String get app_title {
    return message('app_title') ??
        Intl.message(
          'Anytime Podcast Player',
          name: 'app_title',
          desc: 'Full title for the application',
          locale: localeName,
        );
  }

  String get app_title_short {
    return message('app_title_short') ??
        Intl.message(
          'Anytime Player',
          name: 'app_title_short',
          desc: 'Title for the application',
          locale: localeName,
        );
  }

  String get library {
    return message('library') ??
        Intl.message(
          'Library',
          name: 'library',
          desc: 'Library tab label',
          locale: localeName,
        );
  }

  String get discover {
    return message('discover') ??
        Intl.message(
          'Discover',
          name: 'discover',
          desc: 'Discover tab label',
          locale: localeName,
        );
  }

  String get downloads {
    return message('downloads') ??
        Intl.message(
          'Downloads',
          name: 'downloads',
          desc: 'Downloads tab label',
          locale: localeName,
        );
  }

  /// Podcasts
  String get subscribe_button_label {
    return message('subscribe_button_label') ??
        Intl.message(
          'SUBSCRIBE',
          name: 'subscribe_button_label',
          desc: 'Subscribe button label',
          locale: localeName,
        );
  }

  String get unsubscribe_button_label {
    return message('unsubscribe_button_label') ??
        Intl.message(
          'UNSUBSCRIBE',
          name: 'unsubscribe_button_label',
          desc: 'Unsubscribe button label',
          locale: localeName,
        );
  }

  String get cancel_button_label {
    return message('cancel_button_label') ??
        Intl.message(
          'CANCEL',
          name: 'cancel_button_label',
          desc: 'Cancel button label',
          locale: localeName,
        );
  }

  String get ok_button_label {
    return message('ok_button_label') ??
        Intl.message(
          'OK',
          name: 'ok_button_label',
          desc: 'OK button label',
          locale: localeName,
        );
  }

  String get subscribe_label {
    return message('subscribe_label') ??
        Intl.message(
          'Subscribe',
          name: 'subscribe_label',
          desc: 'Subscribe label',
          locale: localeName,
        );
  }

  String get unsubscribe_label {
    return message('unsubscribe_label') ??
        Intl.message(
          'Unsubscribe',
          name: 'unsubscribe_label',
          desc: 'Unsubscribe label',
          locale: localeName,
        );
  }

  String get unsubscribe_message {
    return message('unsubscribe_message') ??
        Intl.message(
          'Unsubscribing will delete all downloaded episodes of this podcast.',
          name: 'unsubscribe_message',
          desc: 'Displayed when the user unsubscribes from a podcast.',
          locale: localeName,
        );
  }

  String get search_for_podcasts_hint {
    return message('search_for_podcasts_hint') ??
        Intl.message(
          'Search for podcasts',
          name: 'search_for_podcasts_hint',
          desc: 'Hint displayed on search bar when the user clicks the search icon.',
          locale: localeName,
        );
  }

  String get no_subscriptions_message {
    return message('no_subscriptions_message') ??
        Intl.message(
          'Tap the Discovery button below or use the search bar above to find your first podcast',
          name: 'no_subscriptions_message',
          desc: 'Displayed on the library tab when the user has no subscriptions',
          locale: localeName,
        );
  }

  String get delete_label {
    return message('delete_label') ??
        Intl.message(
          'Delete',
          name: 'delete_label',
          desc: 'Delete label',
          locale: localeName,
        );
  }

  String get delete_button_label {
    return message('delete_button_label') ??
        Intl.message(
          'DELETE',
          name: 'delete_button_label',
          desc: 'Delete label',
          locale: localeName,
        );
  }

  String get mark_played_label {
    return message('mark_played_label') ??
        Intl.message(
          'Mark As Played',
          name: 'mark_played_label',
          desc: 'Mark as played',
          locale: localeName,
        );
  }

  String get mark_unplayed_label {
    return message('mark_unplayed_label') ??
        Intl.message(
          'Mark As Unplayed',
          name: 'mark_unplayed_label',
          desc: 'Mark as unplayed',
          locale: localeName,
        );
  }

  String get delete_episode_confirmation {
    return message('delete_episode_confirmation') ??
        Intl.message(
          'Are you sure you wish to delete this episode?',
          name: 'delete_episode_confirmation',
          desc: 'User is asked to confirm when they attempt to delete an episode',
          locale: localeName,
        );
  }

  String get delete_episode_title {
    return message('delete_episode_title') ??
        Intl.message(
          'Delete Episode',
          name: 'delete_episode_title',
          desc: 'Delete label',
          locale: localeName,
        );
  }

  String get no_downloads_message {
    return message('no_downloads_message') ??
        Intl.message(
          'You do not have any downloaded episodes',
          name: 'no_downloads_message',
          desc: 'Displayed on the library tab when the user has no subscriptions',
          locale: localeName,
        );
  }

  String get no_search_results_message {
    return message('no_search_results_message') ??
        Intl.message(
          'No podcasts found',
          name: 'no_search_results_message',
          desc: 'Displayed on the library tab when the user has no subscriptions',
          locale: localeName,
        );
  }

  String get no_podcast_details_message {
    return message('no_podcast_details_message') ??
        Intl.message(
          'Could not load podcast episodes. Please check your connection.',
          name: 'no_podcast_details_message',
          desc: 'Displayed on the podcast details page when the details could not be loaded',
          locale: localeName,
        );
  }

  String get play_button_label {
    return message('play_button_label') ??
        Intl.message(
          'Play epsiode',
          name: 'play_button_label',
          desc: 'Semantic label for the play button',
          locale: localeName,
        );
  }

  String get pause_button_label {
    return message('pause_button_label') ??
        Intl.message(
          'Pause episode',
          name: 'pause_button_label',
          desc: 'Semantic label for the pause button',
          locale: localeName,
        );
  }

  String get download_episode_button_label {
    return message('download_episode_button_label') ??
        Intl.message(
          'Download episode',
          name: 'download_episode_button_label',
          desc: 'Semantic label for the download episode button',
          locale: localeName,
        );
  }

  String get delete_episode_button_label {
    return message('delete_episode_button_label') ??
        Intl.message(
          'Delete episode',
          name: 'delete_episode_button_label',
          desc: 'Semantic label for the delete episode',
          locale: localeName,
        );
  }

  String get close_button_label {
    return message('close_button_label') ??
        Intl.message(
          'Close',
          name: 'close_button_label',
          desc: 'Close button label',
          locale: localeName,
        );
  }

  String get search_button_label {
    return message('search_button_label') ??
        Intl.message(
          'Search',
          name: 'search_button_label',
          desc: 'Search button label',
          locale: localeName,
        );
  }

  String get clear_search_button_label {
    return message('clear_search_button_label') ??
        Intl.message(
          'Clear search text',
          name: 'clear_search_button_label',
          desc: 'Search button label',
          locale: localeName,
        );
  }

  String get search_back_button_label {
    return message('search_back_button_label') ??
        Intl.message(
          'Back',
          name: 'search_back_button_label',
          desc: 'Search button label',
          locale: localeName,
        );
  }

  String get minimise_player_window_button_label {
    return message('minimise_player_window_button_label') ??
        Intl.message(
          'Minimise player window',
          name: 'minimise_player_window_button_label',
          desc: 'Search button label',
          locale: localeName,
        );
  }

  String get rewind_button_label {
    return message('rewind_button_label') ??
        Intl.message(
          'Rewind episode 30 seconds',
          name: 'rewind_button_label',
          desc: 'Rewind button tooltip',
          locale: localeName,
        );
  }

  String get fast_forward_button_label {
    return message('fast_forward_button_label') ??
        Intl.message(
          'Fast-forward episode 30 seconds',
          name: 'fast_forward_button_label',
          desc: 'Fast forward tooltip',
          locale: localeName,
        );
  }

  String get about_label {
    return message('about_label') ??
        Intl.message(
          'About',
          name: 'about_label',
          desc: 'About menu item',
          locale: localeName,
        );
  }

  String get mark_episodes_played_label {
    return message('mark_episodes_played_label') ??
        Intl.message(
          'Mark all episodes as played',
          name: 'mark_episodes_played_label',
          desc: 'Mark all episodes played menu item',
          locale: localeName,
        );
  }

  String get mark_episodes_not_played_label {
    return message('mark_episodes_not_played_label') ??
        Intl.message(
          'Mark all episodes as not-played',
          name: 'mark_episodes_not_played_label',
          desc: 'Mark all episodes not played menu item',
          locale: localeName,
        );
  }

  String get stop_download_confirmation {
    return message('stop_download_confirmation') ??
        Intl.message(
          'Are you sure you wish to stop this download and delete the episode?',
          name: 'stop_download_confirmation',
          desc: 'User is asked to confirm when they wish to stop the active download.',
          locale: localeName,
        );
  }

  String get stop_download_button_label {
    return message('stop_download_button_label') ??
        Intl.message(
          'STOP',
          name: 'stop_download_button_label',
          desc: 'Stop label',
          locale: localeName,
        );
  }

  String get stop_download_title {
    return message('stop_download_title') ??
        Intl.message(
          'Stop Download',
          name: 'stop_download_title',
          desc: 'Stop download label',
          locale: localeName,
        );
  }

  String get settings_mark_deleted_played_label {
    return message('settings_mark_deleted_played_label') ??
        Intl.message(
          'Mark deleted episodes as played',
          name: 'settings_mark_deleted_played_label',
          desc: 'Mark deleted episodes as played setting',
          locale: localeName,
        );
  }

  String get settings_download_sd_card_label {
    return message('settings_download_sd_card_label') ??
        Intl.message(
          'Download episodes to SD card',
          name: 'settings_download_sd_card_label',
          desc: 'Download episodes to SD card setting',
          locale: localeName,
        );
  }

  String get settings_download_switch_card {
    return message('settings_download_switch_card') ??
        Intl.message(
          'New downloads will be saved to the SD card. Existing downloads will remain on internal storage.',
          name: 'settings_download_switch_card',
          desc: 'Displayed when user switches from internal storage to SD card',
          locale: localeName,
        );
  }

  String get settings_download_switch_internal {
    return message('settings_download_switch_internal') ??
        Intl.message(
          'New downloads will be saved to internal storage. Existing downloads will remain on the SD card.',
          name: 'settings_download_switch_internal',
          desc: 'Displayed when user switches from internal SD card to internal storage',
          locale: localeName,
        );
  }

  String get settings_download_switch_label {
    return message('settings_download_switch_label') ??
        Intl.message(
          'Change storage location',
          name: 'settings_download_switch_label',
          desc: 'Dialog label for storage switch',
          locale: localeName,
        );
  }

  String get cancel_option_label {
    return message('cancel_option_label') ??
        Intl.message(
          'Cancel',
          name: 'cancel_option_label',
          desc: 'Cancel option label',
          locale: localeName,
        );
  }

  String get settings_theme_switch_label {
    return message('settings_theme_switch_label') ??
        Intl.message(
          'Dark theme',
          name: 'settings_theme_switch_label',
          desc: 'Dark theme',
          locale: localeName,
        );
  }

  String get playback_speed_label {
    return message('playback_speed_label') ??
        Intl.message(
          'Playback speed',
          name: 'playback_speed_label',
          desc: 'Set playback speed icon label',
          locale: localeName,
        );
  }

  String get show_notes_label {
    return message('show_notes_label') ??
        Intl.message(
          'Show notes',
          name: 'show_notes_label',
          desc: 'Set show notes icon label',
          locale: localeName,
        );
  }

  String get search_provider_label {
    return message('search_provider_label') ??
        Intl.message(
          'Search provider',
          name: 'search_provider_label',
          desc: 'Set search provider label',
          locale: localeName,
        );
  }

  String get settings_label {
    return message('settings_label') ??
        Intl.message(
          'Settings',
          name: 'settings_label',
          desc: 'Settings label',
          locale: localeName,
        );
  }

  String get go_back_button_label {
    return message('go_back_button_label') ??
        Intl.message(
          'GO BACK',
          name: 'go_back_button_label',
          desc: 'Go-back button label',
          locale: localeName,
        );
  }

  String get continue_button_label {
    return message('continue_button_label') ??
        Intl.message(
          'CONTINUE',
          name: 'continue_button_label',
          desc: 'Continue button label',
          locale: localeName,
        );
  }

  String get consent_message {
    return message('consent_message') ??
        Intl.message(
          'The funding icon appears for Podcasts that support funding or donations. Clicking the icon will open a page to an external site that is provided by the Podcast owner and is not controlled by AnyTime',
          name: 'consent_message',
          desc: 'Display when first accessing external funding link',
          locale: localeName,
        );
  }

  String get episode_label {
    return message('episode_label') ??
        Intl.message(
          'Episode',
          name: 'episode_label',
          desc: 'Tab label on now playing screen.',
          locale: localeName,
        );
  }

  String get chapters_label {
    return message('chapters_label') ??
        Intl.message(
          'Chapters',
          name: 'chapters_label',
          desc: 'Tab label on now playing screen.',
          locale: localeName,
        );
  }

  String get notes_label {
    return message('notes_label') ??
        Intl.message(
          'Notes',
          name: 'notes_label',
          desc: 'Tab label on now playing screen.',
          locale: localeName,
        );
  }

  String get podcast_funding_dialog_header {
    return message('podcast_funding_dialog_header') ??
        Intl.message(
          'Podcast Funding',
          name: 'podcast_funding_dialog_header',
          desc: 'Header on podcast funding consent dialog',
          locale: localeName,
        );
  }

  String get settings_auto_open_now_playing {
    return message('settings_auto_open_now_playing') ??
        Intl.message(
          'Full screen player mode on episode start',
          name: 'settings_auto_open_now_playing',
          desc: 'Displayed when user switches to use full screen player automatically',
          locale: localeName,
        );
  }

  String get error_no_connection {
    return message('error_no_connection') ??
        Intl.message(
          'Unable to play episode. Please check your connection and try again',
          name: 'error_no_connection',
          desc: 'Displayed when attempting to start streaming an episode with no data connection',
          locale: localeName,
        );
  }

  String get error_playback_fail {
    return message('error_playback_fail') ??
        Intl.message(
          'An unexpected error occurred during playback. Please check your connection and try again',
          name: 'error_playback_fail',
          desc: 'Displayed when attempting to start streaming an episode with no data connection',
          locale: localeName,
        );
  }

  String get add_rss_feed_option {
    return message('add_rss_feed_option') ??
        Intl.message(
          'Add RSS Feed',
          name: 'add_rss_feed_option',
          desc: 'Option label for adding manual RSS feed url',
          locale: localeName,
        );
  }

  String get settings_import_opml {
    return message('settings_import_opml') ??
        Intl.message(
          'Import OPML',
          name: 'settings_import_opml',
          desc: 'Option label importing OPML file',
          locale: localeName,
        );
  }

  String get settings_export_opml {
    return message('settings_export_opml') ??
        Intl.message(
          'Export OPML',
          name: 'settings_export_opml',
          desc: 'Option label exporting OPML file',
          locale: localeName,
        );
  }

  String get label_opml_importing {
    return message('label_opml_importing') ??
        Intl.message(
          'Importing',
          name: 'label_opml_importing',
          desc: 'Label for importing OPML dialog',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes {
    return message('settings_auto_update_episodes') ??
        Intl.message(
          'Auto update episodes',
          name: 'settings_auto_update_episodes',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_never {
    return message('settings_auto_update_episodes_never') ??
        Intl.message(
          'Never',
          name: 'settings_auto_update_episodes_never',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_heading {
    return message('settings_auto_update_episodes_heading') ??
        Intl.message(
          'Refresh episodes on details screen after',
          name: 'settings_auto_update_episodes_heading',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_always {
    return message('settings_auto_update_episodes_always') ??
        Intl.message(
          'Always',
          name: 'settings_auto_update_episodes_always',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_10min {
    return message('settings_auto_update_episodes_10min') ??
        Intl.message(
          '10 minutes since last update',
          name: 'settings_auto_update_episodes_10min',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_30min {
    return message('settings_auto_update_episodes_30min') ??
        Intl.message(
          '30 minutes since last update',
          name: 'settings_auto_update_episodes_30min',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_1hour {
    return message('settings_auto_update_episodes_1hour') ??
        Intl.message(
          '1 hour since last update',
          name: 'settings_auto_update_episodes_1hour',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_3hour {
    return message('settings_auto_update_episodes_3hour') ??
        Intl.message(
          '3 hours since last update',
          name: 'settings_auto_update_episodes_3hour',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_6hour {
    return message('settings_auto_update_episodes_6hour') ??
        Intl.message(
          '6 hours since last update',
          name: 'settings_auto_update_episodes_6hour',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_auto_update_episodes_12hour {
    return message('settings_auto_update_episodes_12hour') ??
        Intl.message(
          '12 hours since last update',
          name: 'settings_auto_update_episodes_12hour',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get new_episodes_label {
    return message('new_episodes_label') ??
        Intl.message(
          'New episodes are available',
          name: 'new_episodes_label',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get new_episodes_view_now_label {
    return message('new_episodes_view_now_label') ??
        Intl.message(
          'VIEW NOW',
          name: 'new_episodes_view_now_label',
          desc: 'Option label for auto updating of episodes',
          locale: localeName,
        );
  }

  String get settings_personalisation_divider_label {
    return message('settings_personalisation_divider_label') ??
        Intl.message(
          'PERSONALISATION',
          name: 'settings_personalisation_divider_label',
          desc: 'Settings divider label for personalisation',
          locale: localeName,
        );
  }

  String get settings_episodes_divider_label {
    return message('settings_episodes_divider_label') ??
        Intl.message(
          'EPISODES',
          name: 'settings_episodes_divider_label',
          desc: 'Settings divider label for episodes',
          locale: localeName,
        );
  }

  String get settings_playback_divider_label {
    return message('settings_playback_divider_label') ??
        Intl.message(
          'PLAYBACK',
          name: 'settings_playback_divider_label',
          desc: 'Settings divider label for playback',
          locale: localeName,
        );
  }

  String get settings_data_divider_label {
    return message('settings_data_divider_label') ??
        Intl.message(
          'DATA',
          name: 'settings_data_divider_label',
          desc: 'Settings divider label for data',
          locale: localeName,
        );
  }
}

class LocalisationsDelegate extends LocalizationsDelegate<L> {
  const LocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<L> load(Locale locale) => L.load(locale, null);

  @override
  bool shouldReload(LocalisationsDelegate old) => false;
}

class EmbeddedLocalisationsDelegate extends LocalizationsDelegate<L> {
  Map<String, Map<String, String>> messages = {};

  EmbeddedLocalisationsDelegate({@required this.messages});

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<L> load(Locale locale) => L.load(locale, messages);

  @override
  bool shouldReload(EmbeddedLocalisationsDelegate old) => false;
}
