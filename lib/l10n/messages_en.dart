// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.
// @dart=2.12
// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = MessageLookup();

typedef String? MessageIfAbsent(
    String? messageStr, List<Object>? args);

class MessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'en';

  static m0(days) => "${Intl.plural(days, one: 'One day ago', other: '${days} days ago')}";

  static m1(hours) => "${Intl.plural(hours, one: '${hours} hour ago', other: '${hours} hours ago')}";

  static m2(minutes) => "${minutes} min left";

  static m3(minutes) => "${Intl.plural(minutes, one: '1 minute ago', other: '${minutes} minutes ago')}";

  static m4(seconds) => "${seconds} sec left";

  static m5(weeks) => "${Intl.plural(weeks, one: 'One week ago', other: '${weeks} weeks ago')}";

  static m6(days) => "${Intl.plural(days, one: '1d ago', other: '${days}d ago')}";

  static m7(hours) => "${Intl.plural(hours, one: '1h ago', other: '${hours}h ago')}";

  static m8(minutes) => "${minutes} min left";

  static m9(minutes) => "${Intl.plural(minutes, one: '1m ago', other: '${minutes}m ago')}";

  static m10(seconds) => "${seconds} sec left";

  static m11(weeks) => "${Intl.plural(weeks, one: '1w ago', other: '${weeks}w ago')}";

  static m12(minutes) => "${minutes} minutes";

  static m13(minutes) => "${minutes} min";

  static m14(seconds) => "${seconds} sec";

  static m15(minutes) => "${minutes} minutes";

  static m16(seconds) => "${seconds} seconds";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(_) => {
      'about_label': MessageLookupByLibrary.simpleMessage('About'),
    'add_rss_feed_option': MessageLookupByLibrary.simpleMessage('Add RSS Feed'),
    'app_title': MessageLookupByLibrary.simpleMessage('Anytime Podcast Player'),
    'app_title_short': MessageLookupByLibrary.simpleMessage('Anytime Player'),
    'audio_effect_trim_silence_label': MessageLookupByLibrary.simpleMessage('Trim Silence'),
    'audio_effect_volume_boost_label': MessageLookupByLibrary.simpleMessage('Volume Boost'),
    'audio_settings_playback_speed_label': MessageLookupByLibrary.simpleMessage('Playback Speed'),
    'auto_scroll_transcript_label': MessageLookupByLibrary.simpleMessage('Follow transcript'),
    'cancel_button_label': MessageLookupByLibrary.simpleMessage('Cancel'),
    'cancel_download_button_label': MessageLookupByLibrary.simpleMessage('Cancel download'),
    'cancel_option_label': MessageLookupByLibrary.simpleMessage('Cancel'),
    'chapters_label': MessageLookupByLibrary.simpleMessage('Chapters'),
    'clear_queue_button_label': MessageLookupByLibrary.simpleMessage('CLEAR QUEUE'),
    'clear_search_button_label': MessageLookupByLibrary.simpleMessage('Clear search text'),
    'close_button_label': MessageLookupByLibrary.simpleMessage('Close'),
    'consent_message': MessageLookupByLibrary.simpleMessage('This funding link will take you to an external site where you will be able to directly support the show. Links are provided by the podcast authors and is not controlled by Anytime.'),
    'continue_button_label': MessageLookupByLibrary.simpleMessage('Continue'),
    'delete_button_label': MessageLookupByLibrary.simpleMessage('Delete'),
    'delete_episode_button_label': MessageLookupByLibrary.simpleMessage('Delete downloaded episode'),
    'delete_episode_confirmation': MessageLookupByLibrary.simpleMessage('Are you sure you wish to delete this episode?'),
    'delete_episode_title': MessageLookupByLibrary.simpleMessage('Delete Episode'),
    'delete_label': MessageLookupByLibrary.simpleMessage('Delete'),
    'discover': MessageLookupByLibrary.simpleMessage('Discover'),
    'discovery_categories_itunes': MessageLookupByLibrary.simpleMessage('All,Arts,Business,Comedy,Education,Fiction,Government,Health & Fitness,History,Kids & Family,Leisure,Music,News,Religion & Spirituality,Science,Society & Culture,Sports,TV & Film,Technology,True Crime'),
    'discovery_categories_pindex': MessageLookupByLibrary.simpleMessage('All,After-Shows,Alternative,Animals,Animation,Arts,Astronomy,Automotive,Aviation,Baseball,Basketball,Beauty,Books,Buddhism,Business,Careers,Chemistry,Christianity,Climate,Comedy,Commentary,Courses,Crafts,Cricket,Cryptocurrency,Culture,Daily,Design,Documentary,Drama,Earth,Education,Entertainment,Entrepreneurship,Family,Fantasy,Fashion,Fiction,Film,Fitness,Food,Football,Games,Garden,Golf,Government,Health,Hinduism,History,Hobbies,Hockey,Home,HowTo,Improv,Interviews,Investing,Islam,Journals,Judaism,Kids,Language,Learning,Leisure,Life,Management,Manga,Marketing,Mathematics,Medicine,Mental,Music,Natural,Nature,News,NonProfit,Nutrition,Parenting,Performing,Personal,Pets,Philosophy,Physics,Places,Politics,Relationships,Religion,Reviews,Role-Playing,Rugby,Running,Science,Self-Improvement,Sexuality,Soccer,Social,Society,Spirituality,Sports,Stand-Up,Stories,Swimming,TV,Tabletop,Technology,Tennis,Travel,True Crime,Video-Games,Visual,Volleyball,Weather,Wilderness,Wrestling'),
    'download_episode_button_label': MessageLookupByLibrary.simpleMessage('Download episode'),
    'downloads': MessageLookupByLibrary.simpleMessage('Downloads'),
    'empty_queue_message': MessageLookupByLibrary.simpleMessage('Your queue is empty'),
    'episode_details_button_label': MessageLookupByLibrary.simpleMessage('Show episode information'),
    'episode_filter_clear_filters_button_label': MessageLookupByLibrary.simpleMessage('Clear Filters'),
    'episode_filter_no_episodes_title_description': MessageLookupByLibrary.simpleMessage('This podcast has no episodes matching your search criteria and filter'),
    'episode_filter_no_episodes_title_label': MessageLookupByLibrary.simpleMessage('No Episodes Found'),
    'episode_filter_none_label': MessageLookupByLibrary.simpleMessage('None'),
    'episode_filter_played_label': MessageLookupByLibrary.simpleMessage('Played'),
    'episode_filter_semantic_label': MessageLookupByLibrary.simpleMessage('Filter episodes'),
    'episode_filter_started_label': MessageLookupByLibrary.simpleMessage('Started'),
    'episode_filter_unplayed_label': MessageLookupByLibrary.simpleMessage('Unplayed'),
    'episode_label': MessageLookupByLibrary.simpleMessage('Episode'),
    'episode_semantic_time_days_ago': m0,
    'episode_semantic_time_hours_ago': m1,
    'episode_semantic_time_minute_remaining': m2,
    'episode_semantic_time_minutes_ago': m3,
    'episode_semantic_time_second_remaining': m4,
    'episode_semantic_time_weeks_ago': m5,
    'episode_sort_alphabetical_ascending_label': MessageLookupByLibrary.simpleMessage('Alphabetical A-Z'),
    'episode_sort_alphabetical_descending_label': MessageLookupByLibrary.simpleMessage('Alphabetical Z-A'),
    'episode_sort_earliest_first_label': MessageLookupByLibrary.simpleMessage('Earliest first'),
    'episode_sort_latest_first_label': MessageLookupByLibrary.simpleMessage('Latest first'),
    'episode_sort_none_label': MessageLookupByLibrary.simpleMessage('Default'),
    'episode_sort_semantic_label': MessageLookupByLibrary.simpleMessage('Sort episodes'),
    'episode_time_days_ago': m6,
    'episode_time_hours_ago': m7,
    'episode_time_minute_remaining': m8,
    'episode_time_minutes_ago': m9,
    'episode_time_now': MessageLookupByLibrary.simpleMessage('Now'),
    'episode_time_second_remaining': m10,
    'episode_time_weeks_ago': m11,
    'error_no_connection': MessageLookupByLibrary.simpleMessage('Unable to play episode. Please check your connection and try again.'),
    'error_playback_fail': MessageLookupByLibrary.simpleMessage('An unexpected error occurred during playback. Please check your connection and try again.'),
    'fast_forward_button_label': MessageLookupByLibrary.simpleMessage('Fast-forward episode 30 seconds'),
    'feedback_menu_item_label': MessageLookupByLibrary.simpleMessage('Feedback'),
    'go_back_button_label': MessageLookupByLibrary.simpleMessage('Go Back'),
    'label_episode_actions': MessageLookupByLibrary.simpleMessage('Episode Actions'),
    'label_megabytes': MessageLookupByLibrary.simpleMessage('megabytes'),
    'label_megabytes_abbr': MessageLookupByLibrary.simpleMessage('mb'),
    'label_opml_importing': MessageLookupByLibrary.simpleMessage('Importing'),
    'layout_label': MessageLookupByLibrary.simpleMessage('Layout'),
    'library': MessageLookupByLibrary.simpleMessage('Library'),
    'mark_episodes_not_played_label': MessageLookupByLibrary.simpleMessage('Mark all episodes as unplayed'),
    'mark_episodes_played_label': MessageLookupByLibrary.simpleMessage('Mark all episodes as played'),
    'mark_played_label': MessageLookupByLibrary.simpleMessage('Mark Played'),
    'mark_unplayed_label': MessageLookupByLibrary.simpleMessage('Mark Unplayed'),
    'minimise_player_window_button_label': MessageLookupByLibrary.simpleMessage('Minimise player window'),
    'more_label': MessageLookupByLibrary.simpleMessage('More'),
    'new_episodes_label': MessageLookupByLibrary.simpleMessage('New episodes are available'),
    'new_episodes_view_now_label': MessageLookupByLibrary.simpleMessage('VIEW NOW'),
    'no_downloads_message': MessageLookupByLibrary.simpleMessage('You do not have any downloaded episodes'),
    'no_podcast_details_message': MessageLookupByLibrary.simpleMessage('Could not load podcast episodes. Please check your connection.'),
    'no_search_results_message': MessageLookupByLibrary.simpleMessage('No podcasts found'),
    'no_subscriptions_message': MessageLookupByLibrary.simpleMessage('Tap the Discovery button below or use the search bar above to find your first podcast'),
    'no_transcript_available_label': MessageLookupByLibrary.simpleMessage('A transcript is not available for this podcast'),
    'notes_label': MessageLookupByLibrary.simpleMessage('Notes'),
    'now_playing_episode_position': MessageLookupByLibrary.simpleMessage('Episode position'),
    'now_playing_episode_time_remaining': MessageLookupByLibrary.simpleMessage('Time remaining'),
    'now_playing_queue_label': MessageLookupByLibrary.simpleMessage('Now Playing'),
    'ok_button_label': MessageLookupByLibrary.simpleMessage('OK'),
    'open_show_website_label': MessageLookupByLibrary.simpleMessage('Open show website'),
    'opml_export_button_label': MessageLookupByLibrary.simpleMessage('Export'),
    'opml_import_button_label': MessageLookupByLibrary.simpleMessage('Import'),
    'opml_import_export_label': MessageLookupByLibrary.simpleMessage('OPML Import/Export'),
    'pause_button_label': MessageLookupByLibrary.simpleMessage('Pause episode'),
    'play_button_label': MessageLookupByLibrary.simpleMessage('Play episode'),
    'play_download_button_label': MessageLookupByLibrary.simpleMessage('Play downloaded episode'),
    'playback_speed_label': MessageLookupByLibrary.simpleMessage('Playback speed'),
    'podcast_funding_dialog_header': MessageLookupByLibrary.simpleMessage('Podcast Funding'),
    'podcast_options_overflow_menu_semantic_label': MessageLookupByLibrary.simpleMessage('Options menu'),
    'queue_add_label': MessageLookupByLibrary.simpleMessage('Add'),
    'queue_clear_button_label': MessageLookupByLibrary.simpleMessage('Clear'),
    'queue_clear_label': MessageLookupByLibrary.simpleMessage('Are you sure you wish to clear the queue?'),
    'queue_clear_label_title': MessageLookupByLibrary.simpleMessage('Clear Queue'),
    'queue_remove_label': MessageLookupByLibrary.simpleMessage('Remove'),
    'refresh_feed_label': MessageLookupByLibrary.simpleMessage('Refresh episodes'),
    'resume_button_label': MessageLookupByLibrary.simpleMessage('Resume episode'),
    'rewind_button_label': MessageLookupByLibrary.simpleMessage('Rewind episode 10 seconds'),
    'scrim_episode_details_selector': MessageLookupByLibrary.simpleMessage('Dismiss episode details'),
    'scrim_episode_filter_selector': MessageLookupByLibrary.simpleMessage('Dismiss episode filter'),
    'scrim_episode_sort_selector': MessageLookupByLibrary.simpleMessage('Dismiss episode sort'),
    'scrim_layout_selector': MessageLookupByLibrary.simpleMessage('Dismiss layout selector'),
    'scrim_sleep_timer_selector': MessageLookupByLibrary.simpleMessage('Dismiss sleep timer selector'),
    'scrim_speed_selector': MessageLookupByLibrary.simpleMessage('Dismiss playback speed selector'),
    'search_back_button_label': MessageLookupByLibrary.simpleMessage('Back'),
    'search_button_label': MessageLookupByLibrary.simpleMessage('Search'),
    'search_episodes_label': MessageLookupByLibrary.simpleMessage('Search episodes'),
    'search_for_podcasts_hint': MessageLookupByLibrary.simpleMessage('Search for podcasts'),
    'search_provider_label': MessageLookupByLibrary.simpleMessage('Search provider'),
    'search_transcript_label': MessageLookupByLibrary.simpleMessage('Search transcript'),
    'semantic_announce_loading': MessageLookupByLibrary.simpleMessage('Loading, please wait.'),
    'semantic_announce_searching': MessageLookupByLibrary.simpleMessage('Searching, please wait.'),
    'semantic_chapter_link_label': MessageLookupByLibrary.simpleMessage('Chapter web link'),
    'semantic_current_chapter_label': MessageLookupByLibrary.simpleMessage('Current chapter'),
    'semantic_current_value_label': MessageLookupByLibrary.simpleMessage('Current value'),
    'semantic_playing_options_collapse_label': MessageLookupByLibrary.simpleMessage('Close playing options slider'),
    'semantic_playing_options_expand_label': MessageLookupByLibrary.simpleMessage('Open playing options slider'),
    'semantic_podcast_artwork_label': MessageLookupByLibrary.simpleMessage('Podcast artwork'),
    'semantics_add_to_queue': MessageLookupByLibrary.simpleMessage('Add episode to queue'),
    'semantics_collapse_podcast_description': MessageLookupByLibrary.simpleMessage('Collapse podcast description'),
    'semantics_decrease_playback_speed': MessageLookupByLibrary.simpleMessage('Decrease playback speed'),
    'semantics_episode_tile_collapsed': MessageLookupByLibrary.simpleMessage('Episode list item. Showing image, summary and main controls.'),
    'semantics_episode_tile_collapsed_hint': MessageLookupByLibrary.simpleMessage('expand and show more details and additional options'),
    'semantics_episode_tile_expanded': MessageLookupByLibrary.simpleMessage('Episode list item. Showing description, main controls and additional controls.'),
    'semantics_episode_tile_expanded_hint': MessageLookupByLibrary.simpleMessage('collapse and show summary, download and play control'),
    'semantics_expand_podcast_description': MessageLookupByLibrary.simpleMessage('Expand podcast description'),
    'semantics_increase_playback_speed': MessageLookupByLibrary.simpleMessage('Increase playback speed'),
    'semantics_layout_option_compact_grid': MessageLookupByLibrary.simpleMessage('Compact grid layout'),
    'semantics_layout_option_grid': MessageLookupByLibrary.simpleMessage('Grid layout'),
    'semantics_layout_option_list': MessageLookupByLibrary.simpleMessage('List layout'),
    'semantics_main_player_header': MessageLookupByLibrary.simpleMessage('Main player window'),
    'semantics_mark_episode_played': MessageLookupByLibrary.simpleMessage('Mark Episode as played'),
    'semantics_mark_episode_unplayed': MessageLookupByLibrary.simpleMessage('Mark Episode as un-played'),
    'semantics_mini_player_header': MessageLookupByLibrary.simpleMessage('Mini player. Swipe right to play/pause button. Activate to open main player window'),
    'semantics_play_pause_toggle': MessageLookupByLibrary.simpleMessage('Play/pause toggle'),
    'semantics_podcast_details_header': MessageLookupByLibrary.simpleMessage('Podcast details and episodes page'),
    'semantics_remove_from_queue': MessageLookupByLibrary.simpleMessage('Remove episode from queue'),
    'settings_auto_open_now_playing': MessageLookupByLibrary.simpleMessage('Full screen player mode on episode start'),
    'settings_auto_update_episodes': MessageLookupByLibrary.simpleMessage('Auto update episodes'),
    'settings_auto_update_episodes_10min': MessageLookupByLibrary.simpleMessage('10 minutes since last update'),
    'settings_auto_update_episodes_12hour': MessageLookupByLibrary.simpleMessage('12 hours since last update'),
    'settings_auto_update_episodes_1hour': MessageLookupByLibrary.simpleMessage('1 hour since last update'),
    'settings_auto_update_episodes_30min': MessageLookupByLibrary.simpleMessage('30 minutes since last update'),
    'settings_auto_update_episodes_3hour': MessageLookupByLibrary.simpleMessage('3 hours since last update'),
    'settings_auto_update_episodes_6hour': MessageLookupByLibrary.simpleMessage('6 hours since last update'),
    'settings_auto_update_episodes_always': MessageLookupByLibrary.simpleMessage('Always'),
    'settings_auto_update_episodes_heading': MessageLookupByLibrary.simpleMessage('Refresh episodes on details screen after'),
    'settings_auto_update_episodes_never': MessageLookupByLibrary.simpleMessage('Never'),
    'settings_continuous_play_option': MessageLookupByLibrary.simpleMessage('Continuous play'),
    'settings_continuous_play_subtitle': MessageLookupByLibrary.simpleMessage('Automatically play the next episode in the podcast if the queue is empty'),
    'settings_data_divider_label': MessageLookupByLibrary.simpleMessage('DATA'),
    'settings_delete_played_label': MessageLookupByLibrary.simpleMessage('Delete downloaded episodes once played'),
    'settings_download_sd_card_label': MessageLookupByLibrary.simpleMessage('Download episodes to SD card'),
    'settings_download_switch_card': MessageLookupByLibrary.simpleMessage('New downloads will be saved to the SD card. Existing downloads will remain on internal storage.'),
    'settings_download_switch_internal': MessageLookupByLibrary.simpleMessage('New downloads will be saved to internal storage. Existing downloads will remain on the SD card.'),
    'settings_download_switch_label': MessageLookupByLibrary.simpleMessage('Change storage location'),
    'settings_episodes_divider_label': MessageLookupByLibrary.simpleMessage('EPISODES'),
    'settings_export_opml': MessageLookupByLibrary.simpleMessage('Export OPML'),
    'settings_import_opml': MessageLookupByLibrary.simpleMessage('Import OPML'),
    'settings_label': MessageLookupByLibrary.simpleMessage('Settings'),
    'settings_mark_deleted_played_label': MessageLookupByLibrary.simpleMessage('Mark deleted episodes as played'),
    'settings_personalisation_divider_label': MessageLookupByLibrary.simpleMessage('PERSONALISATION'),
    'settings_playback_divider_label': MessageLookupByLibrary.simpleMessage('PLAYBACK'),
    'settings_theme': MessageLookupByLibrary.simpleMessage('Theme'),
    'settings_theme_heading': MessageLookupByLibrary.simpleMessage('Select Theme'),
    'settings_theme_value_auto': MessageLookupByLibrary.simpleMessage('System theme'),
    'settings_theme_value_dark': MessageLookupByLibrary.simpleMessage('Dark theme'),
    'settings_theme_value_light': MessageLookupByLibrary.simpleMessage('Light theme'),
    'share_episode_option_label': MessageLookupByLibrary.simpleMessage('Share episode'),
    'share_podcast_option_label': MessageLookupByLibrary.simpleMessage('Share podcast'),
    'show_notes_label': MessageLookupByLibrary.simpleMessage('Show notes'),
    'sleep_episode_label': MessageLookupByLibrary.simpleMessage('End of episode'),
    'sleep_minute_label': m12,
    'sleep_off_label': MessageLookupByLibrary.simpleMessage('Off'),
    'sleep_timer_label': MessageLookupByLibrary.simpleMessage('Sleep Timer'),
    'stop_download_button_label': MessageLookupByLibrary.simpleMessage('Stop'),
    'stop_download_confirmation': MessageLookupByLibrary.simpleMessage('Are you sure you wish to stop this download and delete the episode?'),
    'stop_download_title': MessageLookupByLibrary.simpleMessage('Stop Download'),
    'subscribe_button_label': MessageLookupByLibrary.simpleMessage('Follow'),
    'subscribe_label': MessageLookupByLibrary.simpleMessage('Follow'),
    'time_minutes': m13,
    'time_seconds': m14,
    'time_semantic_minutes': m15,
    'time_semantic_seconds': m16,
    'transcript_label': MessageLookupByLibrary.simpleMessage('Transcript'),
    'transcript_why_not_label': MessageLookupByLibrary.simpleMessage('Why not?'),
    'transcript_why_not_url': MessageLookupByLibrary.simpleMessage('https://anytimeplayer.app/docs/anytime_transcript_support_en.html'),
    'unsubscribe_button_label': MessageLookupByLibrary.simpleMessage('Unfollow'),
    'unsubscribe_label': MessageLookupByLibrary.simpleMessage('Unfollow'),
    'unsubscribe_message': MessageLookupByLibrary.simpleMessage('Unfollowing will delete all downloaded episodes of this podcast.'),
    'up_next_queue_label': MessageLookupByLibrary.simpleMessage('Up Next')
  };
}
