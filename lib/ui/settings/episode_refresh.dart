// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

class EpisodeRefreshWidget extends StatefulWidget {
  const EpisodeRefreshWidget({Key key}) : super(key: key);

  @override
  State<EpisodeRefreshWidget> createState() => _EpisodeRefreshWidgetState();
}

class _EpisodeRefreshWidgetState extends State<EpisodeRefreshWidget> {
  @override
  Widget build(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder<AppSettings>(
        stream: settingsBloc.settings,
        initialData: AppSettings.sensibleDefaults(),
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(L.of(context).settings_auto_update_episodes),
                subtitle: updateSubtitle(snapshot.data),
                onTap: () {
                  showPlatformDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: Text(
                            L.of(context).settings_auto_update_episodes_heading,
                            style: Theme.of(context).textTheme.subtitle1,
                            textAlign: TextAlign.center,
                          ),
                          scrollable: true,
                          content: StatefulBuilder(
                            builder: (BuildContext context, StateSetter setState) {
                              return Column(children: <Widget>[
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_never),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: -1,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_always),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 0,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_30min),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 30,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_1hour),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 60,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_3hour),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 180,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_6hour),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 360,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text(L.of(context).settings_auto_update_episodes_12hour),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                                  value: 720,
                                  groupValue: snapshot.data.autoUpdateEpisodePeriod,
                                  onChanged: (int value) {
                                    setState(() {
                                      settingsBloc.autoUpdatePeriod(value);

                                      Navigator.pop(context);
                                    });
                                  },
                                ),
                              ]);
                            },
                          ));
                    },
                  );
                },
              ),
            ],
          );
        });
  }

  Text updateSubtitle(AppSettings settings) {
    switch (settings.autoUpdateEpisodePeriod) {
      case -1:
        return Text(L.of(context).settings_auto_update_episodes_never);
        break;
      case 0:
        return Text(L.of(context).settings_auto_update_episodes_always);
        break;
      case 10:
        return Text(L.of(context).settings_auto_update_episodes_10min);
        break;
      case 30:
        return Text(L.of(context).settings_auto_update_episodes_30min);
        break;
      case 60:
        return Text(L.of(context).settings_auto_update_episodes_1hour);
        break;
      case 180:
        return Text(L.of(context).settings_auto_update_episodes_3hour);
        break;
      case 360:
        return Text(L.of(context).settings_auto_update_episodes_6hour);
        break;
      case 720:
        return Text(L.of(context).settings_auto_update_episodes_12hour);
        break;
    }

    return Text('Never');
  }
}
