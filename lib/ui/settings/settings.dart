// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/search_provider_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

/// This is the settings page and allows the user to select various
/// options for the app. This is a self contained page and so, unlike
/// the other forms, talks directly to a settings service rather than
/// a BLoC. Whilst this deviates slightly from the overall architecture,
/// adding a BLoC to simply be consistent with the rest of the
/// application would add unnecessary complexity.
///
/// This page is built with both Android & iOS in mind. However, the
/// rest of the application is not prepared for iOS design; this
/// is in preparation for the iOS version.
class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool sdcard = false;

  Widget _buildList(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder<AppSettings>(
        stream: settingsBloc.settings,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: ListTile.divideTiles(
              context: context,
              tiles: [
                ListTile(
                  title: Text(L.of(context).settings_theme_switch_label),
                  trailing: Switch.adaptive(
                      value: snapshot.data.theme == 'dark',
                      onChanged: (value) {
                        settingsBloc.darkMode(value);
                      }),
                ),
                ListTile(
                  title: Text(L.of(context).settings_mark_deleted_played_label),
                  trailing: Switch.adaptive(
                    value: snapshot.data.markDeletedEpisodesAsPlayed,
                    onChanged: (value) => setState(() => settingsBloc.markDeletedAsPlayed(value)),
                  ),
                ),
                ListTile(
                  title: Text(L.of(context).settings_download_sd_card_label),
                  enabled: sdcard,
                  trailing: Switch.adaptive(
                    value: snapshot.data.storeDownloadsSDCard,
                    onChanged: (value) => sdcard
                        ? setState(() {
                            if (value) {
                              _showStorageDialog(enableExternalStorage: true);
                            } else {
                              _showStorageDialog(enableExternalStorage: false);
                            }

                            settingsBloc.storeDownloadonSDCard(value);
                          })
                        : null,
                  ),
                ),
                ListTile(
                  title: Text(L.of(context).settings_auto_open_now_playing),
                  trailing: Switch.adaptive(
                    value: snapshot.data.autoOpenNowPlaying,
                    onChanged: (value) => setState(() => settingsBloc.setAutoOpenNowPlaying(value)),
                  ),
                ),
                SearchProviderWidget(),
              ],
            ).toList());
          } else {
            return Container();
          }
        });
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Theme.of(context).brightness,
        elevation: 0.0,
        title: Text(
          'Settings',
        ),
      ),
      body: _buildList(context),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: _buildList(context),
    );
  }

  void _showStorageDialog({@required bool enableExternalStorage}) {
    showPlatformDialog<void>(
      context: context,
      builder: (_) => BasicDialogAlert(
        title: Text(L.of(context).settings_download_switch_label),
        content: Text(
          enableExternalStorage
              ? L.of(context).settings_download_switch_card
              : L.of(context).settings_download_switch_internal,
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text(L.of(context).ok_button_label),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
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
        return null;
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
