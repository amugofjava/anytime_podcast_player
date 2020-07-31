// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/core/utils.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';

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
  final SettingsService settingsService;

  Settings({
    @required this.settingsService,
  });

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool sdcard = false;

  Widget _buildList() {
    return ListView(
        children: ListTile.divideTiles(
      context: context,
      tiles: [
        ListTile(
          title: Text(L.of(context).settings_mark_deleted_played_label),
          trailing: Switch.adaptive(
            activeColor: Colors.orange,
            value: widget.settingsService.markDeletedEpisodesAsPlayed,
            onChanged: (value) => setState(() => widget.settingsService.markDeletedEpisodesAsPlayed = value),
          ),
        ),
        ListTile(
          title: Text(L.of(context).settings_download_sd_card_label),
          enabled: sdcard,
          trailing: Switch.adaptive(
            activeColor: Colors.orange,
            value: widget.settingsService.storeDownloadsSDCard,
            onChanged: (value) => sdcard
                ? setState(() {
                    if (value) {
                      _showStorageDialog(enableExternalStorage: true);
                    } else {
                      _showStorageDialog(enableExternalStorage: false);
                    }

                    widget.settingsService.storeDownloadsSDCard = value;
                  })
                : null,
          ),
        ),
      ],
    ).toList());
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.grey[800],
          ),
        ),
      ),
      body: _buildList(),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: _buildList(),
    );
  }

  void _showStorageDialog({@required bool enableExternalStorage}) {
    showPlatformDialog<void>(
      context: context,
      builder: (_) => BasicDialogAlert(
        title: Text("Change storage location"),
        content: Text(
          enableExternalStorage ? L.of(context).settings_download_switch_card : L.of(context).settings_download_switch_internal,
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
