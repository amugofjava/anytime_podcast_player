// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hans locale. All the
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
  String get localeName => 'zh_Hans';

  static m8(minutes) => "剩余${minutes}分钟";

  static m10(seconds) => "剩余${seconds}秒";

  static m15(minutes) => "${minutes}分";

  static m16(seconds) => "${seconds}秒";

  static m17(minutes) => "${minutes}分钟";

  static m18(seconds) => "${seconds}秒";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(_) => {
      'about_label': MessageLookupByLibrary.simpleMessage('关于'),
    'add_rss_feed_option': MessageLookupByLibrary.simpleMessage('添加 RSS Feed'),
    'app_title': MessageLookupByLibrary.simpleMessage('Anytime 播客播放器'),
    'app_title_short': MessageLookupByLibrary.simpleMessage('Anytime 播放器'),
    'audio_effect_trim_silence_label': MessageLookupByLibrary.simpleMessage('静音消除'),
    'audio_effect_volume_boost_label': MessageLookupByLibrary.simpleMessage('音量增强'),
    'audio_settings_playback_speed_label': MessageLookupByLibrary.simpleMessage('播放速度'),
    'cancel_button_label': MessageLookupByLibrary.simpleMessage('取消'),
    'cancel_option_label': MessageLookupByLibrary.simpleMessage('取消'),
    'chapters_label': MessageLookupByLibrary.simpleMessage('章节'),
    'clear_queue_button_label': MessageLookupByLibrary.simpleMessage('清空队列'),
    'clear_search_button_label': MessageLookupByLibrary.simpleMessage('清空搜索文本'),
    'close_button_label': MessageLookupByLibrary.simpleMessage('关闭'),
    'consent_message': MessageLookupByLibrary.simpleMessage('此资助链接将带您前往外部网站，您可以直接在该网站上支持本节目。链接由播客作者提供，不受 Anytime 控制。'),
    'continue_button_label': MessageLookupByLibrary.simpleMessage('继续'),
    'delete_button_label': MessageLookupByLibrary.simpleMessage('删除'),
    'delete_episode_button_label': MessageLookupByLibrary.simpleMessage('删除已下载的单集'),
    'delete_episode_confirmation': MessageLookupByLibrary.simpleMessage('您确定要删除此单集吗？'),
    'delete_episode_title': MessageLookupByLibrary.simpleMessage('删除单集'),
    'delete_label': MessageLookupByLibrary.simpleMessage('删除'),
    'discover': MessageLookupByLibrary.simpleMessage('发现'),
    'download_episode_button_label': MessageLookupByLibrary.simpleMessage('下载单集'),
    'downloads': MessageLookupByLibrary.simpleMessage('下载'),
    'empty_queue_message': MessageLookupByLibrary.simpleMessage('您的播放队列为空'),
    'episode_filter_none_label': MessageLookupByLibrary.simpleMessage('无'),
    'episode_label': MessageLookupByLibrary.simpleMessage('单集'),
    'episode_sort_none_label': MessageLookupByLibrary.simpleMessage('默认'),
    'episode_time_minute_remaining': m8,
    'episode_time_second_remaining': m10,
    'error_no_connection': MessageLookupByLibrary.simpleMessage('无法播放该单集。请检查您的连接并重试。'),
    'error_playback_fail': MessageLookupByLibrary.simpleMessage('播放过程中出现意外错误。请检查您的连接并重试。'),
    'fast_forward_button_label': MessageLookupByLibrary.simpleMessage('单集快进 30 秒'),
    'feedback_menu_item_label': MessageLookupByLibrary.simpleMessage('反馈'),
    'go_back_button_label': MessageLookupByLibrary.simpleMessage('返回'),
    'label_opml_importing': MessageLookupByLibrary.simpleMessage('导入中'),
    'layout_label': MessageLookupByLibrary.simpleMessage('布局'),
    'layout_selector_unplayed_episodes': MessageLookupByLibrary.simpleMessage('显示未播数量'),
    'library': MessageLookupByLibrary.simpleMessage('库'),
    'mark_episodes_not_played_label': MessageLookupByLibrary.simpleMessage('标记全部单集为未听'),
    'mark_episodes_played_label': MessageLookupByLibrary.simpleMessage('标记全部单集为已听'),
    'mark_played_label': MessageLookupByLibrary.simpleMessage('标为已听'),
    'mark_unplayed_label': MessageLookupByLibrary.simpleMessage('标为未听'),
    'minimise_player_window_button_label': MessageLookupByLibrary.simpleMessage('最小化播放器窗口'),
    'more_label': MessageLookupByLibrary.simpleMessage('更多'),
    'new_episodes_label': MessageLookupByLibrary.simpleMessage('有新单集上线'),
    'new_episodes_view_now_label': MessageLookupByLibrary.simpleMessage('立即查看'),
    'no_downloads_message': MessageLookupByLibrary.simpleMessage('您暂未下载任何单集'),
    'no_podcast_details_message': MessageLookupByLibrary.simpleMessage('无法加载播客节目。请检查您的连接。'),
    'no_search_results_message': MessageLookupByLibrary.simpleMessage('未找到播客'),
    'no_subscriptions_message': MessageLookupByLibrary.simpleMessage('点击下方的“发现”按钮或使用上面的搜索栏查找您的第一个播客'),
    'no_transcript_available_label': MessageLookupByLibrary.simpleMessage('此播客暂无转写'),
    'notes_label': MessageLookupByLibrary.simpleMessage('备注'),
    'now_playing_queue_label': MessageLookupByLibrary.simpleMessage('正在播放'),
    'ok_button_label': MessageLookupByLibrary.simpleMessage('确定'),
    'opml_export_button_label': MessageLookupByLibrary.simpleMessage('导出'),
    'opml_import_button_label': MessageLookupByLibrary.simpleMessage('导入'),
    'opml_import_export_label': MessageLookupByLibrary.simpleMessage('OPML 导入/导出'),
    'pause_button_label': MessageLookupByLibrary.simpleMessage('暂停单集'),
    'play_button_label': MessageLookupByLibrary.simpleMessage('播放单集'),
    'playback_speed_label': MessageLookupByLibrary.simpleMessage('播放速度'),
    'podcast_funding_dialog_header': MessageLookupByLibrary.simpleMessage('播客赞助'),
    'queue_add_label': MessageLookupByLibrary.simpleMessage('添加'),
    'queue_clear_button_label': MessageLookupByLibrary.simpleMessage('清除'),
    'queue_clear_label': MessageLookupByLibrary.simpleMessage('您确定要清除队列吗？'),
    'queue_clear_label_title': MessageLookupByLibrary.simpleMessage('清空队列'),
    'queue_remove_label': MessageLookupByLibrary.simpleMessage('删除'),
    'rewind_button_label': MessageLookupByLibrary.simpleMessage('单集倒回 10 秒'),
    'search_back_button_label': MessageLookupByLibrary.simpleMessage('后退'),
    'search_button_label': MessageLookupByLibrary.simpleMessage('搜索'),
    'search_for_podcasts_hint': MessageLookupByLibrary.simpleMessage('搜索播客'),
    'search_provider_label': MessageLookupByLibrary.simpleMessage('搜索提供方'),
    'search_transcript_label': MessageLookupByLibrary.simpleMessage('搜索转写'),
    'semantic_announce_loading': MessageLookupByLibrary.simpleMessage('加载中，请稍候。'),
    'semantic_current_value_label': MessageLookupByLibrary.simpleMessage('当前值'),
    'semantics_add_to_queue': MessageLookupByLibrary.simpleMessage('添加单集到队列'),
    'semantics_collapse_podcast_description': MessageLookupByLibrary.simpleMessage('收起播客描述'),
    'semantics_decrease_playback_speed': MessageLookupByLibrary.simpleMessage('降低播放速度'),
    'semantics_expand_podcast_description': MessageLookupByLibrary.simpleMessage('展开播客描述'),
    'semantics_increase_playback_speed': MessageLookupByLibrary.simpleMessage('增加播放速度'),
    'semantics_layout_option_compact_grid': MessageLookupByLibrary.simpleMessage('紧凑的网格布局'),
    'semantics_layout_option_grid': MessageLookupByLibrary.simpleMessage('网格布局'),
    'semantics_layout_option_list': MessageLookupByLibrary.simpleMessage('列表布局'),
    'semantics_main_player_header': MessageLookupByLibrary.simpleMessage('主播放器窗口'),
    'semantics_mark_episode_played': MessageLookupByLibrary.simpleMessage('将单集标为已听'),
    'semantics_mark_episode_unplayed': MessageLookupByLibrary.simpleMessage('将单集标为未听'),
    'semantics_play_pause_toggle': MessageLookupByLibrary.simpleMessage('播放与暂停开关'),
    'semantics_podcast_details_header': MessageLookupByLibrary.simpleMessage('播客详情和单集页面'),
    'semantics_remove_from_queue': MessageLookupByLibrary.simpleMessage('从队列移除单集'),
    'settings_auto_open_now_playing': MessageLookupByLibrary.simpleMessage('单集开始时的开启全屏模式'),
    'settings_auto_update_episodes': MessageLookupByLibrary.simpleMessage('自动更新节目单'),
    'settings_auto_update_episodes_10min': MessageLookupByLibrary.simpleMessage('距离上次更新已 10 分钟'),
    'settings_auto_update_episodes_12hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 12 小时'),
    'settings_auto_update_episodes_1hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 1 小时'),
    'settings_auto_update_episodes_30min': MessageLookupByLibrary.simpleMessage('距离上次更新已 30 分钟'),
    'settings_auto_update_episodes_3hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 3 小时'),
    'settings_auto_update_episodes_6hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 6 小时'),
    'settings_auto_update_episodes_always': MessageLookupByLibrary.simpleMessage('总是'),
    'settings_auto_update_episodes_heading': MessageLookupByLibrary.simpleMessage('刷新播客'),
    'settings_auto_update_episodes_never': MessageLookupByLibrary.simpleMessage('从不'),
    'settings_data_divider_label': MessageLookupByLibrary.simpleMessage('数据'),
    'settings_delete_played_label': MessageLookupByLibrary.simpleMessage('已下载的剧集播放后删除'),
    'settings_download_sd_card_label': MessageLookupByLibrary.simpleMessage('下载单集到 SD 卡'),
    'settings_download_switch_card': MessageLookupByLibrary.simpleMessage('新的下载内容将保存到 SD 卡。现有的内容将保留在内部存储空间。'),
    'settings_download_switch_internal': MessageLookupByLibrary.simpleMessage('新的下载内容将保存到内部存储空间。现有的内容将保留在 SD 卡上。'),
    'settings_download_switch_label': MessageLookupByLibrary.simpleMessage('更改存储位置'),
    'settings_episodes_divider_label': MessageLookupByLibrary.simpleMessage('单集'),
    'settings_export_opml': MessageLookupByLibrary.simpleMessage('导出 OPML'),
    'settings_import_opml': MessageLookupByLibrary.simpleMessage('导入 OPML'),
    'settings_label': MessageLookupByLibrary.simpleMessage('设置'),
    'settings_mark_deleted_played_label': MessageLookupByLibrary.simpleMessage('标记已删除的单集为已播放'),
    'settings_personalisation_divider_label': MessageLookupByLibrary.simpleMessage('个性化'),
    'settings_playback_divider_label': MessageLookupByLibrary.simpleMessage('播放'),
    'settings_theme': MessageLookupByLibrary.simpleMessage('主题'),
    'settings_theme_heading': MessageLookupByLibrary.simpleMessage('选择主题'),
    'settings_theme_value_auto': MessageLookupByLibrary.simpleMessage('系统主题'),
    'settings_theme_value_dark': MessageLookupByLibrary.simpleMessage('深色主题'),
    'settings_theme_value_light': MessageLookupByLibrary.simpleMessage('浅色主题'),
    'show_notes_label': MessageLookupByLibrary.simpleMessage('Show notes'),
    'sleep_off_label': MessageLookupByLibrary.simpleMessage('关闭'),
    'stop_download_button_label': MessageLookupByLibrary.simpleMessage('停止'),
    'stop_download_confirmation': MessageLookupByLibrary.simpleMessage('您确定要停止下载并删除该集吗？'),
    'stop_download_title': MessageLookupByLibrary.simpleMessage('停止下载'),
    'subscribe_button_label': MessageLookupByLibrary.simpleMessage('关注'),
    'subscribe_label': MessageLookupByLibrary.simpleMessage('关注'),
    'time_minutes': m15,
    'time_seconds': m16,
    'time_semantic_minutes': m17,
    'time_semantic_seconds': m18,
    'transcript_label': MessageLookupByLibrary.simpleMessage('转写'),
    'transcript_why_not_label': MessageLookupByLibrary.simpleMessage('为什么没有？'),
    'unsubscribe_button_label': MessageLookupByLibrary.simpleMessage('取消关注'),
    'unsubscribe_label': MessageLookupByLibrary.simpleMessage('取消关注'),
    'unsubscribe_message': MessageLookupByLibrary.simpleMessage('取消关注将删除此播客的所有已下载单集。'),
    'up_next_queue_label': MessageLookupByLibrary.simpleMessage('下一集')
  };
}
