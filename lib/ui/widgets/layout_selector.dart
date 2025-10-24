// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/slider_handle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

/// Allows the user to select the layout for the library and discovery panes.
/// Can select from a list or different sized grids.
class LayoutSelectorWidget extends StatefulWidget {
  const LayoutSelectorWidget({
    super.key,
  });

  @override
  State<LayoutSelectorWidget> createState() => _LayoutSelectorWidgetState();
}

class _LayoutSelectorWidgetState extends State<LayoutSelectorWidget> {
  var speed = 1.0;

  @override
  void initState() {
    var settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    speed = settingsBloc.currentSettings.playbackSpeed;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    return SafeArea(
      child: StreamBuilder<AppSettings>(
          stream: settingsBloc.settings,
          initialData: AppSettings.sensibleDefaults(),
          builder: (context, snapshot) {
            final mode = snapshot.data!.layoutMode;
            var selectedIndex = <bool>[mode == 0, mode == 1, mode == 2];
            var sortOrder = '';

            switch (settingsBloc.currentSettings.layoutOrder) {
              case 'alphabetical':
                sortOrder = 'Alphabetical';
                break;
              case 'followed':
                sortOrder = 'Date followed';
                break;
              case 'unplayed':
                sortOrder = 'Unplayed episodes';
                break;
              default:
                sortOrder = 'Alphabetical';
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SliderHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 0.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Icon(
                                Icons.grid_view,
                                size: 18,
                              ),
                            ),
                            ExcludeSemantics(
                              child: Text(
                                L.of(context)!.layout_label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        )),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ToggleButtons(
                              onPressed: (int index) {
                                setState(() {
                                  settingsBloc.layoutMode(index);
                                });
                              },
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              isSelected: selectedIndex,
                              children: [
                                Icon(
                                  Icons.list,
                                  semanticLabel: L.of(context)!.layout_selector_list_view,
                                ),
                                Icon(
                                  Icons.grid_on,
                                  semanticLabel: L.of(context)!.layout_selector_compact_grid_view,
                                ),
                                Icon(
                                  Icons.grid_view,
                                  semanticLabel: L.of(context)!.layout_selector_grid_view,
                                )
                              ]),
                        ),
                      ]),
                ),
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Icon(
                                Icons.access_time,
                                size: 18,
                              ),
                            ),
                            Text(
                              L.of(context)!.layout_selector_highlight_new_episodes,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        )),
                        Switch.adaptive(
                          value: settingsBloc.currentSettings.layoutHighlight,
                          onChanged: (highlight) {
                            setState(() {
                              settingsBloc.layoutHighlight(highlight);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Icon(
                                Icons.stars,
                                size: 18,
                              ),
                            ),
                            Text(
                              L.of(context)!.layout_selector_unplayed_episodes,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        )),
                        Switch.adaptive(
                          value: settingsBloc.currentSettings.layoutCount,
                          onChanged: (count) {
                            setState(() {
                              settingsBloc.layoutCount(count);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 16.0, 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Icon(
                                Icons.sort_by_alpha,
                                size: 18,
                              ),
                            ),
                            Text(
                              L.of(context)!.layout_selector_sort_by,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        )),
                        TextButton(
                          onPressed: () {
                            showPlatformDialog(
                                context: context,
                                useRootNavigator: false,
                                builder: (BuildContext context) {
                                  return (defaultTargetPlatform == TargetPlatform.iOS) ?
                                  CupertinoActionSheet(
                                    actions: <Widget>[
                                        CupertinoActionSheetAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            setState(() {
                                              settingsBloc.layoutOrder('alphabetical');
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: Text(L.of(context)!.library_sort_alphabetical_label),
                                        ),
                                        CupertinoActionSheetAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            setState(() {
                                              settingsBloc.layoutOrder('followed');
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: Text(L.of(context)!.library_sort_date_followed_label),
                                        ),
                                        CupertinoActionSheetAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            setState(() {
                                              settingsBloc.layoutOrder('unplayed');
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: Text(L.of(context)!.library_sort_unplayed_count_label),
                                        ),
                                    ],
                                    cancelButton: CupertinoActionSheetAction(
                                      isDefaultAction: false,
                                      onPressed: () {
                                        Navigator.pop(context, 'Close');
                                      },
                                      child: Text(L.of(context)!.close_button_label),
                                    ),
                                  )
                                  : AlertDialog(
                                    title: Text(
                                      L.of(context)!.layout_selector_sort_by,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    scrollable: true,
                                    content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                                      return Column(children: <Widget>[
                                        RadioListTile<String>(
                                            title: Text(L.of(context)!.library_sort_alphabetical_label),
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                            value: 'alphabetical',
                                            groupValue: snapshot.data!.layoutOrder,
                                            onChanged: (String? value) {
                                              setState(() {
                                                settingsBloc.layoutOrder(value ?? '');
                                                Navigator.pop(context);
                                              });
                                            }),
                                        RadioListTile<String>(
                                            title: Text(L.of(context)!.library_sort_date_followed_label),
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                            value: 'followed',
                                            groupValue: snapshot.data!.layoutOrder,
                                            onChanged: (String? value) {
                                              setState(() {
                                                settingsBloc.layoutOrder(value ?? '');
                                                Navigator.pop(context);
                                              });
                                            }),
                                        RadioListTile<String>(
                                            title: Text(L.of(context)!.library_sort_unplayed_count_label),
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                            value: 'unplayed',
                                            groupValue: snapshot.data!.layoutOrder,
                                            onChanged: (String? value) {
                                              setState(() {
                                                settingsBloc.layoutOrder(value ?? '');
                                                Navigator.pop(context);
                                              });
                                            }),
                                        SimpleDialogOption(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              child: ActionText(L.of(context)!.close_button_label),
                                              onPressed: () {
                                                Navigator.pop(context, '');
                                              },
                                            ),
                                          ),
                                        ),
                                      ]);
                                    }),
                                  );
                                });
                          },
                          child: Text(sortOrder),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
              ],
            );
          }),
    );
  }
}
