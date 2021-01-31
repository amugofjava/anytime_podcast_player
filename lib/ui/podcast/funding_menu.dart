// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/funding.dart';
import 'package:anytime/l10n/L.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// This class is responsible for rendering the funding menu on the podcast details
/// page. It returns either a [_MaterialPodcastMenu] or a [_CupertinoContextMenu]
/// instance depending upon which platform we are running on.
///
/// The target platform is based on the current [Theme]: [ThemeData.platform].
class FundingMenu extends StatelessWidget {
  final List<Funding> funding;

  FundingMenu(this.funding);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _MaterialFundingMenu(funding);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _CupertinoFundingMenu(funding);
    }

    // Not needed, but stops the linter complaining.
    return null;
  }
}

/// This is the material design version of the context menu. This will be rendered
/// for all platforms that are not iOS.
class _MaterialFundingMenu extends StatelessWidget {
  final List<Funding> funding;

  _MaterialFundingMenu(this.funding);

  @override
  Widget build(BuildContext context) {
    final settingsBloc = Provider.of<SettingsBloc>(context);

    return funding == null || funding.isEmpty
        ? Container()
        : StreamBuilder<AppSettings>(
            stream: settingsBloc.settings,
            initialData: AppSettings.sensibleDefaults(),
            builder: (context, snapshot) {
              return PopupMenuButton<String>(
                color: Theme.of(context).dialogBackgroundColor,
                onSelected: (url) {
                  FundingLink.fundingLink(
                    url,
                    snapshot.data.externalLinkConsent,
                    context,
                  ).then((value) {
                    settingsBloc.setExternalLinkConsent(value);
                  });
                },
                icon: Icon(
                  Icons.payment,
                  color: Theme.of(context).buttonColor,
                ),
                itemBuilder: (BuildContext context) {
                  return List<PopupMenuEntry<String>>.generate(funding.length, (index) {
                    return PopupMenuItem<String>(
                      value: funding[index].url,
                      enabled: true,
                      child: Text(funding[index].value),
                    );
                  });
                },
              );
            });
  }
}

/// This is the Cupertino context menu and is rendered only when running on
/// an iOS device.
class _CupertinoFundingMenu extends StatelessWidget {
  final List<Funding> funding;

  _CupertinoFundingMenu(this.funding);

  @override
  Widget build(BuildContext context) {
    final settingsBloc = Provider.of<SettingsBloc>(context);

    return funding == null || funding.isEmpty
        ? Container()
        : StreamBuilder<AppSettings>(
            stream: settingsBloc.settings,
            initialData: AppSettings.sensibleDefaults(),
            builder: (context, snapshot) {
              return CupertinoActionSheet(
                actions: <Widget>[
                  ...List<CupertinoActionSheetAction>.generate(funding.length, (index) {
                    return CupertinoActionSheetAction(
                      onPressed: () {
                        FundingLink.fundingLink(
                          funding[index].url,
                          snapshot.data.externalLinkConsent,
                          context,
                        ).then((value) {
                          settingsBloc.setExternalLinkConsent(value);
                        });
                      },
                      child: Text(L.of(context).mark_episodes_played_label),
                    );
                  }),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  child: Text(L.of(context).cancel_option_label),
                  onPressed: () {
                    Navigator.pop(context, 'Cancel');
                  },
                ),
              );
            });
  }
}

class FundingLink {
  /// Check the consent status. If this is the first time we have been
  /// requested to open a funding link, present the user with and
  /// information dialog first to make clear that the link is provided
  /// by the podcast owner and not AnyTime.
  static Future<bool> fundingLink(String url, bool consent, BuildContext context) async {
    var result = false;

    if (consent) {
      result = true;

      unawaited(
        canLaunch(url).then((value) => launch(url)),
      );
    } else {
      result = await showPlatformDialog<bool>(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text(L.of(context).podcast_funding_dialog_header),
          content: Text(L.of(context).consent_message),
          actions: <Widget>[
            BasicDialogAction(
              title: Text(L.of(context).go_back_button_label),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            BasicDialogAction(
              title: Text(L.of(context).continue_button_label),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      );

      if (result) {
        unawaited(
          canLaunch(url).then((value) => launch(url)),
        );
      }
    }

    return Future.value(result);
  }
}
