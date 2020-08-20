// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

class L {
  L(this.localeName);

  static Future<L> load(Locale locale) {
    final name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      return L(localeName);
    });
  }

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L);
  }

  final String localeName;

  /// Message definitions start here

  /// General
  String get app_title {
    return Intl.message(
      'Anytime Podcast Player',
      name: 'app_title',
      desc: 'Full title for the application',
      locale: localeName,
    );
  }

  String get app_title_short {
    return Intl.message(
      'Anytime Player',
      name: 'app_title_short',
      desc: 'Title for the application',
      locale: localeName,
    );
  }

  String get library {
    return Intl.message(
      'Library',
      name: 'library',
      desc: 'Library tab label',
      locale: localeName,
    );
  }

  String get discover {
    return Intl.message(
      'Discover',
      name: 'discover',
      desc: 'Discover tab label',
      locale: localeName,
    );
  }

  String get downloads {
    return Intl.message(
      'Downloads',
      name: 'downloads',
      desc: 'Downloads tab label',
      locale: localeName,
    );
  }

  /// Podcasts
  String get subscribe_button_label {
    return Intl.message(
      'SUBSCRIBE',
      name: 'subscribe_button_label',
      desc: 'Subscribe button label',
      locale: localeName,
    );
  }

  String get unsubscribe_button_label {
    return Intl.message(
      'UNSUBSCRIBE',
      name: 'unsubscribe_button_label',
      desc: 'Unsubscribe button label',
      locale: localeName,
    );
  }

  String get cancel_button_label {
    return Intl.message(
      'CANCEL',
      name: 'cancel_button_label',
      desc: 'Cancel button label',
      locale: localeName,
    );
  }

  String get ok_button_label {
    return Intl.message(
      'OK',
      name: 'ok_button_label',
      desc: 'OK button label',
      locale: localeName,
    );
  }

  String get subscribe_label {
    return Intl.message(
      'Subscribe',
      name: 'subscribe_label',
      desc: 'Subscribe label',
      locale: localeName,
    );
  }

  String get unsubscribe_label {
    return Intl.message(
      'Unsubscribe',
      name: 'unsubscribe_label',
      desc: 'Unsubscribe label',
      locale: localeName,
    );
  }

  String get unsubscribe_message {
    return Intl.message(
      'Unsubscribing will delete all downloaded episodes of this podcast.',
      name: 'unsubscribe_message',
      desc: 'Displayed when the user unsubscribes from a podcast.',
      locale: localeName,
    );
  }

  String get search_for_podcasts_hint {
    return Intl.message(
      'Search for podcasts',
      name: 'search_for_podcasts_hint',
      desc: 'Hint displayed on search bar when the user clicks the search icon.',
      locale: localeName,
    );
  }

  String get no_subscriptions_message {
    return Intl.message(
      'Tap the Discovery button below or use the search bar above to find your first podcast',
      name: 'no_subscriptions_message',
      desc: 'Displayed on the library tab when the user has no subscriptions',
      locale: localeName,
    );
  }

  String get delete_label {
    return Intl.message(
      'Delete',
      name: 'delete_label',
      desc: 'Delete label',
      locale: localeName,
    );
  }

  String get delete_button_label {
    return Intl.message(
      'DELETE',
      name: 'delete_button_label',
      desc: 'Delete label',
      locale: localeName,
    );
  }

  String get mark_played_label {
    return Intl.message(
      'Mark As Played',
      name: 'mark_played_label',
      desc: 'Mark as played',
      locale: localeName,
    );
  }

  String get mark_unplayed_label {
    return Intl.message(
      'Mark As Unplayed',
      name: 'mark_unplayed_label',
      desc: 'Mark as unplayed',
      locale: localeName,
    );
  }

  String get delete_episode_confirmation {
    return Intl.message(
      'Are you sure you wish to delete this episode?',
      name: 'delete_episode_confirmation',
      desc: 'User is asked to confirm when they attempt to delete an episode',
      locale: localeName,
    );
  }

  String get delete_episode_title {
    return Intl.message(
      'Delete Episode',
      name: 'delete_episode_title',
      desc: 'Delete label',
      locale: localeName,
    );
  }

  String get no_downloads_message {
    return Intl.message(
      'You do not have any downloaded episodes',
      name: 'no_downloads_message',
      desc: 'Displayed on the library tab when the user has no subscriptions',
      locale: localeName,
    );
  }

  String get no_search_results_message {
    return Intl.message(
      'No podcasts found',
      name: 'no_search_results_message',
      desc: 'Displayed on the library tab when the user has no subscriptions',
      locale: localeName,
    );
  }

  String get no_podcast_details_message {
    return Intl.message(
      'Could not load podcast episodes. Please check your connection.',
      name: 'no_podcast_details_message',
      desc: 'Displayed on the podcast details page when the details could not be loaded',
      locale: localeName,
    );
  }

  String get play_button_label {
    return Intl.message(
      'Play epsiode',
      name: 'play_button_label',
      desc: 'Semantic label for the play button',
      locale: localeName,
    );
  }

  String get pause_button_label {
    return Intl.message(
      'Pause episode',
      name: 'pause_button_label',
      desc: 'Semantic label for the pause button',
      locale: localeName,
    );
  }

  String get download_episode_button_label {
    return Intl.message(
      'Download episode',
      name: 'download_episode_button_label',
      desc: 'Semantic label for the download episode button',
      locale: localeName,
    );
  }

  String get delete_episode_button_label {
    return Intl.message(
      'Delete episode',
      name: 'delete_episode_button_label',
      desc: 'Semantic label for the delete episode',
      locale: localeName,
    );
  }

  String get close_button_label {
    return Intl.message(
      'Close',
      name: 'close_button_label',
      desc: 'Close button label',
      locale: localeName,
    );
  }

  String get search_button_label {
    return Intl.message(
      'Search',
      name: 'search_button_label',
      desc: 'Search button label',
      locale: localeName,
    );
  }

  String get clear_search_button_label {
    return Intl.message(
      'Clear search text',
      name: 'clear_search_button_label',
      desc: 'Search button label',
      locale: localeName,
    );
  }

  String get search_back_button_label {
    return Intl.message(
      'Back',
      name: 'search_back_button_label',
      desc: 'Search button label',
      locale: localeName,
    );
  }

  String get minimise_player_window_button_label {
    return Intl.message(
      'Minimise player window',
      name: 'minimise_player_window_button_label',
      desc: 'Search button label',
      locale: localeName,
    );
  }

  String get rewind_button_label {
    return Intl.message(
      'Rewind episode 30 seconds',
      name: 'rewind_button_label',
      desc: 'Rewind button tooltip',
      locale: localeName,
    );
  }

  String get fast_forward_button_label {
    return Intl.message(
      'Fast-forward episode 30 seconds',
      name: 'fast_forward_button_label',
      desc: 'Fast forward tooltip',
      locale: localeName,
    );
  }

  String get about_label {
    return Intl.message(
      'About',
      name: 'about_label',
      desc: 'About menu item',
      locale: localeName,
    );
  }

  String get mark_episodes_played_label {
    return Intl.message(
      'Mark all episodes as played',
      name: 'mark_episodes_played_label',
      desc: 'Mark all episodes played menu item',
      locale: localeName,
    );
  }

  String get mark_episodes_not_played_label {
    return Intl.message(
      'Mark all episodes as not-played',
      name: 'mark_episodes_not_played_label',
      desc: 'Mark all episodes not played menu item',
      locale: localeName,
    );
  }

  String get stop_download_confirmation {
    return Intl.message(
      'Are you sure you wish to stop this download and delete the episode?',
      name: 'stop_download_confirmation',
      desc: 'User is asked to confirm when they wish to stop the active download.',
      locale: localeName,
    );
  }

  String get stop_download_button_label {
    return Intl.message(
      'STOP',
      name: 'stop_download_button_label',
      desc: 'Stop label',
      locale: localeName,
    );
  }

  String get stop_download_title {
    return Intl.message(
      'Stop Download',
      name: 'stop_download_title',
      desc: 'Stop download label',
      locale: localeName,
    );
  }

  String get settings_mark_deleted_played_label {
    return Intl.message(
      'Mark deleted episodes as played',
      name: 'settings_mark_deleted_played_label',
      desc: 'Mark deleted episodes as played setting',
      locale: localeName,
    );
  }

  String get settings_download_sd_card_label {
    return Intl.message(
      'Download episodes to SD card',
      name: 'settings_download_sd_card_label',
      desc: 'Download episodes to SD card setting',
      locale: localeName,
    );
  }

  String get settings_download_switch_card {
    return Intl.message(
      'New downloads will be saved to the SD card. Existing downloads will remain on internal storage.',
      name: 'settings_download_switch_card',
      desc: 'Displayed when user switches from internal storage to SD card',
      locale: localeName,
    );
  }

  String get settings_download_switch_internal {
    return Intl.message(
      'New downloads will be saved to internal storage. Existing downloads will remain on the SD card.',
      name: 'settings_download_switch_internal',
      desc: 'Displayed when user switches from internal SD card to internal storage',
      locale: localeName,
    );
  }

  String get settings_download_switch_label {
    return Intl.message(
      'Change storage location',
      name: 'settings_download_switch_label',
      desc: 'Dialog label for storage switch',
      locale: localeName,
    );
  }

  String get cancel_option_label {
    return Intl.message(
      'Cancel',
      name: 'cancel_option_label',
      desc: 'Cancel option label',
      locale: localeName,
    );
  }
}

class LocalisationsDelegate extends LocalizationsDelegate<L> {
  const LocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<L> load(Locale locale) => L.load(locale);

  @override
  bool shouldReload(LocalisationsDelegate old) => false;
}
