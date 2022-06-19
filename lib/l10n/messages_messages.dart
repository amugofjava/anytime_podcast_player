// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a messages locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, always_declare_return_types

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<Object> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'messages';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about_label": MessageLookupByLibrary.simpleMessage("About"),
        "add_rss_feed_option": MessageLookupByLibrary.simpleMessage("Add RSS Feed"),
        "app_title": MessageLookupByLibrary.simpleMessage("Anytime Podcast Player"),
        "app_title_short": MessageLookupByLibrary.simpleMessage("Anytime Player"),
        "audio_effect_trim_silence_label": MessageLookupByLibrary.simpleMessage("Trim Silence"),
        "audio_effect_volume_boost_label": MessageLookupByLibrary.simpleMessage("Volume Boost"),
        "audio_settings_playback_speed_label": MessageLookupByLibrary.simpleMessage("Playback Speed"),
        "cancel_button_label": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cancel_option_label": MessageLookupByLibrary.simpleMessage("Cancel"),
        "chapters_label": MessageLookupByLibrary.simpleMessage("Chapters"),
        "clear_queue_button_label": MessageLookupByLibrary.simpleMessage("CLEAR QUEUE"),
        "clear_search_button_label": MessageLookupByLibrary.simpleMessage("Clear search text"),
        "close_button_label": MessageLookupByLibrary.simpleMessage("Close"),
        "consent_message": MessageLookupByLibrary.simpleMessage(
            "The funding icon appears for Podcasts that support funding or donations. Clicking the icon will open a page to an external site that is provided by the Podcast owner and is not controlled by AnyTime"),
        "continue_button_label": MessageLookupByLibrary.simpleMessage("Continue"),
        "delete_button_label": MessageLookupByLibrary.simpleMessage("Delete"),
        "delete_episode_button_label": MessageLookupByLibrary.simpleMessage("Delete episode"),
        "delete_episode_confirmation":
            MessageLookupByLibrary.simpleMessage("Are you sure you wish to delete this episode?"),
        "delete_episode_title": MessageLookupByLibrary.simpleMessage("Delete Episode"),
        "delete_label": MessageLookupByLibrary.simpleMessage("Delete"),
        "discover": MessageLookupByLibrary.simpleMessage("Discover"),
        "download_episode_button_label": MessageLookupByLibrary.simpleMessage("Download episode"),
        "downloads": MessageLookupByLibrary.simpleMessage("Downloads"),
        "empty_queue_message": MessageLookupByLibrary.simpleMessage("Your queue is empty"),
        "episode_label": MessageLookupByLibrary.simpleMessage("Episode"),
        "error_no_connection":
            MessageLookupByLibrary.simpleMessage("Unable to play episode. Please check your connection and try again"),
        "error_playback_fail": MessageLookupByLibrary.simpleMessage(
            "An unexpected error occurred during playback. Please check your connection and try again"),
        "fast_forward_button_label": MessageLookupByLibrary.simpleMessage("Fast-forward episode 30 seconds"),
        "go_back_button_label": MessageLookupByLibrary.simpleMessage("Go Back"),
        "label_opml_importing": MessageLookupByLibrary.simpleMessage("Importing"),
        "layout_label": MessageLookupByLibrary.simpleMessage("Layout"),
        "library": MessageLookupByLibrary.simpleMessage("Library"),
        "mark_episodes_not_played_label": MessageLookupByLibrary.simpleMessage("Mark all episodes as not-played"),
        "mark_episodes_played_label": MessageLookupByLibrary.simpleMessage("Mark all episodes as played"),
        "mark_played_label": MessageLookupByLibrary.simpleMessage("Mark As Played"),
        "mark_unplayed_label": MessageLookupByLibrary.simpleMessage("Mark As Unplayed"),
        "minimise_player_window_button_label": MessageLookupByLibrary.simpleMessage("Minimise player window"),
        "more_label": MessageLookupByLibrary.simpleMessage("More"),
        "new_episodes_label": MessageLookupByLibrary.simpleMessage("New episodes are available"),
        "new_episodes_view_now_label": MessageLookupByLibrary.simpleMessage("VIEW NOW"),
        "no_downloads_message": MessageLookupByLibrary.simpleMessage("You do not have any downloaded episodes"),
        "no_podcast_details_message":
            MessageLookupByLibrary.simpleMessage("Could not load podcast episodes. Please check your connection."),
        "no_search_results_message": MessageLookupByLibrary.simpleMessage("No podcasts found"),
        "no_subscriptions_message": MessageLookupByLibrary.simpleMessage(
            "Tap the Discovery button below or use the search bar above to find your first podcast"),
        "notes_label": MessageLookupByLibrary.simpleMessage("Notes"),
        "now_playing_queue_label": MessageLookupByLibrary.simpleMessage("Now Playing"),
        "ok_button_label": MessageLookupByLibrary.simpleMessage("OK"),
        "opml_export_button_label": MessageLookupByLibrary.simpleMessage("Export"),
        "opml_import_button_label": MessageLookupByLibrary.simpleMessage("Import"),
        "opml_import_export_label": MessageLookupByLibrary.simpleMessage("OPML Import/Export"),
        "pause_button_label": MessageLookupByLibrary.simpleMessage("Pause episode"),
        "play_button_label": MessageLookupByLibrary.simpleMessage("Play epsiode"),
        "playback_speed_label": MessageLookupByLibrary.simpleMessage("Playback speed"),
        "podcast_funding_dialog_header": MessageLookupByLibrary.simpleMessage("Podcast Funding"),
        "queue_add_label": MessageLookupByLibrary.simpleMessage("Add"),
        "queue_clear_button_label": MessageLookupByLibrary.simpleMessage("Clear"),
        "queue_clear_label": MessageLookupByLibrary.simpleMessage("Are you sure you wish to clear the queue?"),
        "queue_clear_label_title": MessageLookupByLibrary.simpleMessage("Clear Queue"),
        "queue_remove_label": MessageLookupByLibrary.simpleMessage("Remove"),
        "rewind_button_label": MessageLookupByLibrary.simpleMessage("Rewind episode 10 seconds"),
        "search_back_button_label": MessageLookupByLibrary.simpleMessage("Back"),
        "search_button_label": MessageLookupByLibrary.simpleMessage("Search"),
        "search_for_podcasts_hint": MessageLookupByLibrary.simpleMessage("Search for podcasts"),
        "search_provider_label": MessageLookupByLibrary.simpleMessage("Search provider"),
        "settings_auto_open_now_playing":
            MessageLookupByLibrary.simpleMessage("Full screen player mode on episode start"),
        "settings_auto_update_episodes": MessageLookupByLibrary.simpleMessage("Auto update episodes"),
        "settings_auto_update_episodes_10min": MessageLookupByLibrary.simpleMessage("10 minutes since last update"),
        "settings_auto_update_episodes_12hour": MessageLookupByLibrary.simpleMessage("12 hours since last update"),
        "settings_auto_update_episodes_1hour": MessageLookupByLibrary.simpleMessage("1 hour since last update"),
        "settings_auto_update_episodes_30min": MessageLookupByLibrary.simpleMessage("30 minutes since last update"),
        "settings_auto_update_episodes_3hour": MessageLookupByLibrary.simpleMessage("3 hours since last update"),
        "settings_auto_update_episodes_6hour": MessageLookupByLibrary.simpleMessage("6 hours since last update"),
        "settings_auto_update_episodes_always": MessageLookupByLibrary.simpleMessage("Always"),
        "settings_auto_update_episodes_heading":
            MessageLookupByLibrary.simpleMessage("Refresh episodes on details screen after"),
        "settings_auto_update_episodes_never": MessageLookupByLibrary.simpleMessage("Never"),
        "settings_data_divider_label": MessageLookupByLibrary.simpleMessage("DATA"),
        "settings_download_sd_card_label": MessageLookupByLibrary.simpleMessage("Download episodes to SD card"),
        "settings_download_switch_card": MessageLookupByLibrary.simpleMessage(
            "New downloads will be saved to the SD card. Existing downloads will remain on internal storage."),
        "settings_download_switch_internal": MessageLookupByLibrary.simpleMessage(
            "New downloads will be saved to internal storage. Existing downloads will remain on the SD card."),
        "settings_download_switch_label": MessageLookupByLibrary.simpleMessage("Change storage location"),
        "settings_episodes_divider_label": MessageLookupByLibrary.simpleMessage("EPISODES"),
        "settings_export_opml": MessageLookupByLibrary.simpleMessage("Export OPML"),
        "settings_import_opml": MessageLookupByLibrary.simpleMessage("Import OPML"),
        "settings_label": MessageLookupByLibrary.simpleMessage("Settings"),
        "settings_mark_deleted_played_label": MessageLookupByLibrary.simpleMessage("Mark deleted episodes as played"),
        "settings_personalisation_divider_label": MessageLookupByLibrary.simpleMessage("PERSONALISATION"),
        "settings_playback_divider_label": MessageLookupByLibrary.simpleMessage("PLAYBACK"),
        "settings_theme_switch_label": MessageLookupByLibrary.simpleMessage("Dark theme"),
        "show_notes_label": MessageLookupByLibrary.simpleMessage("Show notes"),
        "stop_download_button_label": MessageLookupByLibrary.simpleMessage("Stop"),
        "stop_download_confirmation":
            MessageLookupByLibrary.simpleMessage("Are you sure you wish to stop this download and delete the episode?"),
        "stop_download_title": MessageLookupByLibrary.simpleMessage("Stop Download"),
        "subscribe_button_label": MessageLookupByLibrary.simpleMessage("Follow"),
        "subscribe_label": MessageLookupByLibrary.simpleMessage("Subscribe"),
        "unsubscribe_button_label": MessageLookupByLibrary.simpleMessage("Unfollow"),
        "unsubscribe_label": MessageLookupByLibrary.simpleMessage("Unsubscribe"),
        "unsubscribe_message":
            MessageLookupByLibrary.simpleMessage("Unsubscribing will delete all downloaded episodes of this podcast."),
        "up_next_queue_label": MessageLookupByLibrary.simpleMessage("Up Next")
      };
}
