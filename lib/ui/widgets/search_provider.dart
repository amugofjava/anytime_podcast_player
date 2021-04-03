// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchProviderWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;

  SearchProviderWidget({this.onChanged});

  @override
  _SearchProviderWidgetState createState() => _SearchProviderWidgetState();
}

class _SearchProviderWidgetState extends State<SearchProviderWidget> {
  @override
  Widget build(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder<AppSettings>(
        stream: settingsBloc.settings,
        initialData: AppSettings.sensibleDefaults(),
        builder: (context, snapshot) {
          return snapshot.data.searchProviders.length > 1
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(L.of(context).search_provider_label),
                      subtitle: Text(snapshot.data.searchProvider == 'itunes' ? 'iTunes' : 'PodcastIndex'),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text(L.of(context).search_provider_label),
                                content: StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                      RadioListTile<String>(
                                        title: Text('iTunes'),
                                        value: 'itunes',
                                        groupValue: snapshot.data.searchProvider,
                                        onChanged: (String value) {
                                          setState(() {
                                            settingsBloc.setSearchProvider(value);

                                            if (widget.onChanged != null) {
                                              widget.onChanged(value);
                                            }

                                            Navigator.pop(context);
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text('PodcastIndex'),
                                        value: 'podcastindex',
                                        groupValue: snapshot.data.searchProvider,
                                        onChanged: (String value) {
                                          setState(() {
                                            settingsBloc.setSearchProvider(value);

                                            if (widget.onChanged != null) {
                                              widget.onChanged(value);
                                            }

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
                )
              : Container();
        });
  }
}
