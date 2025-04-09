import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

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
                            content: StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                return Column(
                                  children: <Widget>[
                                    RadioListTile<String>(
                                      title: Text(L.of(context)!.settings_theme_value_auto),
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                      value: ThemeMode.system.name,
                                      groupValue: snapshot.data!.selectedTheme,
                                      onChanged: (String? value) {
                                        setState(() {
                                          settingsBloc.selectedTheme(value ?? ThemeMode.system.name);
                                          settingsBloc.themeMode(value ?? ThemeMode.light.name);

                                          Navigator.pop(context);
                                        });
                                      }
                                    ),
                                    RadioListTile<String>(
                                        title: Text(L.of(context)!.settings_theme_value_light),
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                        value: ThemeMode.light.name,
                                        groupValue: snapshot.data!.selectedTheme,
                                        onChanged: (String? value) {
                                          setState(() {
                                            settingsBloc.selectedTheme(value ?? ThemeMode.light.name);
                                            settingsBloc.themeMode(value ?? ThemeMode.light.name);

                                            Navigator.pop(context);
                                          });
                                        }
                                    ),
                                    RadioListTile<String>(
                                        title: Text(L.of(context)!.settings_theme_value_dark),
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                        value: ThemeMode.dark.name,
                                        groupValue: snapshot.data!.selectedTheme,
                                        onChanged: (String? value) {
                                          setState(() {
                                            settingsBloc.selectedTheme(value ?? ThemeMode.dark.name);
                                            settingsBloc.themeMode(value ?? ThemeMode.dark.name);

                                            Navigator.pop(context);
                                          });
                                        }
                                    ),
                                  ]
                                );
                              }
                            ),
                          );
                        }
                    );
                  },
                )
              ]
          );
        }
    );
  }

  Text updateSubtitle(AppSettings settings) {
    if (settings.selectedTheme == ThemeMode.light.name) {
      return Text(L.of(context)!.settings_theme_value_light);
    } else if (settings.selectedTheme == ThemeMode.dark.name) {
      return Text(L.of(context)!.settings_theme_value_dark);
    }

    return Text(L.of(context)!.settings_theme_value_auto);
  }
}
