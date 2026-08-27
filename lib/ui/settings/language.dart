// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

/// Lets the user choose the display language: follow the device, English or
/// Simplified Chinese.
class LanguageWidget extends StatefulWidget {
  final ValueChanged<String?>? onChanged;

  const LanguageWidget({
    super.key,
    this.onChanged,
  });

  @override
  State<LanguageWidget> createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  /// Returns the human-readable label for a stored language value.
  String _labelFor(AppSettings settings) {
    switch (settings.language) {
      case 'en':
        return L.of(context)!.settings_language_english;
      case 'zh':
        return L.of(context)!.settings_language_chinese;
      default:
        return L.of(context)!.settings_language_system;
    }
  }

  @override
  Widget build(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder<AppSettings>(
      stream: settingsBloc.settings,
      initialData: AppSettings.sensibleDefaults(),
      builder: (context, snapshot) {
        return ListTile(
          title: Text(L.of(context)!.settings_language_label),
          subtitle: Text(_labelFor(snapshot.data!)),
          onTap: () {
            showPlatformDialog<void>(
              context: context,
              useRootNavigator: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Semantics(
                    header: true,
                    child: Text(L.of(context)!.settings_language_label,
                        style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                  ),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        RadioListTile<String>(
                          title: Text(L.of(context)!.settings_language_system),
                          value: 'system',
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                          groupValue: snapshot.data!.language,
                          onChanged: (String? value) {
                            setState(() {
                              settingsBloc.setLanguage('system');

                              if (widget.onChanged != null) {
                                widget.onChanged!(value);
                              }

                              Navigator.pop(context);
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: Text(L.of(context)!.settings_language_english),
                          value: 'en',
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                          groupValue: snapshot.data!.language,
                          onChanged: (String? value) {
                            setState(() {
                              settingsBloc.setLanguage('en');

                              if (widget.onChanged != null) {
                                widget.onChanged!(value);
                              }

                              Navigator.pop(context);
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: Text(L.of(context)!.settings_language_chinese),
                          value: 'zh',
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                          groupValue: snapshot.data!.language,
                          onChanged: (String? value) {
                            setState(() {
                              settingsBloc.setLanguage('zh');

                              if (widget.onChanged != null) {
                                widget.onChanged!(value);
                              }

                              Navigator.pop(context);
                            });
                          },
                        ),
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
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
