// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/bloc/podcast/opml_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:anytime/ui/library/opml_export.dart';
import 'package:anytime/ui/library/opml_import.dart';
import 'package:anytime/ui/settings/episode_refresh.dart';
import 'package:anytime/ui/settings/language.dart';
import 'package:anytime/ui/settings/search_provider.dart';
import 'package:anytime/ui/settings/settings_section_label.dart';
import 'package:anytime/ui/settings/theme_select.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// This is the settings page and allows the user to select various
/// options for the app.
///
/// This is a self contained page and so, unlike the other forms, talks directly
/// to a settings service rather than a BLoC. Whilst this deviates slightly from
/// the overall architecture, adding a BLoC to simply be consistent with the rest
/// of the application would add unnecessary complexity.
///
/// This page is built with both Android & iOS in mind. However, the
/// rest of the application is not prepared for iOS design; this
/// is in preparation for the iOS version.
class Settings extends StatefulWidget {
  const Settings({
    super.key,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool sdcard = false;

  Widget _buildList(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);
    var podcastBloc = Provider.of<PodcastBloc>(context);
    var opmlBloc = Provider.of<OPMLBloc>(context);

    return StreamBuilder<AppSettings>(
        stream: settingsBloc.settings,
        initialData: settingsBloc.currentSettings,
        builder: (context, snapshot) {
          return ListView(
            children: [
              SettingsDividerLabel(label: L.of(context)!.settings_personalisation_divider_label),
              const ThemeSelectWidget(),
              SettingsDividerLabel(label: L.of(context)!.settings_episodes_divider_label),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_mark_deleted_played_label),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.markDeletedEpisodesAsPlayed,
                    onChanged: (value) => setState(() => settingsBloc.markDeletedAsPlayed(value)),
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    title: Text(L.of(context)!.settings_delete_played_label),
                    trailing: Switch.adaptive(
                      value: snapshot.data!.deleteDownloadedPlayedEpisodes,
                      onChanged: (value) => setState(() => settingsBloc.deleteDownloadedPlayedEpisodes(value)),
                    )),
              ),
              MergeSemantics(
                child: ListTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  title: Text(L.of(context)!.settings_download_sd_card_label),
                  // The switch is only enabled when a removable SD card is
                  // present; otherwise downloads stay on internal storage.
                  onTap: sdcard
                      ? () {
                          setState(() {
                            final value = !snapshot.data!.storeDownloadsSDCard;
                            if (value) {
                              _showStorageDialog(enableExternalStorage: true);
                            } else {
                              _showStorageDialog(enableExternalStorage: false);
                            }
                            settingsBloc.storeDownloadonSDCard(value);
                          });
                        }
                      : null,
                  trailing: Switch.adaptive(
                    value: snapshot.data!.storeDownloadsSDCard,
                    onChanged: sdcard
                        ? (value) {
                            setState(() {
                              if (value) {
                                _showStorageDialog(enableExternalStorage: true);
                              } else {
                                _showStorageDialog(enableExternalStorage: false);
                              }
                              settingsBloc.storeDownloadonSDCard(value);
                            });
                          }
                        : null,
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  title: Text(L.of(context)!.settings_custom_download_path_label),
                  subtitle: Text(
                    snapshot.data!.customDownloadPath.isNotEmpty
                        ? snapshot.data!.customDownloadPath
                        : L.of(context)!.settings_custom_download_path_default,
                  ),
                  trailing: snapshot.data!.customDownloadPath.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: L.of(context)!.settings_custom_download_path_reset,
                          onPressed: () {
                            setState(() {
                              settingsBloc.setCustomDownloadPath('');
                            });
                          },
                        )
                      : const Icon(Icons.folder_open),
                  onTap: () async {
                    await _pickCustomDownloadPath(settingsBloc);
                  },
                ),
              ),
              SettingsDividerLabel(label: L.of(context)!.settings_playback_divider_label),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_auto_open_now_playing),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.autoOpenNowPlaying,
                    onChanged: (value) => setState(() => settingsBloc.setAutoOpenNowPlaying(value)),
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_continuous_play_option),
                  subtitle: Text(L.of(context)!.settings_continuous_play_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.autoPlay,
                    onChanged: (value) => setState(() => settingsBloc.autoPlay(value)),
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_convert_to_mp3_label),
                  subtitle: Text(L.of(context)!.settings_convert_to_mp3_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.convertToMp3,
                    onChanged: (value) => setState(() => settingsBloc.convertToMp3(value)),
                  ),
                ),
              ),
              SettingsDividerLabel(label: L.of(context)!.settings_podcast_management_divider_label),
              const EpisodeRefreshWidget(),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_background_refresh_option),
                  subtitle: Text(L.of(context)!.settings_background_refresh_option_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.backgroundUpdate,
                    onChanged: (value) => setState(() => settingsBloc.backgroundUpdates(value)),
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_background_refresh_mobile_data_option),
                  subtitle: Text(L.of(context)!.settings_background_refresh_mobile_data_option_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.backgroundUpdateMobileData,
                    onChanged: (value) => setState(() => settingsBloc.backgroundUpdatesMobileData(value)),
                  ),
                ),
              ),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_auto_download_episodes_label),
                  subtitle: Text(L.of(context)!.settings_auto_download_episodes_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.autoDownloadEpisodes,
                    onChanged: (value) => setState(() => settingsBloc.setAutoDownloadEpisodes(value)),
                  ),
                ),
              ),
              if (snapshot.data!.autoDownloadEpisodes)
                MergeSemantics(
                  child: ListTile(
                    title: Text(L.of(context)!.settings_auto_download_podcasts_label),
                    subtitle: Text(
                      snapshot.data!.autoDownloadPodcastGuids.isEmpty
                          ? L.of(context)!.settings_auto_download_all_podcasts
                          : L.of(context)!.settings_auto_download_selected_podcasts(
                                snapshot.data!.autoDownloadPodcastGuids.length,
                              ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPodcastSelectionDialog(context, settingsBloc, snapshot.data!),
                  ),
                ),
              SettingsDividerLabel(label: L.of(context)!.settings_notification_divider_label),
              MergeSemantics(
                child: ListTile(
                  title: Text(L.of(context)!.settings_refresh_notification_option),
                  subtitle: Text(L.of(context)!.settings_refresh_notification_option_subtitle),
                  trailing: Switch.adaptive(
                    value: snapshot.data!.updatesNotification,
                    onChanged: (value) => setState(() => settingsBloc.updateNotification(value)),
                  ),
                ),
              ),
              SettingsDividerLabel(label: L.of(context)!.settings_data_divider_label),
              ListTile(
                title: Text(L.of(context)!.settings_import_opml),
                onTap: () async {
                  var result = (await FilePicker.platform.pickFiles(
                    type: FileType.any,
                  ));

                  if (result != null && result.count > 0) {
                    var file = result.files.first;

                    if (context.mounted) {
                      var e = await showPlatformDialog<bool>(
                        androidBarrierDismissible: false,
                        useRootNavigator: false,
                        context: context,
                        builder: (_) => PopScope(
                          canPop: true,
                          onPopInvokedWithResult: (didPop, result) async => false,
                          child: BasicDialogAlert(
                            title: Text(L.of(context)!.settings_import_opml),
                            content: OPMLImport(file: file.path!),
                            actions: <Widget>[
                              BasicDialogAction(
                                title: ActionText(L.of(context)!.cancel_button_label),
                                onPressed: () {
                                  return Navigator.pop(context, true);
                                },
                              ),
                            ],
                          ),
                        ),
                      );

                      if (e != null && e) {
                        opmlBloc.opmlEvent(OPMLCancelEvent());
                      }
                    }
                    podcastBloc.podcastEvent(PodcastEvent.reloadSubscriptions);
                  }
                },
              ),
              ListTile(
                title: Text(L.of(context)!.settings_export_opml),
                onTap: () async {
                  await showPlatformDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => BasicDialogAlert(
                      content: const OPMLExport(),
                    ),
                  );
                },
              ),
              const SearchProviderWidget(),
              const LanguageWidget(),
            ],
          );
        });
  }

  Widget _buildAndroid(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: Text(
            L.of(context)!.settings_label,
          ),
        ),
        body: _buildList(context),
      ),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.all(0.0),
        leading: CupertinoButton(
            child: Icon(
              Icons.arrow_back_ios,
              semanticLabel: L.of(context)?.go_back_button_label,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        middle: Text(
          L.of(context)!.settings_label,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      child: Material(child: _buildList(context)),
    );
  }

  Future<void> _pickCustomDownloadPath(SettingsBloc settingsBloc) async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final proceed = await showPlatformDialog<bool>(
          context: context,
          useRootNavigator: false,
          builder: (_) => BasicDialogAlert(
            title: Text(L.of(context)!.settings_custom_download_path_permission_title),
            content: Text(L.of(context)!.settings_custom_download_path_permission_message),
            actions: <Widget>[
              BasicDialogAction(
                title: Text(L.of(context)!.cancel_button_label),
                onPressed: () => Navigator.pop(context, false),
              ),
              BasicDialogAction(
                title: Text(L.of(context)!.ok_button_label),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (proceed != true) return;

        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          return;
        }
      }
    }

    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      setState(() {
        settingsBloc.setCustomDownloadPath(selectedDirectory);
      });
    }
  }

  void _showStorageDialog({required bool enableExternalStorage}) {
    showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => BasicDialogAlert(
        title: Text(L.of(context)!.settings_download_switch_label),
        content: Text(
          enableExternalStorage
              ? L.of(context)!.settings_download_switch_card
              : L.of(context)!.settings_download_switch_internal,
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text(
              L.of(context)!.ok_button_label,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showPodcastSelectionDialog(
    BuildContext context,
    SettingsBloc settingsBloc,
    AppSettings settings,
  ) async {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final subscriptions = await podcastBloc.podcastService.subscriptions();

    if (!context.mounted) return;

    if (subscriptions.isEmpty) {
      await showPlatformDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (_) => BasicDialogAlert(
          title: Text(L.of(context)!.settings_auto_download_podcasts_label),
          content: Text(L.of(context)!.settings_auto_download_no_subscriptions),
          actions: <Widget>[
            BasicDialogAction(
              title: Text(L.of(context)!.ok_button_label),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final currentGuids = Set<String>.from(settings.autoDownloadPodcastGuids);
    final Set<String> selectedGuids = currentGuids.isEmpty
        ? subscriptions.map((p) => p.guid).whereType<String>().toSet()
        : Set<String>.from(currentGuids);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(L.of(context)!.settings_auto_download_podcasts_label),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final podcast = subscriptions[index];
                    final isChecked = podcast.guid != null && selectedGuids.contains(podcast.guid);
                    return CheckboxListTile(
                      title: Text(
                        podcast.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setDialogState(() {
                          if (podcast.guid != null) {
                            if (val == true) {
                              selectedGuids.add(podcast.guid!);
                            } else {
                              selectedGuids.remove(podcast.guid!);
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: Text(L.of(context)!.settings_auto_download_select_all),
                  onPressed: () {
                    setDialogState(() {
                      selectedGuids.addAll(subscriptions.map((p) => p.guid).whereType<String>());
                    });
                  },
                ),
                TextButton(
                  child: Text(L.of(context)!.cancel_button_label),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                TextButton(
                  child: Text(L.of(context)!.ok_button_label),
                  onPressed: () {
                    setState(() {
                      settingsBloc.setAutoDownloadPodcastGuids(selectedGuids.toList());
                    });
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAndroid(context);
      case TargetPlatform.iOS:
        return _buildIos(context);
      default:
        assert(false, 'Unexpected platform $defaultTargetPlatform');
        return _buildAndroid(context);
    }
  }

  @override
  void initState() {
    super.initState();

    hasExternalStorage().then((value) {
      setState(() {
        sdcard = value;
      });
    });
  }
}
