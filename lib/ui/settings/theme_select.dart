import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

import '../widgets/action_text.dart';

class ThemeSelectWidget extends StatefulWidget {
  const ThemeSelectWidget({super.key});

  @override
  State<ThemeSelectWidget> createState() => _ThemeSelectWidgetState();
}

class _ThemeSelectWidgetState extends State<ThemeSelectWidget> {
  @override
  Widget build(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder(
        stream: settingsBloc.settings,
        initialData: AppSettings.sensibleDefaults(),
        builder: (context, snapshot) {
          return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(L.of(context)!.settings_theme),
                  subtitle: updateSubtitle(snapshot.data!),
                  onTap: () {
                    showPlatformDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              L.of(context)!.settings_theme_heading,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            scrollable: true,
                            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                              return Column(children: <Widget>[
                                RadioListTile<String>(
                                    title: Text(L.of(context)!.settings_theme_value_auto),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                    value: 'system',
                                    groupValue: snapshot.data!.theme,
                                    onChanged: (String? value) {
                                      setState(() {
                                        settingsBloc.theme(value ?? 'system');

                                        Navigator.pop(context);
                                      });
                                    }),
                                RadioListTile<String>(
                                    title: Text(L.of(context)!.settings_theme_value_light),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                    value: 'light',
                                    groupValue: snapshot.data!.theme,
                                    onChanged: (String? value) {
                                      setState(() {
                                        settingsBloc.theme(value ?? 'light');

                                        Navigator.pop(context);
                                      });
                                    }),
                                RadioListTile<String>(
                                    title: Text(L.of(context)!.settings_theme_value_dark),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                    value: 'dark',
                                    groupValue: snapshot.data!.theme,
                                    onChanged: (String? value) {
                                      setState(() {
                                        settingsBloc.theme(value ?? 'dark');

                                        Navigator.pop(context);
                                      });
                                    }),
                                SimpleDialogOption(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                                  // child: Text(L.of(context)!.close_button_label),
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
                )
              ]);
        });
  }

  Text updateSubtitle(AppSettings settings) {
    return switch (settings.theme) {
      'system' => Text(L.of(context)!.settings_theme_value_auto),
      'light' => Text(L.of(context)!.settings_theme_value_light),
      _ => Text(L.of(context)!.settings_theme_value_dark)
    };
  }
}
