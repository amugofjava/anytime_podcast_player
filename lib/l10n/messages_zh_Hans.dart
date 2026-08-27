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

typedef String? MessageIfAbsent(String? messageStr, List<Object>? args);

class MessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'zh_Hans';

  static m0(days) => "${Intl.plural(days, one: '一天前', other: '${days}天前')}";

  static m1(hours) => "${Intl.plural(hours, one: '1小时前', other: '${hours}小时前')}";

  static m2(minutes) => "${minutes} 分钟后结束";

  static m3(minutes) => "${Intl.plural(minutes, one: '1分钟前', other: '${minutes}分钟前')}";

  static m4(seconds) => "${seconds} 秒后结束";

  static m5(weeks) => "${Intl.plural(weeks, one: '一周前', other: '${weeks}周前')}";

  static m6(days) => "${Intl.plural(days, one: '1天前', other: '${days}天前')}";

  static m7(hours) => "${Intl.plural(hours, one: '1小时前', other: '${hours}小时前')}";

  static m8(minutes) => "剩余${minutes}分钟";

  static m9(minutes) => "${Intl.plural(minutes, one: '1分钟前', other: '${minutes}分钟前')}";

  static m10(seconds) => "剩余${seconds}秒";

  static m11(weeks) => "${Intl.plural(weeks, one: '1周前', other: '${weeks}周前')}";

  static m12(episodes) => "${Intl.plural(episodes, one: '1 集新节目', other: '${episodes} 集新节目')}";

  static m13(episodes) => "${Intl.plural(episodes, one: '1 集未播放', other: '${episodes} 集未播放')}";

  static m14(minutes) => "${minutes} 分钟";

  static m15(minutes) => "${minutes}分";

  static m16(seconds) => "${seconds}秒";

  static m17(minutes) => "${minutes}分钟";

  static m18(seconds) => "${seconds}秒";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(_) => {
        'about_label': MessageLookupByLibrary.simpleMessage('关于'),
        'active_downloads_empty_message': MessageLookupByLibrary.simpleMessage('暂无正在下载或转码的单集'),
        'add_rss_feed_option': MessageLookupByLibrary.simpleMessage('添加 RSS Feed'),
        'alert_sync_title_body': MessageLookupByLibrary.simpleMessage('Anytime 正在更新你的播客库'),
        'alert_sync_title_label': MessageLookupByLibrary.simpleMessage('播客库更新'),
        'app_title': MessageLookupByLibrary.simpleMessage('Anytime 播客播放器'),
        'app_title_short': MessageLookupByLibrary.simpleMessage('Anytime 播放器'),
        'audio_effect_trim_silence_label': MessageLookupByLibrary.simpleMessage('静音消除'),
        'audio_effect_volume_boost_label': MessageLookupByLibrary.simpleMessage('音量增强'),
        'audio_settings_playback_speed_label': MessageLookupByLibrary.simpleMessage('播放速度'),
        'auto_scroll_transcript_label': MessageLookupByLibrary.simpleMessage('跟随文稿'),
        'batch_action_delete': MessageLookupByLibrary.simpleMessage('批量删除'),
        'batch_action_mark_played': MessageLookupByLibrary.simpleMessage('标记已听'),
        'batch_action_mark_unplayed': MessageLookupByLibrary.simpleMessage('标记未听'),
        'batch_action_queue': MessageLookupByLibrary.simpleMessage('加到队列'),
        'batch_add_to_queue_success': MessageLookupByLibrary.simpleMessage('已添加到播放队列'),
        'batch_delete_dialog_message': MessageLookupByLibrary.simpleMessage('确定删除选中的已下载单集吗？此操作不可撤回。'),
        'batch_delete_dialog_title': MessageLookupByLibrary.simpleMessage('批量删除'),
        'cancel_button_label': MessageLookupByLibrary.simpleMessage('取消'),
        'cancel_download_button_label': MessageLookupByLibrary.simpleMessage('取消下载'),
        'cancel_option_label': MessageLookupByLibrary.simpleMessage('取消'),
        'chapters_label': MessageLookupByLibrary.simpleMessage('章节'),
        'clear_queue_button_label': MessageLookupByLibrary.simpleMessage('清空队列'),
        'clear_search_button_label': MessageLookupByLibrary.simpleMessage('清空搜索文本'),
        'close_button_label': MessageLookupByLibrary.simpleMessage('关闭'),
        'consent_message':
            MessageLookupByLibrary.simpleMessage('此资助链接将带您前往外部网站，您可以直接在该网站上支持本节目。链接由播客作者提供，不受 Anytime 控制。'),
        'continue_button_label': MessageLookupByLibrary.simpleMessage('继续'),
        'converting_episode_button_label': MessageLookupByLibrary.simpleMessage('正在转换格式'),
        'delete_button_label': MessageLookupByLibrary.simpleMessage('删除'),
        'delete_episode_button_label': MessageLookupByLibrary.simpleMessage('删除已下载的单集'),
        'delete_episode_confirmation': MessageLookupByLibrary.simpleMessage('您确定要删除此单集吗？'),
        'delete_episode_title': MessageLookupByLibrary.simpleMessage('删除单集'),
        'delete_label': MessageLookupByLibrary.simpleMessage('删除'),
        'discover': MessageLookupByLibrary.simpleMessage('发现'),
        'discovery_categories_itunes': MessageLookupByLibrary.simpleMessage(
            '全部,艺术,商业,喜剧,教育,小说,政府,健康与健身,历史,儿童与家庭,休闲,音乐,新闻,宗教与信仰,科学,社会与文化,体育,电视与电影,科技,真实犯罪'),
        'discovery_categories_pindex': MessageLookupByLibrary.simpleMessage(
            '全部,幕后花絮,另类,动物,动画,艺术,天文学,汽车,航空,棒球,篮球,美容,书籍,佛教,商业,职业,化学,基督教,气候,喜剧,评论,课程,手工艺,板球,加密货币,文化,每日,设计,纪录片,戏剧,地球,教育,娱乐,创业,家庭,奇幻,时尚,小说,电影,健身,食品,足球,游戏,园艺,高尔夫,政府,健康,印度教,历史,爱好,冰球,家居,教程,即兴,访谈,投资,伊斯兰教,日志,犹太教,儿童,语言,学习,休闲,生活,管理,漫画,营销,数学,医学,心理健康,音乐,自然,自然,新闻,非营利,营养,育儿,表演,个人,宠物,哲学,物理学,地方,政治,关系,宗教,评论,角色扮演,橄榄球,跑步,科学,自我提升,性,足球,社会,社会,心灵,体育,单口相声,故事,游泳,电视,桌面游戏,科技,网球,旅行,真实犯罪,视频游戏,视觉,排球,天气,荒野,摔跤'),
        'download_action_cancel': MessageLookupByLibrary.simpleMessage('取消'),
        'download_action_pause': MessageLookupByLibrary.simpleMessage('暂停'),
        'download_action_resume': MessageLookupByLibrary.simpleMessage('继续'),
        'download_action_retry': MessageLookupByLibrary.simpleMessage('重试'),
        'download_episode_button_label': MessageLookupByLibrary.simpleMessage('下载单集'),
        'download_status_converting': MessageLookupByLibrary.simpleMessage('转码中'),
        'download_status_downloading': MessageLookupByLibrary.simpleMessage('下载中'),
        'download_status_failed': MessageLookupByLibrary.simpleMessage('失败'),
        'download_status_paused': MessageLookupByLibrary.simpleMessage('已暂停'),
        'download_status_queued': MessageLookupByLibrary.simpleMessage('排队中'),
        'downloads': MessageLookupByLibrary.simpleMessage('下载'),
        'downloads_tab_active': MessageLookupByLibrary.simpleMessage('下载中'),
        'downloads_tab_downloaded': MessageLookupByLibrary.simpleMessage('已下载'),
        'empty_queue_message': MessageLookupByLibrary.simpleMessage('您的播放队列为空'),
        'episode_details_button_label': MessageLookupByLibrary.simpleMessage('显示单集信息'),
        'episode_filter_clear_filters_button_label': MessageLookupByLibrary.simpleMessage('清除筛选'),
        'episode_filter_no_episodes_title_description': MessageLookupByLibrary.simpleMessage('该播客没有符合你搜索条件和筛选的单集'),
        'episode_filter_no_episodes_title_label': MessageLookupByLibrary.simpleMessage('未找到单集'),
        'episode_filter_none_label': MessageLookupByLibrary.simpleMessage('无'),
        'episode_filter_played_label': MessageLookupByLibrary.simpleMessage('已播放'),
        'episode_filter_semantic_label': MessageLookupByLibrary.simpleMessage('筛选单集'),
        'episode_filter_started_label': MessageLookupByLibrary.simpleMessage('已开始'),
        'episode_filter_unplayed_label': MessageLookupByLibrary.simpleMessage('未播放'),
        'episode_label': MessageLookupByLibrary.simpleMessage('单集'),
        'episode_semantic_time_days_ago': m0,
        'episode_semantic_time_hours_ago': m1,
        'episode_semantic_time_minute_remaining': m2,
        'episode_semantic_time_minutes_ago': m3,
        'episode_semantic_time_second_remaining': m4,
        'episode_semantic_time_weeks_ago': m5,
        'episode_sort_alphabetical_ascending_label': MessageLookupByLibrary.simpleMessage('按字母 A-Z'),
        'episode_sort_alphabetical_descending_label': MessageLookupByLibrary.simpleMessage('按字母 Z-A'),
        'episode_sort_earliest_first_label': MessageLookupByLibrary.simpleMessage('最早的在前'),
        'episode_sort_latest_first_label': MessageLookupByLibrary.simpleMessage('最新的在前'),
        'episode_sort_none_label': MessageLookupByLibrary.simpleMessage('默认'),
        'episode_sort_semantic_label': MessageLookupByLibrary.simpleMessage('对单集排序'),
        'episode_time_days_ago': m6,
        'episode_time_hours_ago': m7,
        'episode_time_minute_remaining': m8,
        'episode_time_minutes_ago': m9,
        'episode_time_now': MessageLookupByLibrary.simpleMessage('刚刚'),
        'episode_time_second_remaining': m10,
        'episode_time_weeks_ago': m11,
        'error_no_connection': MessageLookupByLibrary.simpleMessage('无法播放该单集。请检查您的连接并重试。'),
        'error_playback_fail': MessageLookupByLibrary.simpleMessage('播放过程中出现意外错误。请检查您的连接并重试。'),
        'fast_forward_button_label': MessageLookupByLibrary.simpleMessage('单集快进 30 秒'),
        'feedback_menu_item_label': MessageLookupByLibrary.simpleMessage('反馈'),
        'go_back_button_label': MessageLookupByLibrary.simpleMessage('返回'),
        'label_episode_actions': MessageLookupByLibrary.simpleMessage('单集操作'),
        'label_megabytes': MessageLookupByLibrary.simpleMessage('兆字节'),
        'label_megabytes_abbr': MessageLookupByLibrary.simpleMessage('MB'),
        'label_opml_importing': MessageLookupByLibrary.simpleMessage('导入中'),
        'label_podcast_actions': MessageLookupByLibrary.simpleMessage('播客操作'),
        'layout_label': MessageLookupByLibrary.simpleMessage('布局'),
        'layout_selector_compact_grid_view': MessageLookupByLibrary.simpleMessage('紧凑网格视图'),
        'layout_selector_grid_view': MessageLookupByLibrary.simpleMessage('网格视图'),
        'layout_selector_highlight_new_episodes': MessageLookupByLibrary.simpleMessage('突出显示新单集'),
        'layout_selector_list_view': MessageLookupByLibrary.simpleMessage('列表视图'),
        'layout_selector_sort_by': MessageLookupByLibrary.simpleMessage('排序方式'),
        'layout_selector_sort_by_alphabetical': MessageLookupByLibrary.simpleMessage('按字母'),
        'layout_selector_sort_by_followed': MessageLookupByLibrary.simpleMessage('按关注'),
        'layout_selector_sort_by_unplayed': MessageLookupByLibrary.simpleMessage('按未播放'),
        'layout_selector_unplayed_episodes': MessageLookupByLibrary.simpleMessage('显示未播数量'),
        'library': MessageLookupByLibrary.simpleMessage('库'),
        'library_sort_alphabetical_label': MessageLookupByLibrary.simpleMessage('按字母排序'),
        'library_sort_date_followed_label': MessageLookupByLibrary.simpleMessage('按关注日期'),
        'library_sort_latest_episodes_label': MessageLookupByLibrary.simpleMessage('最新单集'),
        'library_sort_unplayed_count_label': MessageLookupByLibrary.simpleMessage('未播放单集'),
        'mark_episodes_not_played_label': MessageLookupByLibrary.simpleMessage('标记全部单集为未听'),
        'mark_episodes_played_label': MessageLookupByLibrary.simpleMessage('标记全部单集为已听'),
        'mark_played_label': MessageLookupByLibrary.simpleMessage('标为已听'),
        'mark_unplayed_label': MessageLookupByLibrary.simpleMessage('标为未听'),
        'minimise_player_window_button_label': MessageLookupByLibrary.simpleMessage('最小化播放器窗口'),
        'more_label': MessageLookupByLibrary.simpleMessage('更多'),
        'multi_select_deselect_all': MessageLookupByLibrary.simpleMessage('取消全选'),
        'multi_select_exit': MessageLookupByLibrary.simpleMessage('退出'),
        'multi_select_select_all': MessageLookupByLibrary.simpleMessage('全选'),
        'new_episodes_label': MessageLookupByLibrary.simpleMessage('有新单集上线'),
        'new_episodes_view_now_label': MessageLookupByLibrary.simpleMessage('立即查看'),
        'no_downloads_message': MessageLookupByLibrary.simpleMessage('您暂未下载任何单集'),
        'no_podcast_details_message': MessageLookupByLibrary.simpleMessage('无法加载播客节目。请检查您的连接。'),
        'no_search_results_message': MessageLookupByLibrary.simpleMessage('未找到播客'),
        'no_subscriptions_message': MessageLookupByLibrary.simpleMessage('点击下方的“发现”按钮或使用上面的搜索栏查找您的第一个播客'),
        'no_transcript_available_label': MessageLookupByLibrary.simpleMessage('此播客暂无转写'),
        'notes_label': MessageLookupByLibrary.simpleMessage('备注'),
        'now_playing_episode_position': MessageLookupByLibrary.simpleMessage('单集进度'),
        'now_playing_episode_time_remaining': MessageLookupByLibrary.simpleMessage('剩余时间'),
        'now_playing_queue_label': MessageLookupByLibrary.simpleMessage('正在播放'),
        'ok_button_label': MessageLookupByLibrary.simpleMessage('确定'),
        'open_show_website_label': MessageLookupByLibrary.simpleMessage('打开节目网站'),
        'open_up_next_hint': MessageLookupByLibrary.simpleMessage('打开「接下来播放」队列'),
        'opml_export_button_label': MessageLookupByLibrary.simpleMessage('导出'),
        'opml_import_button_label': MessageLookupByLibrary.simpleMessage('导入'),
        'opml_import_export_label': MessageLookupByLibrary.simpleMessage('OPML 导入/导出'),
        'pause_button_label': MessageLookupByLibrary.simpleMessage('暂停单集'),
        'play_button_label': MessageLookupByLibrary.simpleMessage('播放单集'),
        'play_download_button_label': MessageLookupByLibrary.simpleMessage('播放已下载单集'),
        'playback_speed_label': MessageLookupByLibrary.simpleMessage('播放速度'),
        'playing_next_queue_label': MessageLookupByLibrary.simpleMessage('接下来播放'),
        'podcast_context_play_latest_episode_label': MessageLookupByLibrary.simpleMessage('播放最新单集'),
        'podcast_context_play_next_episode_label': MessageLookupByLibrary.simpleMessage('播放下一集未播放单集'),
        'podcast_context_queue_latest_episode_label': MessageLookupByLibrary.simpleMessage('将最新单集加入队列'),
        'podcast_context_queue_next_episode_label': MessageLookupByLibrary.simpleMessage('将下一集未播放单集加入队列'),
        'podcast_funding_dialog_header': MessageLookupByLibrary.simpleMessage('播客赞助'),
        'podcast_options_overflow_menu_semantic_label': MessageLookupByLibrary.simpleMessage('选项菜单'),
        'queue_add_label': MessageLookupByLibrary.simpleMessage('添加'),
        'queue_clear_button_label': MessageLookupByLibrary.simpleMessage('清除'),
        'queue_clear_label': MessageLookupByLibrary.simpleMessage('您确定要清除队列吗？'),
        'queue_clear_label_title': MessageLookupByLibrary.simpleMessage('清空队列'),
        'queue_remove_label': MessageLookupByLibrary.simpleMessage('删除'),
        'refresh_feed_label': MessageLookupByLibrary.simpleMessage('刷新单集'),
        'resume_button_label': MessageLookupByLibrary.simpleMessage('继续播放单集'),
        'rewind_button_label': MessageLookupByLibrary.simpleMessage('单集倒回 10 秒'),
        'scrim_episode_details_selector': MessageLookupByLibrary.simpleMessage('关闭单集详情'),
        'scrim_episode_filter_selector': MessageLookupByLibrary.simpleMessage('关闭单集筛选'),
        'scrim_episode_sort_selector': MessageLookupByLibrary.simpleMessage('关闭单集排序'),
        'scrim_layout_selector': MessageLookupByLibrary.simpleMessage('关闭布局选择器'),
        'scrim_sleep_timer_selector': MessageLookupByLibrary.simpleMessage('关闭睡眠定时器选择器'),
        'scrim_speed_selector': MessageLookupByLibrary.simpleMessage('关闭播放速度选择器'),
        'search_back_button_label': MessageLookupByLibrary.simpleMessage('后退'),
        'search_button_label': MessageLookupByLibrary.simpleMessage('搜索'),
        'search_episodes_label': MessageLookupByLibrary.simpleMessage('搜索单集'),
        'search_for_podcasts_hint': MessageLookupByLibrary.simpleMessage('搜索播客'),
        'search_provider_label': MessageLookupByLibrary.simpleMessage('搜索提供方'),
        'search_transcript_label': MessageLookupByLibrary.simpleMessage('搜索转写'),
        'semantic_announce_loading': MessageLookupByLibrary.simpleMessage('加载中，请稍候。'),
        'semantic_announce_searching': MessageLookupByLibrary.simpleMessage('正在搜索，请稍候。'),
        'semantic_chapter_link_label': MessageLookupByLibrary.simpleMessage('章节网页链接'),
        'semantic_current_chapter_label': MessageLookupByLibrary.simpleMessage('当前章节'),
        'semantic_current_value_label': MessageLookupByLibrary.simpleMessage('当前值'),
        'semantic_new_episodes_count': m12,
        'semantic_playing_options_collapse_label': MessageLookupByLibrary.simpleMessage('关闭播放选项滑块'),
        'semantic_playing_options_expand_label': MessageLookupByLibrary.simpleMessage('打开播放选项滑块'),
        'semantic_podcast_artwork_label': MessageLookupByLibrary.simpleMessage('播客封面图'),
        'semantic_unplayed_episodes_count': m13,
        'semantics_add_to_queue': MessageLookupByLibrary.simpleMessage('添加单集到队列'),
        'semantics_collapse_podcast_description': MessageLookupByLibrary.simpleMessage('收起播客描述'),
        'semantics_decrease_playback_speed': MessageLookupByLibrary.simpleMessage('降低播放速度'),
        'semantics_episode_tile_collapsed': MessageLookupByLibrary.simpleMessage('单集列表项。显示图片、摘要和主要控件。'),
        'semantics_episode_tile_collapsed_hint': MessageLookupByLibrary.simpleMessage('展开以查看更多详情和附加选项'),
        'semantics_episode_tile_expanded': MessageLookupByLibrary.simpleMessage('单集列表项。显示描述、主要控件和附加控件。'),
        'semantics_episode_tile_expanded_hint': MessageLookupByLibrary.simpleMessage('收起以显示摘要、下载和播放控件'),
        'semantics_expand_podcast_description': MessageLookupByLibrary.simpleMessage('展开播客描述'),
        'semantics_increase_playback_speed': MessageLookupByLibrary.simpleMessage('增加播放速度'),
        'semantics_layout_option_compact_grid': MessageLookupByLibrary.simpleMessage('紧凑的网格布局'),
        'semantics_layout_option_grid': MessageLookupByLibrary.simpleMessage('网格布局'),
        'semantics_layout_option_list': MessageLookupByLibrary.simpleMessage('列表布局'),
        'semantics_main_player_header': MessageLookupByLibrary.simpleMessage('主播放器窗口'),
        'semantics_mark_episode_played': MessageLookupByLibrary.simpleMessage('将单集标为已听'),
        'semantics_mark_episode_unplayed': MessageLookupByLibrary.simpleMessage('将单集标为未听'),
        'semantics_mini_player_header': MessageLookupByLibrary.simpleMessage('迷你播放器。向右滑动到播放/暂停按钮。激活以打开主播放器窗口'),
        'semantics_play_pause_toggle': MessageLookupByLibrary.simpleMessage('播放与暂停开关'),
        'semantics_podcast_details_header': MessageLookupByLibrary.simpleMessage('播客详情和单集页面'),
        'semantics_remove_from_queue': MessageLookupByLibrary.simpleMessage('从队列移除单集'),
        'settings_auto_open_now_playing': MessageLookupByLibrary.simpleMessage('单集开始时的开启全屏模式'),
        'settings_auto_update_episodes': MessageLookupByLibrary.simpleMessage('自动更新节目单'),
        'settings_auto_update_episodes_10min': MessageLookupByLibrary.simpleMessage('距离上次更新已 10 分钟'),
        'settings_auto_update_episodes_12hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 12 小时'),
        'settings_auto_update_episodes_1hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 1 小时'),
        'settings_auto_update_episodes_24hour': MessageLookupByLibrary.simpleMessage('每 24 小时'),
        'settings_auto_update_episodes_30min': MessageLookupByLibrary.simpleMessage('距离上次更新已 30 分钟'),
        'settings_auto_update_episodes_3hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 3 小时'),
        'settings_auto_update_episodes_48hour': MessageLookupByLibrary.simpleMessage('每 2 天'),
        'settings_auto_update_episodes_6hour': MessageLookupByLibrary.simpleMessage('距离上次更新已 6 小时'),
        'settings_auto_update_episodes_always': MessageLookupByLibrary.simpleMessage('总是'),
        'settings_auto_update_episodes_heading': MessageLookupByLibrary.simpleMessage('刷新播客'),
        'settings_auto_update_episodes_never': MessageLookupByLibrary.simpleMessage('从不'),
        'settings_background_refresh_mobile_data_option': MessageLookupByLibrary.simpleMessage('使用移动数据时刷新'),
        'settings_background_refresh_mobile_data_option_subtitle':
            MessageLookupByLibrary.simpleMessage('允许在使用移动数据时刷新播客库'),
        'settings_background_refresh_option': MessageLookupByLibrary.simpleMessage('后台刷新'),
        'settings_background_refresh_option_subtitle': MessageLookupByLibrary.simpleMessage('在屏幕关闭时刷新单集。这会增加电量消耗。'),
        'settings_continuous_play_option': MessageLookupByLibrary.simpleMessage('连续播放'),
        'settings_continuous_play_subtitle': MessageLookupByLibrary.simpleMessage('队列为空时自动播放该播客的下一集'),
        'settings_convert_to_mp3_label': MessageLookupByLibrary.simpleMessage('转成 MP3'),
        'settings_convert_to_mp3_subtitle': MessageLookupByLibrary.simpleMessage('自动将下载的单集转成 MP3'),
        'settings_custom_download_path_default': MessageLookupByLibrary.simpleMessage('默认'),
        'settings_custom_download_path_label': MessageLookupByLibrary.simpleMessage('自定义下载目录'),
        'settings_custom_download_path_permission_message':
            MessageLookupByLibrary.simpleMessage('若要将播客音频保存至外部自定义文件夹，Anytime 需要“所有文件访问权限”。'),
        'settings_custom_download_path_permission_title': MessageLookupByLibrary.simpleMessage('需要存储管理权限'),
        'settings_custom_download_path_reset': MessageLookupByLibrary.simpleMessage('恢复默认目录'),
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
        'settings_language_chinese': MessageLookupByLibrary.simpleMessage('中文'),
        'settings_language_english': MessageLookupByLibrary.simpleMessage('English'),
        'settings_language_label': MessageLookupByLibrary.simpleMessage('语言'),
        'settings_language_system': MessageLookupByLibrary.simpleMessage('跟随系统'),
        'settings_mark_deleted_played_label': MessageLookupByLibrary.simpleMessage('标记已删除的单集为已播放'),
        'settings_notification_divider_label': MessageLookupByLibrary.simpleMessage('通知'),
        'settings_personalisation_divider_label': MessageLookupByLibrary.simpleMessage('个性化'),
        'settings_playback_divider_label': MessageLookupByLibrary.simpleMessage('播放'),
        'settings_podcast_management_divider_label': MessageLookupByLibrary.simpleMessage('播客管理'),
        'settings_refresh_notification_option': MessageLookupByLibrary.simpleMessage('刷新通知'),
        'settings_refresh_notification_option_subtitle': MessageLookupByLibrary.simpleMessage('刷新单集时显示通知图标'),
        'settings_theme': MessageLookupByLibrary.simpleMessage('主题'),
        'settings_theme_heading': MessageLookupByLibrary.simpleMessage('选择主题'),
        'settings_theme_value_auto': MessageLookupByLibrary.simpleMessage('系统主题'),
        'settings_theme_value_dark': MessageLookupByLibrary.simpleMessage('深色主题'),
        'settings_theme_value_light': MessageLookupByLibrary.simpleMessage('浅色主题'),
        'share_episode_option_label': MessageLookupByLibrary.simpleMessage('分享单集'),
        'share_podcast_option_label': MessageLookupByLibrary.simpleMessage('分享播客'),
        'show_notes_label': MessageLookupByLibrary.simpleMessage('Show notes'),
        'sleep_episode_label': MessageLookupByLibrary.simpleMessage('本集播完时'),
        'sleep_minute_label': m14,
        'sleep_off_label': MessageLookupByLibrary.simpleMessage('关闭'),
        'sleep_timer_label': MessageLookupByLibrary.simpleMessage('睡眠定时器'),
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
        'transcript_why_not_url':
            MessageLookupByLibrary.simpleMessage('https://anytimeplayer.app/docs/anytime_transcript_support_en.html'),
        'unsubscribe_button_label': MessageLookupByLibrary.simpleMessage('取消关注'),
        'unsubscribe_label': MessageLookupByLibrary.simpleMessage('取消关注'),
        'unsubscribe_message': MessageLookupByLibrary.simpleMessage('取消关注将删除此播客的所有已下载单集。'),
        'up_next_queue_label': MessageLookupByLibrary.simpleMessage('下一集'),
        'update_library_option': MessageLookupByLibrary.simpleMessage('刷新播客库')
      };
}
