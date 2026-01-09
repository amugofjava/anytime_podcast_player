// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static m0(days) => "${Intl.plural(days, one: '1 gün önce', other: '${days} gün önce')}";

  static m1(hours) => "${Intl.plural(hours, one: '${hours} saat önce', other: '${hours} saat önce')}";

  static m2(minutes) => "${minutes} dakika kaldı";

  static m3(minutes) => "${Intl.plural(minutes, one: '1 dakika önce', other: '${minutes} dakika önce')}";

  static m4(seconds) => "${seconds} saniye kaldı";

  static m5(weeks) => "${Intl.plural(weeks, one: '1 hafta önce', other: '${weeks} hafta önce')}";

  static m6(days) => "${Intl.plural(days, one: '1g önce', other: '${days}g önce')}";

  static m7(hours) => "${Intl.plural(hours, one: '1s önce', other: '${hours}s önce')}";

  static m8(minutes) => "${minutes} dakika kaldı";

  static m9(minutes) => "${Intl.plural(minutes, one: '1 dk önce', other: '${minutes} dk önce')}";

  static m10(seconds) => "${seconds} saniye kaldı";

  static m11(weeks) => "${Intl.plural(weeks, one: 'h önce', other: '${weeks}h önce')}";

  static m12(episodes) => "${Intl.plural(episodes, one: '1 yeni bölüm', other: '${episodes} yeni bölümler')}";

  static m13(episodes) => "${Intl.plural(episodes, one: '1 oynatılmamış bölüm', other: '${episodes} oynatılmamış bölüm')}";

  static m14(minutes) => "${minutes} dakika";

  static m15(minutes) => "${minutes} dk";

  static m16(seconds) => "${seconds} sn";

  static m17(minutes) => "${minutes} dakika";

  static m18(seconds) => "${seconds} saniye";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(_) => {
      'about_label': MessageLookupByLibrary.simpleMessage('Hakkında'),
    'add_rss_feed_option': MessageLookupByLibrary.simpleMessage('RSS feed ekle'),
    'alert_sync_title_body': MessageLookupByLibrary.simpleMessage('Podcast kitaplığınızı istediğiniz zaman güncelleyebilirsiniz'),
    'alert_sync_title_label': MessageLookupByLibrary.simpleMessage('Kütüphane Güncellemesi'),
    'app_title': MessageLookupByLibrary.simpleMessage('Anytime Podcast Oynatıcı'),
    'app_title_short': MessageLookupByLibrary.simpleMessage('Anytime Player'),
    'audio_effect_trim_silence_label': MessageLookupByLibrary.simpleMessage('Sessiz kısımları kes'),
    'audio_effect_volume_boost_label': MessageLookupByLibrary.simpleMessage('Ses yükseltme'),
    'audio_settings_playback_speed_label': MessageLookupByLibrary.simpleMessage('Oynatım Hızı'),
    'auto_scroll_transcript_label': MessageLookupByLibrary.simpleMessage('Transkripti takip et'),
    'cancel_button_label': MessageLookupByLibrary.simpleMessage('İptal'),
    'cancel_download_button_label': MessageLookupByLibrary.simpleMessage('İndirmeyi iptal et'),
    'cancel_option_label': MessageLookupByLibrary.simpleMessage('İptal'),
    'chapters_label': MessageLookupByLibrary.simpleMessage('Bölümler'),
    'clear_queue_button_label': MessageLookupByLibrary.simpleMessage('Kuyruğu temizle'),
    'clear_search_button_label': MessageLookupByLibrary.simpleMessage('Arama metnini temizle'),
    'close_button_label': MessageLookupByLibrary.simpleMessage('Kapat'),
    'consent_message': MessageLookupByLibrary.simpleMessage('Bu fon bağlantısı sizi, programı doğrudan destekleyebileceğiniz harici bir siteye yönlendirecektir. Bağlantılar podcast yazarları tarafından sağlanmaktadır ve Anytime tarafından kontrol edilmemektedir.'),
    'continue_button_label': MessageLookupByLibrary.simpleMessage('Devam'),
    'delete_button_label': MessageLookupByLibrary.simpleMessage('Sil'),
    'delete_episode_button_label': MessageLookupByLibrary.simpleMessage('İndirilmiş bölümü sil'),
    'delete_episode_confirmation': MessageLookupByLibrary.simpleMessage('Bu bölümü silmek istediğinizden emin misiniz?'),
    'delete_episode_title': MessageLookupByLibrary.simpleMessage('Bölümü sil'),
    'delete_label': MessageLookupByLibrary.simpleMessage('Sil'),
    'discover': MessageLookupByLibrary.simpleMessage('Keşfet'),
    'discovery_categories_itunes': MessageLookupByLibrary.simpleMessage('Hepsi,Sanat,İş,Komedi,Eğitim,Kurgu,Devlet,Sağlık ve Vücut Geliştirme,Tarih,Çocuklar ve Aile,Boş Zaman,Müzik,Haberler,Din ve Maneviyat,Bilim,Toplum ve Kültür,Spor,TV ve Film,Teknoloji,Polisiye'),
    'discovery_categories_pindex': MessageLookupByLibrary.simpleMessage('Hepsi,After-Show,Alternatif,Hayvanlar,Animasyon,Sanat,Astronomi,Otomotiv,Havacılık,Beyzbol,Basketbol,Güzellik,Kitaplar,Budizm,İş,Kariyer,Kimya,Hristiyanlık,İklim,Komedi,Yorum,Kurslar,El Sanatları,Kriket,Kripto Para,Kültür,Günlük,Tasarım,Belgesel,Drama,Dünya,Eğitim,Eğlence,Girişimcilik,Aile,Fantastik,Moda,Kurgu,Film,Vücut Geliştirme,Yemek,Futbol,Oyunlar,Bahçe,Golf,Devlet,Sağlık,Hinduizm,Tarih,Hobiler,Hokey,Ev,Nasıl Yapılır,Doğaçlama,Röportajlar,Yatırım,İslam,Dergiler,Yahudilik,Çocuklar,Dil,Öğrenme,Boş Zaman,Yaşam,Yönetim,Manga,Pazarlama,Matematik,Tıp,Zihinsel,Müzik,Doğal,Doğa,Haberler,Kâr Amacı Gütmeyen,Beslenme,Ebeveynlik,Performans,Kişisel,Evcil Hayvanlar,Felsefe,Fizik,Yerler,Siyaset,İlişkiler,Din,İncelemeler,Rol Yapma,Rugby,Koşu,Bilim,Kişisel Gelişim,Cinsellik,Futbol,Sosyal,Toplum,Maneviyat,Spor,Stand-Up,Hikayeler,Yüzme,TV,Masaüstü,Teknoloji,Tenis,Seyahat,Polisiye,Video Oyunları,Görsel,Voleybol,Hava Durumu,Vahşi Doğa,Güreş'),
    'download_episode_button_label': MessageLookupByLibrary.simpleMessage('Bölümü indir'),
    'downloads': MessageLookupByLibrary.simpleMessage('İndirmeler'),
    'empty_queue_message': MessageLookupByLibrary.simpleMessage('Kuyruk boş'),
    'episode_details_button_label': MessageLookupByLibrary.simpleMessage('Bölüm bilgilerini göster'),
    'episode_filter_clear_filters_button_label': MessageLookupByLibrary.simpleMessage('Filtreyi Temizle'),
    'episode_filter_no_episodes_title_description': MessageLookupByLibrary.simpleMessage('Bu podcastte aradığınız kriter ve filtreye uyan bölüm bulunmuyor'),
    'episode_filter_no_episodes_title_label': MessageLookupByLibrary.simpleMessage('Bölüm bulunamadı'),
    'episode_filter_none_label': MessageLookupByLibrary.simpleMessage('Bölümler filtrelenmedi'),
    'episode_filter_played_label': MessageLookupByLibrary.simpleMessage('Oynatıldı'),
    'episode_filter_semantic_label': MessageLookupByLibrary.simpleMessage('Bölümleri filtrele'),
    'episode_filter_started_label': MessageLookupByLibrary.simpleMessage('Başladı'),
    'episode_filter_unplayed_label': MessageLookupByLibrary.simpleMessage('Oynatılmadı'),
    'episode_label': MessageLookupByLibrary.simpleMessage('Bölüm'),
    'episode_semantic_time_days_ago': m0,
    'episode_semantic_time_hours_ago': m1,
    'episode_semantic_time_minute_remaining': m2,
    'episode_semantic_time_minutes_ago': m3,
    'episode_semantic_time_second_remaining': m4,
    'episode_semantic_time_weeks_ago': m5,
    'episode_sort_alphabetical_ascending_label': MessageLookupByLibrary.simpleMessage('Alfabetik A-Z'),
    'episode_sort_alphabetical_descending_label': MessageLookupByLibrary.simpleMessage('Alfabetik Z-A'),
    'episode_sort_earliest_first_label': MessageLookupByLibrary.simpleMessage('En eski'),
    'episode_sort_latest_first_label': MessageLookupByLibrary.simpleMessage('En yeni'),
    'episode_sort_none_label': MessageLookupByLibrary.simpleMessage('Varsayılan'),
    'episode_sort_semantic_label': MessageLookupByLibrary.simpleMessage('Bölümleri sırala'),
    'episode_time_days_ago': m6,
    'episode_time_hours_ago': m7,
    'episode_time_minute_remaining': m8,
    'episode_time_minutes_ago': m9,
    'episode_time_now': MessageLookupByLibrary.simpleMessage('Şimdi'),
    'episode_time_second_remaining': m10,
    'episode_time_weeks_ago': m11,
    'error_no_connection': MessageLookupByLibrary.simpleMessage('Bölüm oynatılamıyor. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.'),
    'error_playback_fail': MessageLookupByLibrary.simpleMessage('Oynatma sırasında beklenmedik bir hata oluştu. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.'),
    'fast_forward_button_label': MessageLookupByLibrary.simpleMessage('Bölümü 30 saniye ileri sar'),
    'feedback_menu_item_label': MessageLookupByLibrary.simpleMessage('Geribildirim'),
    'go_back_button_label': MessageLookupByLibrary.simpleMessage('Geri Dön'),
    'label_episode_actions': MessageLookupByLibrary.simpleMessage('Bölüm Eylemleri'),
    'label_megabytes': MessageLookupByLibrary.simpleMessage('megabyte'),
    'label_megabytes_abbr': MessageLookupByLibrary.simpleMessage('mb'),
    'label_opml_importing': MessageLookupByLibrary.simpleMessage('İçe aktarılıyor'),
    'label_podcast_actions': MessageLookupByLibrary.simpleMessage('Podcast Eylemleri'),
    'layout_label': MessageLookupByLibrary.simpleMessage('Düzen'),
    'layout_selector_compact_grid_view': MessageLookupByLibrary.simpleMessage('Kompakt ızgara görünümü'),
    'layout_selector_grid_view': MessageLookupByLibrary.simpleMessage('Izgara görünümü'),
    'layout_selector_highlight_new_episodes': MessageLookupByLibrary.simpleMessage('Yeni bölümleri öne çıkar'),
    'layout_selector_list_view': MessageLookupByLibrary.simpleMessage('Liste görünümü'),
    'layout_selector_sort_by': MessageLookupByLibrary.simpleMessage('Sıralama'),
    'layout_selector_sort_by_alphabetical': MessageLookupByLibrary.simpleMessage('Alfabetik'),
    'layout_selector_sort_by_followed': MessageLookupByLibrary.simpleMessage('Takip edilen'),
    'layout_selector_sort_by_unplayed': MessageLookupByLibrary.simpleMessage('Oynatılmamış'),
    'layout_selector_unplayed_episodes': MessageLookupByLibrary.simpleMessage('Oynanmamış sayısını göster'),
    'library': MessageLookupByLibrary.simpleMessage('Kütüphane'),
    'library_sort_alphabetical_label': MessageLookupByLibrary.simpleMessage('Alfabetik'),
    'library_sort_date_followed_label': MessageLookupByLibrary.simpleMessage('Takip edilen tarih'),
    'library_sort_latest_episodes_label': MessageLookupByLibrary.simpleMessage('Son bölümler'),
    'library_sort_unplayed_count_label': MessageLookupByLibrary.simpleMessage('Oynatılmamış bölümler'),
    'mark_episodes_not_played_label': MessageLookupByLibrary.simpleMessage('Tüm bölümleri oynatılmamış olarak işaretle'),
    'mark_episodes_played_label': MessageLookupByLibrary.simpleMessage('Tüm bölümleri oynatılmış olarak işaretle'),
    'mark_played_label': MessageLookupByLibrary.simpleMessage('Oynatıldı olarak işaretle'),
    'mark_unplayed_label': MessageLookupByLibrary.simpleMessage('Oynatılmadı olarak işaretle'),
    'minimise_player_window_button_label': MessageLookupByLibrary.simpleMessage('Oynatıcıyı penceresini küçült'),
    'more_label': MessageLookupByLibrary.simpleMessage('Daha fazla'),
    'new_episodes_label': MessageLookupByLibrary.simpleMessage('Yeni bölümler mevcut'),
    'new_episodes_view_now_label': MessageLookupByLibrary.simpleMessage('ŞİMDİ GÖSTER'),
    'no_downloads_message': MessageLookupByLibrary.simpleMessage('İndirilmiş bölümünüz yok'),
    'no_podcast_details_message': MessageLookupByLibrary.simpleMessage('Podcast bölümleri yüklenemedi. Lütfen bağlantınızı kontrol edin.'),
    'no_search_results_message': MessageLookupByLibrary.simpleMessage('Podcast bulunamadı'),
    'no_subscriptions_message': MessageLookupByLibrary.simpleMessage('Aşağıdaki Keşfet butonunu kullanarak veya yukarıdaki arama çubuğu ile ilk podcastini bulabilirsin'),
    'no_transcript_available_label': MessageLookupByLibrary.simpleMessage('Bu podcast için transkript mevcut değil'),
    'notes_label': MessageLookupByLibrary.simpleMessage('Notlar'),
    'now_playing_episode_position': MessageLookupByLibrary.simpleMessage('Bölüm konumu'),
    'now_playing_episode_time_remaining': MessageLookupByLibrary.simpleMessage('Kalan süre'),
    'now_playing_queue_label': MessageLookupByLibrary.simpleMessage('Şuan oynatılıyor'),
    'ok_button_label': MessageLookupByLibrary.simpleMessage('Tamam'),
    'open_show_website_label': MessageLookupByLibrary.simpleMessage('Gösterinin web sitesini aç'),
    'open_up_next_hint': MessageLookupByLibrary.simpleMessage('Sonrakine geç'),
    'opml_export_button_label': MessageLookupByLibrary.simpleMessage('Dışa Aktar'),
    'opml_import_button_label': MessageLookupByLibrary.simpleMessage('İçe Aktar'),
    'opml_import_export_label': MessageLookupByLibrary.simpleMessage('OPML İçe aktar / Dışa aktar'),
    'pause_button_label': MessageLookupByLibrary.simpleMessage('Bölümü durdur'),
    'play_button_label': MessageLookupByLibrary.simpleMessage('Bölümü oynat'),
    'play_download_button_label': MessageLookupByLibrary.simpleMessage('İndirilen bölümü oynat'),
    'playback_speed_label': MessageLookupByLibrary.simpleMessage('Oynatma Hızı'),
    'playing_next_queue_label': MessageLookupByLibrary.simpleMessage('Sonraki oynatılıyor'),
    'podcast_context_play_latest_episode_label': MessageLookupByLibrary.simpleMessage('Son bölümü oynat'),
    'podcast_context_play_next_episode_label': MessageLookupByLibrary.simpleMessage('Bir sonraki oynatılmamış bölümü oynat'),
    'podcast_context_queue_latest_episode_label': MessageLookupByLibrary.simpleMessage('En son bölümü sıraya ekle'),
    'podcast_context_queue_next_episode_label': MessageLookupByLibrary.simpleMessage('Sıradaki oynatılmamış bölümü sıraya ekle'),
    'podcast_funding_dialog_header': MessageLookupByLibrary.simpleMessage('Podcast fonlama'),
    'podcast_options_overflow_menu_semantic_label': MessageLookupByLibrary.simpleMessage('Ayar menüsü'),
    'queue_add_label': MessageLookupByLibrary.simpleMessage('Ekle'),
    'queue_clear_button_label': MessageLookupByLibrary.simpleMessage('Temizle'),
    'queue_clear_label': MessageLookupByLibrary.simpleMessage('Kuyruğu temizlemek istediğine emin misin?'),
    'queue_clear_label_title': MessageLookupByLibrary.simpleMessage('Kuyruğu Temizle'),
    'queue_remove_label': MessageLookupByLibrary.simpleMessage('Kaldır'),
    'refresh_feed_label': MessageLookupByLibrary.simpleMessage('Bölümleri yenile'),
    'resume_button_label': MessageLookupByLibrary.simpleMessage('Bölümü devam ettir'),
    'rewind_button_label': MessageLookupByLibrary.simpleMessage('Bölümü 10 saniye geri sar'),
    'scrim_episode_details_selector': MessageLookupByLibrary.simpleMessage('Bölüm ayrıntılarını kapat'),
    'scrim_episode_filter_selector': MessageLookupByLibrary.simpleMessage('Bölüm filtresini kapat'),
    'scrim_episode_sort_selector': MessageLookupByLibrary.simpleMessage('Bölüm sıralamasını kapat'),
    'scrim_layout_selector': MessageLookupByLibrary.simpleMessage('Düzen seçiciyi kapat'),
    'scrim_sleep_timer_selector': MessageLookupByLibrary.simpleMessage('Uyku zamanlayıcı seçiciyi kapat'),
    'scrim_speed_selector': MessageLookupByLibrary.simpleMessage('Oynatma hızı seçiciyi kapat'),
    'search_back_button_label': MessageLookupByLibrary.simpleMessage('Geri'),
    'search_button_label': MessageLookupByLibrary.simpleMessage('Ara'),
    'search_episodes_label': MessageLookupByLibrary.simpleMessage('Bölüm ara'),
    'search_for_podcasts_hint': MessageLookupByLibrary.simpleMessage('Podcast ara'),
    'search_provider_label': MessageLookupByLibrary.simpleMessage('Arama Sağlayıcısı'),
    'search_transcript_label': MessageLookupByLibrary.simpleMessage('Transkript ara'),
    'semantic_announce_loading': MessageLookupByLibrary.simpleMessage('Yükleniyor, lütfen bekleyin.'),
    'semantic_announce_searching': MessageLookupByLibrary.simpleMessage('Aranıyor, lütfen bekleyin.'),
    'semantic_chapter_link_label': MessageLookupByLibrary.simpleMessage('Bölüm web bağlantısı'),
    'semantic_current_chapter_label': MessageLookupByLibrary.simpleMessage('Geçerli bölüm'),
    'semantic_current_value_label': MessageLookupByLibrary.simpleMessage('Geçerli değer'),
    'semantic_new_episodes_count': m12,
    'semantic_playing_options_collapse_label': MessageLookupByLibrary.simpleMessage('Oynatma seçenekleri kaydırıcısını kapat'),
    'semantic_playing_options_expand_label': MessageLookupByLibrary.simpleMessage('Oynatma seçenekleri kaydırıcısını aç'),
    'semantic_podcast_artwork_label': MessageLookupByLibrary.simpleMessage('Ana oynatıcıda podcast görüntüsünün etrafına yerleştirildi'),
    'semantic_unplayed_episodes_count': m13,
    'semantics_add_to_queue': MessageLookupByLibrary.simpleMessage('Bölümü kuyruğa ekle'),
    'semantics_collapse_podcast_description': MessageLookupByLibrary.simpleMessage('Podcast açıklamasını daralt'),
    'semantics_decrease_playback_speed': MessageLookupByLibrary.simpleMessage('Oynatma hızını azalt'),
    'semantics_episode_tile_collapsed': MessageLookupByLibrary.simpleMessage('Bölüm listesi öğesi. Resim, özet ve ana kontroller gösteriliyor.'),
    'semantics_episode_tile_collapsed_hint': MessageLookupByLibrary.simpleMessage('genişlet ve daha fazla ayrıntı ve ek seçenekleri göster'),
    'semantics_episode_tile_expanded': MessageLookupByLibrary.simpleMessage('Bölüm listesi öğesi. Açıklama, ana kontroller ve ek kontroller gösteriliyor.'),
    'semantics_episode_tile_expanded_hint': MessageLookupByLibrary.simpleMessage('özeti göster ve daralt, indir ve oynat kontrolü'),
    'semantics_expand_podcast_description': MessageLookupByLibrary.simpleMessage('Podcast açıklamasını genişlet'),
    'semantics_increase_playback_speed': MessageLookupByLibrary.simpleMessage('Oynatma hızını arttır'),
    'semantics_layout_option_compact_grid': MessageLookupByLibrary.simpleMessage('Kompakt ızgara düzeni'),
    'semantics_layout_option_grid': MessageLookupByLibrary.simpleMessage('Izgara düzeni'),
    'semantics_layout_option_list': MessageLookupByLibrary.simpleMessage('Liste düzeni'),
    'semantics_main_player_header': MessageLookupByLibrary.simpleMessage('Ana oynatıcı penceresi'),
    'semantics_mark_episode_played': MessageLookupByLibrary.simpleMessage('Bölümü oynatılmış olarak işaretle'),
    'semantics_mark_episode_unplayed': MessageLookupByLibrary.simpleMessage('Bölümü oynatılmamış olarak işaretle'),
    'semantics_mini_player_header': MessageLookupByLibrary.simpleMessage('Mini oynatıcı. Oynat/duraklat düğmesine sağa kaydırın. Ana oynatıcı penceresini açmak için etkinleştirin'),
    'semantics_play_pause_toggle': MessageLookupByLibrary.simpleMessage('Oynat/duraklat düğmesi'),
    'semantics_podcast_details_header': MessageLookupByLibrary.simpleMessage('Podcast ayrıntıları ve bölüm sayfası'),
    'semantics_remove_from_queue': MessageLookupByLibrary.simpleMessage('Bölümü kuyruktan kaldır'),
    'settings_auto_open_now_playing': MessageLookupByLibrary.simpleMessage('Bölüm başladığında tam ekran yap'),
    'settings_auto_update_episodes': MessageLookupByLibrary.simpleMessage('Podcastları Yenile'),
    'settings_auto_update_episodes_10min': MessageLookupByLibrary.simpleMessage('son güncelleme 10 dakika önce'),
    'settings_auto_update_episodes_12hour': MessageLookupByLibrary.simpleMessage('Her 12 saat'),
    'settings_auto_update_episodes_1hour': MessageLookupByLibrary.simpleMessage('Her saat'),
    'settings_auto_update_episodes_24hour': MessageLookupByLibrary.simpleMessage('Her 24 saatte'),
    'settings_auto_update_episodes_30min': MessageLookupByLibrary.simpleMessage('Her 30 dakikada bir'),
    'settings_auto_update_episodes_3hour': MessageLookupByLibrary.simpleMessage('3 saatte bir'),
    'settings_auto_update_episodes_48hour': MessageLookupByLibrary.simpleMessage('Her 2 günde bir'),
    'settings_auto_update_episodes_6hour': MessageLookupByLibrary.simpleMessage('6 saatte bir'),
    'settings_auto_update_episodes_always': MessageLookupByLibrary.simpleMessage('Her zaman'),
    'settings_auto_update_episodes_heading': MessageLookupByLibrary.simpleMessage('Podcastları Yenile'),
    'settings_auto_update_episodes_never': MessageLookupByLibrary.simpleMessage('Hiçbir Zaman'),
    'settings_background_refresh_mobile_data_option': MessageLookupByLibrary.simpleMessage('Mobil veri kullanırken yenile'),
    'settings_background_refresh_mobile_data_option_subtitle': MessageLookupByLibrary.simpleMessage('Mobil veri kullanırken kütüphanenin yenilenmesine izin ver'),
    'settings_background_refresh_option': MessageLookupByLibrary.simpleMessage('Arka planda yenileme'),
    'settings_background_refresh_option_subtitle': MessageLookupByLibrary.simpleMessage('Ekran kapalıyken bölümleri yenile. Bu pil kullanımını artıracaktır.'),
    'settings_continuous_play_option': MessageLookupByLibrary.simpleMessage('Sürekli oynatma'),
    'settings_continuous_play_subtitle': MessageLookupByLibrary.simpleMessage('Kuyruk boşsa podcastteki bir sonraki bölümü otomatik olarak oynat'),
    'settings_data_divider_label': MessageLookupByLibrary.simpleMessage('VERİ'),
    'settings_delete_played_label': MessageLookupByLibrary.simpleMessage('İzlendikten sonra indirilen bölümleri sil'),
    'settings_download_sd_card_label': MessageLookupByLibrary.simpleMessage('Bölümleri SD karta indir'),
    'settings_download_switch_card': MessageLookupByLibrary.simpleMessage('Yeni indirmeler SD karta kaydedilecektir. Mevcut indirmeler dahili depolama alanında kalacaktır.'),
    'settings_download_switch_internal': MessageLookupByLibrary.simpleMessage('Yeni indirmeler dahili depolama alanına kaydedilecektir. Mevcut indirmeler SD kartta kalacaktır.'),
    'settings_download_switch_label': MessageLookupByLibrary.simpleMessage('Depolama konumunu değiştir'),
    'settings_episodes_divider_label': MessageLookupByLibrary.simpleMessage('BÖLÜMLER'),
    'settings_export_opml': MessageLookupByLibrary.simpleMessage('OPML olarak dışa aktar'),
    'settings_import_opml': MessageLookupByLibrary.simpleMessage('OPML İçe Aktar'),
    'settings_label': MessageLookupByLibrary.simpleMessage('Ayarlar'),
    'settings_mark_deleted_played_label': MessageLookupByLibrary.simpleMessage('Silinen bölümleri izlendi olarak işaretle'),
    'settings_notification_divider_label': MessageLookupByLibrary.simpleMessage('BİLDİRİMLER'),
    'settings_personalisation_divider_label': MessageLookupByLibrary.simpleMessage('KİŞİSELLEŞTİRME'),
    'settings_playback_divider_label': MessageLookupByLibrary.simpleMessage('TEKRAR OYNAT'),
    'settings_podcast_management_divider_label': MessageLookupByLibrary.simpleMessage('PODCAST YÖNETİMİ'),
    'settings_refresh_notification_option': MessageLookupByLibrary.simpleMessage('Bildirimi yenile'),
    'settings_refresh_notification_option_subtitle': MessageLookupByLibrary.simpleMessage('Bölümler yenilenirken bildirim simgesi göster'),
    'settings_theme': MessageLookupByLibrary.simpleMessage('Tema'),
    'settings_theme_heading': MessageLookupByLibrary.simpleMessage('Tema seç'),
    'settings_theme_value_auto': MessageLookupByLibrary.simpleMessage('Sistem Teması'),
    'settings_theme_value_dark': MessageLookupByLibrary.simpleMessage('Koyu tema'),
    'settings_theme_value_light': MessageLookupByLibrary.simpleMessage('Açık tema'),
    'share_episode_option_label': MessageLookupByLibrary.simpleMessage('Bölümü paylaş'),
    'share_podcast_option_label': MessageLookupByLibrary.simpleMessage('Podcasti paylaş'),
    'show_notes_label': MessageLookupByLibrary.simpleMessage('Notları göster'),
    'sleep_episode_label': MessageLookupByLibrary.simpleMessage('Bölüm sonu'),
    'sleep_minute_label': m14,
    'sleep_off_label': MessageLookupByLibrary.simpleMessage('Kapalı'),
    'sleep_timer_label': MessageLookupByLibrary.simpleMessage('Uyku Zamanlayıcı'),
    'stop_download_button_label': MessageLookupByLibrary.simpleMessage('Durdur'),
    'stop_download_confirmation': MessageLookupByLibrary.simpleMessage('Bu indirmeyi durdurup bölümü silmek istediğinizden emin misiniz?'),
    'stop_download_title': MessageLookupByLibrary.simpleMessage('İndirmeyi durdur'),
    'subscribe_button_label': MessageLookupByLibrary.simpleMessage('Takip et'),
    'subscribe_label': MessageLookupByLibrary.simpleMessage('Takip et'),
    'time_minutes': m15,
    'time_seconds': m16,
    'time_semantic_minutes': m17,
    'time_semantic_seconds': m18,
    'transcript_label': MessageLookupByLibrary.simpleMessage('Transkript'),
    'transcript_why_not_label': MessageLookupByLibrary.simpleMessage('Neden olmasın?'),
    'transcript_why_not_url': MessageLookupByLibrary.simpleMessage('https://anytimeplayer.app/docs/anytime_transcript_support_en.html'),
    'unsubscribe_button_label': MessageLookupByLibrary.simpleMessage('Takibi bırak'),
    'unsubscribe_label': MessageLookupByLibrary.simpleMessage('Takibi bırak'),
    'unsubscribe_message': MessageLookupByLibrary.simpleMessage('Takibi bırakmak, bu podcastin indirilen tüm bölümlerini siler.'),
    'up_next_queue_label': MessageLookupByLibrary.simpleMessage('Sonraki'),
    'update_library_option': MessageLookupByLibrary.simpleMessage('Kütüphaneyi Yenile')
  };
}
