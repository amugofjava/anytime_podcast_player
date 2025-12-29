// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
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
  String get localeName => 'ru';

  static m0(days) => "${Intl.plural(days, one: 'О��ин день назад', other: '${days} дня назад')}";

  static m1(hours) => "${Intl.plural(hours, one: '${hours} час назад', other: '${hours} часов назад')}";

  static m2(minutes) => "${minutes} минут осталось";

  static m3(minutes) => "${Intl.plural(minutes, one: '1 минуту назад', other: '${minutes} минут назад')}";

  static m4(seconds) => "${seconds} секунд осталось";

  static m5(weeks) => "${Intl.plural(weeks, one: 'Одна неделя назад', other: '${weeks} недели назад')}";

  static m6(days) => "${Intl.plural(days, one: '1д назад', other: '${days}д назад')}";

  static m7(hours) => "${Intl.plural(hours, one: '1ч назад', other: '${hours}ч назад')}";

  static m8(minutes) => "${minutes} мин осталось";

  static m9(minutes) => "${Intl.plural(minutes, one: '1м назад', other: '${minutes}м назад')}";

  static m10(seconds) => "${seconds} сек осталось";

  static m11(weeks) => "${Intl.plural(weeks, one: '1н назад', other: '${weeks}н назад')}";

  static m12(episodes) => "${Intl.plural(episodes, one: '1 новый выпуск', other: '${episodes} новых выпусков')}";

  static m13(episodes) => "${Intl.plural(episodes, one: '1 непрослушаный выпуск', other: '${episodes} непрослушаных выпусков')}";

  static m14(minutes) => "${minutes} минут";

  static m15(minutes) => "${minutes} мин";

  static m16(seconds) => "${seconds} сек";

  static m17(minutes) => "${minutes} минут";

  static m18(seconds) => "${seconds} секунд";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(_) => {
      'about_label': MessageLookupByLibrary.simpleMessage('О приложении'),
    'add_rss_feed_option': MessageLookupByLibrary.simpleMessage('Добавить RSS ленту'),
    'alert_sync_title_body': MessageLookupByLibrary.simpleMessage('Anytime обновляет вашу библиотеку подкастов'),
    'alert_sync_title_label': MessageLookupByLibrary.simpleMessage('Обновление библиотеки'),
    'app_title': MessageLookupByLibrary.simpleMessage('Плеер подкастов Anytime'),
    'app_title_short': MessageLookupByLibrary.simpleMessage('Плеер Anytime'),
    'audio_effect_trim_silence_label': MessageLookupByLibrary.simpleMessage('Обрезать тишину'),
    'audio_effect_volume_boost_label': MessageLookupByLibrary.simpleMessage('Усиление громкости'),
    'audio_settings_playback_speed_label': MessageLookupByLibrary.simpleMessage('Скорость воспроизведения'),
    'auto_scroll_transcript_label': MessageLookupByLibrary.simpleMessage('Следовать по субтитрам'),
    'cancel_button_label': MessageLookupByLibrary.simpleMessage('Отмена'),
    'cancel_download_button_label': MessageLookupByLibrary.simpleMessage('Отменить скачивание'),
    'cancel_option_label': MessageLookupByLibrary.simpleMessage('Отменить'),
    'chapters_label': MessageLookupByLibrary.simpleMessage('Главы'),
    'clear_queue_button_label': MessageLookupByLibrary.simpleMessage('ОЧИСТИТЬ ОЧЕРЕДЬ'),
    'clear_search_button_label': MessageLookupByLibrary.simpleMessage('Очистить текст поиска'),
    'close_button_label': MessageLookupByLibrary.simpleMessage('Закрыть'),
    'consent_message': MessageLookupByLibrary.simpleMessage('Эта ссылка на финансирование приведёт вас на внешний сайт, где вы сможете напрямую поддерживать шоу. Ссылки предоставляются авторами подкаста и не контролируются Энитаймом.'),
    'continue_button_label': MessageLookupByLibrary.simpleMessage('Продолжить'),
    'delete_button_label': MessageLookupByLibrary.simpleMessage('Удалить'),
    'delete_episode_button_label': MessageLookupByLibrary.simpleMessage('Удалить скачанный выпуск'),
    'delete_episode_confirmation': MessageLookupByLibrary.simpleMessage('Вы уверены, что хотите удалить этот выпуск?'),
    'delete_episode_title': MessageLookupByLibrary.simpleMessage('Удалить выпуск'),
    'delete_label': MessageLookupByLibrary.simpleMessage('Удалить'),
    'discover': MessageLookupByLibrary.simpleMessage('Обзор'),
    'discovery_categories_itunes': MessageLookupByLibrary.simpleMessage('Все,Искусство,Предпринимательство,Комедия,Образование,Художественная литература,Государство,Здоровье и фитнес,История,Дети и семья,Досуг,Музыка,Новости,Религия и духовность,Наука,Общество и культура,Спорт,ТВ и кино,Технологии,Следствие вели'),
    'discovery_categories_pindex': MessageLookupByLibrary.simpleMessage('Все,После шоу,Альтернатива,Животные,Анимация,Искусство,Астрономия,Автомобили,Авиация,Бейсбол,Баскетбол,Красота,Книги,Буддизм,Предпринимательство,Карьера,Химия,Христианство,Климат,Комедия,Комментарии,Курсы,Ремёсла,Крикет,Криптовалюта,Культура,Ежедневные,Дизайн,Документальные,Драма,Земля,Образование,Развлечения,Предпринимательство,Семья,Фэнтези,Мода,Художественная литература,Фильм,Фитнес,Еда,Футбол,Игры,Сад,Гольф,Государство,Здоровье,Индуизм,История,Хобби,Хоккей,Дом,Советы,Импровизации,Интервью,Инвестиции,Ислам,Журналы,Иудаизм,Дети,Языки,Обучение,Досуг,Жизнь,Менеджмент,Манга,М��ркетинг,Математика,Медицина,Умственный,Музыка,Естественный,Природа,Новости,Сообщества,Питание,Воспитание детей,Выступление,Личное,Домашние животные,Философия,Физика,Места,Политика,Отношения,Религия,Обзоры,Ролевые игры,Регби,Бег,Наука,Самосовершенствование,Сексуальность,Футбол,Социальное,Общество,Духовность,Спорт,Стендап,Истории,Плавание,ТВ,Настолки,Технологии,Теннис,Путешествия,Следствие вели,Видеоигры,Визуальные,Волейбол,Погода,Дикая местность,Борьба'),
    'download_episode_button_label': MessageLookupByLibrary.simpleMessage('Скачать выпуск'),
    'downloads': MessageLookupByLibrary.simpleMessage('Скачивания'),
    'empty_queue_message': MessageLookupByLibrary.simpleMessage('Ваша очередь пуста'),
    'episode_details_button_label': MessageLookupByLibrary.simpleMessage('Показать информацию выпуска'),
    'episode_filter_clear_filters_button_label': MessageLookupByLibrary.simpleMessage('Очистить фильтры'),
    'episode_filter_no_episodes_title_description': MessageLookupByLibrary.simpleMessage('В этом подкасте нет выпусков по вашим критериям поиска и фильтру'),
    'episode_filter_no_episodes_title_label': MessageLookupByLibrary.simpleMessage('Не найдено выпусков'),
    'episode_filter_none_label': MessageLookupByLibrary.simpleMessage('Никаких'),
    'episode_filter_played_label': MessageLookupByLibrary.simpleMessage('Прослушано'),
    'episode_filter_semantic_label': MessageLookupByLibrary.simpleMessage('Отфильтровать выпуски'),
    'episode_filter_started_label': MessageLookupByLibrary.simpleMessage('Начался'),
    'episode_filter_unplayed_label': MessageLookupByLibrary.simpleMessage('Непрослушано'),
    'episode_label': MessageLookupByLibrary.simpleMessage('Выпуск'),
    'episode_semantic_time_days_ago': m0,
    'episode_semantic_time_hours_ago': m1,
    'episode_semantic_time_minute_remaining': m2,
    'episode_semantic_time_minutes_ago': m3,
    'episode_semantic_time_second_remaining': m4,
    'episode_semantic_time_weeks_ago': m5,
    'episode_sort_alphabetical_ascending_label': MessageLookupByLibrary.simpleMessage('По алфавиту А-Я'),
    'episode_sort_alphabetical_descending_label': MessageLookupByLibrary.simpleMessage('По алфавиту Я-А'),
    'episode_sort_earliest_first_label': MessageLookupByLibrary.simpleMessage('Сначала ранние'),
    'episode_sort_latest_first_label': MessageLookupByLibrary.simpleMessage('Сначала последние'),
    'episode_sort_none_label': MessageLookupByLibrary.simpleMessage('По умолчанию'),
    'episode_sort_semantic_label': MessageLookupByLibrary.simpleMessage('Сортировать выпуски'),
    'episode_time_days_ago': m6,
    'episode_time_hours_ago': m7,
    'episode_time_minute_remaining': m8,
    'episode_time_minutes_ago': m9,
    'episode_time_now': MessageLookupByLibrary.simpleMessage('Сейчас'),
    'episode_time_second_remaining': m10,
    'episode_time_weeks_ago': m11,
    'error_no_connection': MessageLookupByLibrary.simpleMessage('Не могу воспроизвести эпизод. Проверьте соединение и попробуйте ещё раз.'),
    'error_playback_fail': MessageLookupByLibrary.simpleMessage('При воспроизведении произошла неожиданная ошибка. Проверьте соединение и попробуйте еще раз.'),
    'fast_forward_button_label': MessageLookupByLibrary.simpleMessage('Промотать выпуск на 30 секунд'),
    'feedback_menu_item_label': MessageLookupByLibrary.simpleMessage('Обратная связь'),
    'go_back_button_label': MessageLookupByLibrary.simpleMessage('Перейти назад'),
    'label_episode_actions': MessageLookupByLibrary.simpleMessage('Действия'),
    'label_megabytes': MessageLookupByLibrary.simpleMessage('мегабайт'),
    'label_megabytes_abbr': MessageLookupByLibrary.simpleMessage('mb'),
    'label_opml_importing': MessageLookupByLibrary.simpleMessage('Импортирование'),
    'label_podcast_actions': MessageLookupByLibrary.simpleMessage('Действия подкаста'),
    'layout_label': MessageLookupByLibrary.simpleMessage('Макет'),
    'layout_selector_compact_grid_view': MessageLookupByLibrary.simpleMessage('Сжатый сеточный вид'),
    'layout_selector_grid_view': MessageLookupByLibrary.simpleMessage('Сеточный вид'),
    'layout_selector_highlight_new_episodes': MessageLookupByLibrary.simpleMessage('Отмечать новые выпуски'),
    'layout_selector_list_view': MessageLookupByLibrary.simpleMessage('Списочный вид'),
    'layout_selector_sort_by': MessageLookupByLibrary.simpleMessage('Сортировать по'),
    'layout_selector_sort_by_alphabetical': MessageLookupByLibrary.simpleMessage('Алфавитный'),
    'layout_selector_sort_by_followed': MessageLookupByLibrary.simpleMessage('Подписано'),
    'layout_selector_sort_by_unplayed': MessageLookupByLibrary.simpleMessage('Непрослушано'),
    'layout_selector_unplayed_episodes': MessageLookupByLibrary.simpleMessage('Показывать число непрослушаных'),
    'library': MessageLookupByLibrary.simpleMessage('Библиотека'),
    'library_sort_alphabetical_label': MessageLookupByLibrary.simpleMessage('Алфавитный'),
    'library_sort_date_followed_label': MessageLookupByLibrary.simpleMessage('Дата подписки'),
    'library_sort_latest_episodes_label': MessageLookupByLibrary.simpleMessage('Последние выпуски'),
    'library_sort_unplayed_count_label': MessageLookupByLibrary.simpleMessage('Непрослушаные выпуски'),
    'mark_episodes_not_played_label': MessageLookupByLibrary.simpleMessage('Отметить все выпуски как ещё непрослушанные'),
    'mark_episodes_played_label': MessageLookupByLibrary.simpleMessage('Отметить все выпуски как прослушанные'),
    'mark_played_label': MessageLookupByLibrary.simpleMessage('Отметить прослушанным'),
    'mark_unplayed_label': MessageLookupByLibrary.simpleMessage('Отметить непрослушанным'),
    'minimise_player_window_button_label': MessageLookupByLibrary.simpleMessage('Свернуть окно проигрывателя'),
    'more_label': MessageLookupByLibrary.simpleMessage('Ещё'),
    'new_episodes_label': MessageLookupByLibrary.simpleMessage('Доступны новые выпуски'),
    'new_episodes_view_now_label': MessageLookupByLibrary.simpleMessage('СЛУШАТЬ СЕЙЧАС'),
    'no_downloads_message': MessageLookupByLibrary.simpleMessage('У вас нет скачанных выпусков'),
    'no_podcast_details_message': MessageLookupByLibrary.simpleMessage('Не удалось скачать выпуски подкаста. Пожалуйста, проверьте соединение.'),
    'no_search_results_message': MessageLookupByLibrary.simpleMessage('Подкасты не найдены'),
    'no_subscriptions_message': MessageLookupByLibrary.simpleMessage('Нажмите кнопку Обзор ниже или используйте панель поиска выше, чтобы найти свой первый подкаст'),
    'no_transcript_available_label': MessageLookupByLibrary.simpleMessage('Субтитры недоступны для этого подкаста'),
    'notes_label': MessageLookupByLibrary.simpleMessage('Заметки'),
    'now_playing_episode_position': MessageLookupByLibrary.simpleMessage('Позиция в выпуске'),
    'now_playing_episode_time_remaining': MessageLookupByLibrary.simpleMessage('Осталось'),
    'now_playing_queue_label': MessageLookupByLibrary.simpleMessage('Сейчас слушаете'),
    'ok_button_label': MessageLookupByLibrary.simpleMessage('Ладно'),
    'open_show_website_label': MessageLookupByLibrary.simpleMessage('Открыть вебсайт шоу'),
    'open_up_next_hint': MessageLookupByLibrary.simpleMessage('Открыть очередь'),
    'opml_export_button_label': MessageLookupByLibrary.simpleMessage('Экспортировать'),
    'opml_import_button_label': MessageLookupByLibrary.simpleMessage('Импортировать'),
    'opml_import_export_label': MessageLookupByLibrary.simpleMessage('Экспорт OPML и импорт'),
    'pause_button_label': MessageLookupByLibrary.simpleMessage('Приостановить выпуск'),
    'play_button_label': MessageLookupByLibrary.simpleMessage('Слушать выпуск'),
    'play_download_button_label': MessageLookupByLibrary.simpleMessage('Прослушать скачанный выпуск'),
    'playback_speed_label': MessageLookupByLibrary.simpleMessage('Скорость воспроизведения'),
    'playing_next_queue_label': MessageLookupByLibrary.simpleMessage('Следующее играть'),
    'podcast_context_play_latest_episode_label': MessageLookupByLibrary.simpleMessage('Слушать последний выпуск'),
    'podcast_context_play_next_episode_label': MessageLookupByLibrary.simpleMessage('Играть следующий непрослушаный выпуск'),
    'podcast_context_queue_latest_episode_label': MessageLookupByLibrary.simpleMessage('Последний выпуск в очередь'),
    'podcast_context_queue_next_episode_label': MessageLookupByLibrary.simpleMessage('Следующий непрослушаный выпуск в очередь'),
    'podcast_funding_dialog_header': MessageLookupByLibrary.simpleMessage('Финансирование подкастов'),
    'podcast_options_overflow_menu_semantic_label': MessageLookupByLibrary.simpleMessage('Меню опций'),
    'queue_add_label': MessageLookupByLibrary.simpleMessage('Добавить'),
    'queue_clear_button_label': MessageLookupByLibrary.simpleMessage('Очистить'),
    'queue_clear_label': MessageLookupByLibrary.simpleMessage('Вы уверены, что хотите очистить очередь?'),
    'queue_clear_label_title': MessageLookupByLibrary.simpleMessage('Очистить очередь'),
    'queue_remove_label': MessageLookupByLibrary.simpleMessage('Убрать'),
    'refresh_feed_label': MessageLookupByLibrary.simpleMessage('Обновить выпуски'),
    'resume_button_label': MessageLookupByLibrary.simpleMessage('Продолжить слушать'),
    'rewind_button_label': MessageLookupByLibrary.simpleMessage('Промотать выпуск на 10 секунд'),
    'scrim_episode_details_selector': MessageLookupByLibrary.simpleMessage('Скрыть подробности выпуска'),
    'scrim_episode_filter_selector': MessageLookupByLibrary.simpleMessage('Скрыть фильтр выпусков'),
    'scrim_episode_sort_selector': MessageLookupByLibrary.simpleMessage('Скрыть сортировку выпусков'),
    'scrim_layout_selector': MessageLookupByLibrary.simpleMessage('Скрыть выбор макета'),
    'scrim_sleep_timer_selector': MessageLookupByLibrary.simpleMessage('Скрыть выбор таймера сна'),
    'scrim_speed_selector': MessageLookupByLibrary.simpleMessage('Скрыть выбор скорости воспроизведения'),
    'search_back_button_label': MessageLookupByLibrary.simpleMessage('Назад'),
    'search_button_label': MessageLookupByLibrary.simpleMessage('Поиск'),
    'search_episodes_label': MessageLookupByLibrary.simpleMessage('Поиск выпусков'),
    'search_for_podcasts_hint': MessageLookupByLibrary.simpleMessage('Поиск подкастов'),
    'search_provider_label': MessageLookupByLibrary.simpleMessage('Поставщик поиска'),
    'search_transcript_label': MessageLookupByLibrary.simpleMessage('Поиск субтитров'),
    'semantic_announce_loading': MessageLookupByLibrary.simpleMessage('Загрузка, пожалуйста, подождите.'),
    'semantic_announce_searching': MessageLookupByLibrary.simpleMessage('Ищу, пожалуйста подождите.'),
    'semantic_chapter_link_label': MessageLookupByLibrary.simpleMessage('Веб ссылка на главу'),
    'semantic_current_chapter_label': MessageLookupByLibrary.simpleMessage('Текущая глава'),
    'semantic_current_value_label': MessageLookupByLibrary.simpleMessage('Текущее значение'),
    'semantic_new_episodes_count': m12,
    'semantic_playing_options_collapse_label': MessageLookupByLibrary.simpleMessage('Закрыть опции проигрывания с прокруткой'),
    'semantic_playing_options_expand_label': MessageLookupByLibrary.simpleMessage('Открыть опции проигрывания с прокруткой'),
    'semantic_podcast_artwork_label': MessageLookupByLibrary.simpleMessage('Изображения подкаста'),
    'semantic_unplayed_episodes_count': m13,
    'semantics_add_to_queue': MessageLookupByLibrary.simpleMessage('Добавить выпуск в очередь'),
    'semantics_collapse_podcast_description': MessageLookupByLibrary.simpleMessage('Свернуть описание подкаста'),
    'semantics_decrease_playback_speed': MessageLookupByLibrary.simpleMessage('Замедлить'),
    'semantics_episode_tile_collapsed': MessageLookupByLibrary.simpleMessage('Пункт списка выпусков. Отображает изображение, сводку и основные элементы управления.'),
    'semantics_episode_tile_collapsed_hint': MessageLookupByLibrary.simpleMessage('развернуть и показать больше подробностей и дополнительных опций'),
    'semantics_episode_tile_expanded': MessageLookupByLibrary.simpleMessage('Пункт списка выпусков. Отображает описание, основные и дополнительные элементы управления.'),
    'semantics_episode_tile_expanded_hint': MessageLookupByLibrary.simpleMessage('свернуть и показать только сводку, скачивание и управление воспроизведением'),
    'semantics_expand_podcast_description': MessageLookupByLibrary.simpleMessage('Раскрыть описание подкаста'),
    'semantics_increase_playback_speed': MessageLookupByLibrary.simpleMessage('Ускорить'),
    'semantics_layout_option_compact_grid': MessageLookupByLibrary.simpleMessage('Компактная сетка'),
    'semantics_layout_option_grid': MessageLookupByLibrary.simpleMessage('Сеткой'),
    'semantics_layout_option_list': MessageLookupByLibrary.simpleMessage('Списком'),
    'semantics_main_player_header': MessageLookupByLibrary.simpleMessage('Главное окно проигрывателя'),
    'semantics_mark_episode_played': MessageLookupByLibrary.simpleMessage('Отметить выпуск как прослушанный'),
    'semantics_mark_episode_unplayed': MessageLookupByLibrary.simpleMessage('Отметить выпуск как ещё непрослушанный'),
    'semantics_mini_player_header': MessageLookupByLibrary.simpleMessage('Мини проигрыватель. Проведите в право чтобы начать или приостановить прослушивание. Активируйте чтобы открыть главное окно проигрывателя'),
    'semantics_play_pause_toggle': MessageLookupByLibrary.simpleMessage('Переключить Слушать/Пауза'),
    'semantics_podcast_details_header': MessageLookupByLibrary.simpleMessage('Подробности подкаста и страница выпусков'),
    'semantics_remove_from_queue': MessageLookupByLibrary.simpleMessage('Удалить выпуск из очереди'),
    'settings_auto_open_now_playing': MessageLookupByLibrary.simpleMessage('Полноэкранный режим проигрывателя при начале выпуска'),
    'settings_auto_update_episodes': MessageLookupByLibrary.simpleMessage('Автообновление выпусков'),
    'settings_auto_update_episodes_10min': MessageLookupByLibrary.simpleMessage('10 минут после последнего обновления'),
    'settings_auto_update_episodes_12hour': MessageLookupByLibrary.simpleMessage('Каждые 12 часов'),
    'settings_auto_update_episodes_1hour': MessageLookupByLibrary.simpleMessage('Каждый час'),
    'settings_auto_update_episodes_24hour': MessageLookupByLibrary.simpleMessage('Каждые 24 часа'),
    'settings_auto_update_episodes_30min': MessageLookupByLibrary.simpleMessage('Каждые 30 минут'),
    'settings_auto_update_episodes_3hour': MessageLookupByLibrary.simpleMessage('Каждые три часа'),
    'settings_auto_update_episodes_48hour': MessageLookupByLibrary.simpleMessage('Каждые 2 дня'),
    'settings_auto_update_episodes_6hour': MessageLookupByLibrary.simpleMessage('Каждые шесть часов'),
    'settings_auto_update_episodes_always': MessageLookupByLibrary.simpleMessage('Всегда'),
    'settings_auto_update_episodes_heading': MessageLookupByLibrary.simpleMessage('Обновление подкастов'),
    'settings_auto_update_episodes_never': MessageLookupByLibrary.simpleMessage('Никогда'),
    'settings_background_refresh_mobile_data_option': MessageLookupByLibrary.simpleMessage('Обновлять когда на мобильной сети'),
    'settings_background_refresh_mobile_data_option_subtitle': MessageLookupByLibrary.simpleMessage('Позволить обновлять библиотеку когда используются мобильные данные'),
    'settings_background_refresh_option': MessageLookupByLibrary.simpleMessage('Фоновое обновление'),
    'settings_background_refresh_option_subtitle': MessageLookupByLibrary.simpleMessage('Обновлять выпуски когда экран отключен. Это подразрядит батарею.'),
    'settings_continuous_play_option': MessageLookupByLibrary.simpleMessage('Непрерывное проигрывание'),
    'settings_continuous_play_subtitle': MessageLookupByLibrary.simpleMessage('Автоматически воспроизводить следующий эпизод в подкасте, если очередь пуста'),
    'settings_data_divider_label': MessageLookupByLibrary.simpleMessage('ДАННЫЕ'),
    'settings_delete_played_label': MessageLookupByLibrary.simpleMessage('Удалять скачанные выпуски после прослушивания'),
    'settings_download_sd_card_label': MessageLookupByLibrary.simpleMessage('Скачивать выпуски на SD карту'),
    'settings_download_switch_card': MessageLookupByLibrary.simpleMessage('Новые скачивания будут сохраняться на SD-карте. Уже существующие так и останутся на внутреннем хранилище.'),
    'settings_download_switch_internal': MessageLookupByLibrary.simpleMessage('Новые скачивания будут сохраняться на внутреннем хранилище. Уже существующие так и останутся на SD-ка��те.'),
    'settings_download_switch_label': MessageLookupByLibrary.simpleMessage('Изменить местоположение хранения'),
    'settings_episodes_divider_label': MessageLookupByLibrary.simpleMessage('ВЫПУСКИ'),
    'settings_export_opml': MessageLookupByLibrary.simpleMessage('Экспорт в файл OPML'),
    'settings_import_opml': MessageLookupByLibrary.simpleMessage('Импортировать из файла OPML'),
    'settings_label': MessageLookupByLibrary.simpleMessage('Настройки'),
    'settings_mark_deleted_played_label': MessageLookupByLibrary.simpleMessage('Отметить удалённые выпуски как прослушанные'),
    'settings_notification_divider_label': MessageLookupByLibrary.simpleMessage('УВЕДОМЛЕНИЯ'),
    'settings_personalisation_divider_label': MessageLookupByLibrary.simpleMessage('ПЕРСОНАЛИЗАЦИЯ'),
    'settings_playback_divider_label': MessageLookupByLibrary.simpleMessage('ВОСПРОИЗВЕДЕНИЕ'),
    'settings_podcast_management_divider_label': MessageLookupByLibrary.simpleMessage('УПРАВЛЕНИЕ ПОДКАСТАМИ'),
    'settings_refresh_notification_option': MessageLookupByLibrary.simpleMessage('Освежить уведомление'),
    'settings_refresh_notification_option_subtitle': MessageLookupByLibrary.simpleMessage('Отображать значок уведомления когда обновляются выпуски'),
    'settings_theme': MessageLookupByLibrary.simpleMessage('Тема оформления'),
    'settings_theme_heading': MessageLookupByLibrary.simpleMessage('Выберите тему'),
    'settings_theme_value_auto': MessageLookupByLibrary.simpleMessage('Как в системе'),
    'settings_theme_value_dark': MessageLookupByLibrary.simpleMessage('Тёмная тема'),
    'settings_theme_value_light': MessageLookupByLibrary.simpleMessage('Светлая тема'),
    'share_episode_option_label': MessageLookupByLibrary.simpleMessage('Поделиться выпуском'),
    'share_podcast_option_label': MessageLookupByLibrary.simpleMessage('Поделиться подкастом'),
    'show_notes_label': MessageLookupByLibrary.simpleMessage('Показать заметки'),
    'sleep_episode_label': MessageLookupByLibrary.simpleMessage('Конец выпуска'),
    'sleep_minute_label': m14,
    'sleep_off_label': MessageLookupByLibrary.simpleMessage('Отключено'),
    'sleep_timer_label': MessageLookupByLibrary.simpleMessage('Таймер сна'),
    'stop_download_button_label': MessageLookupByLibrary.simpleMessage('Остановить'),
    'stop_download_confirmation': MessageLookupByLibrary.simpleMessage('Вы уверены, что хотите остановить скачивание и удалить выпуск?'),
    'stop_download_title': MessageLookupByLibrary.simpleMessage('Остановить скачивание'),
    'subscribe_button_label': MessageLookupByLibrary.simpleMessage('Подписаться'),
    'subscribe_label': MessageLookupByLibrary.simpleMessage('Подписаться'),
    'time_minutes': m15,
    'time_seconds': m16,
    'time_semantic_minutes': m17,
    'time_semantic_seconds': m18,
    'transcript_label': MessageLookupByLibrary.simpleMessage('Субтитры'),
    'transcript_why_not_label': MessageLookupByLibrary.simpleMessage('Почему нет?'),
    'transcript_why_not_url': MessageLookupByLibrary.simpleMessage('https://anytimeplayer.app/docs/anytime_transcript_support_en.html'),
    'unsubscribe_button_label': MessageLookupByLibrary.simpleMessage('Отписаться'),
    'unsubscribe_label': MessageLookupByLibrary.simpleMessage('Отписаться'),
    'unsubscribe_message': MessageLookupByLibrary.simpleMessage('При отмене ��одписки будут удалены все загруженные эпизоды этого подкаста.'),
    'up_next_queue_label': MessageLookupByLibrary.simpleMessage('До следующего'),
    'update_library_option': MessageLookupByLibrary.simpleMessage('Обновить библиотеку')
  };
}
