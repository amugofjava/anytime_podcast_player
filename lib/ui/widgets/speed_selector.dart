// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This widget allows the user to change the playback speed. Selecting the playback
/// speed icon will open a dialog box showing the speed options available.
class SpeedSelectorWidget extends StatefulWidget {
  @override
  _SpeedSelectorWidgetState createState() => _SpeedSelectorWidgetState();
}

class _SpeedSelectorWidgetState extends State<SpeedSelectorWidget> {
  var speed = 1.0;

  @override
  void initState() {
    var settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    speed = settingsBloc.currentSettings.playbackSpeed;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var settingsBloc = Provider.of<SettingsBloc>(context);

    return StreamBuilder<AppSettings>(
        stream: settingsBloc.settings,
        initialData: AppSettings.sensibleDefaults(),
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  showModalBottomSheet<void>(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          topRight: Radius.circular(10.0),
                        ),
                      ),
                      builder: (context) {
                        return SpeedSlider();
                      });
                },
                child: Text(
                  'x${snapshot.data.playbackSpeed}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).buttonColor,
                  ),
                ),
              ),
            ],
          );
        });
  }
}

class SpeedSlider extends StatefulWidget {
  const SpeedSlider({Key key}) : super(key: key);

  @override
  _SpeedSliderState createState() => _SpeedSliderState();
}

class _SpeedSliderState extends State<SpeedSlider> {
  var speed = 1.0;
  var trimSilence = false;

  @override
  void initState() {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    speed = settingsBloc.currentSettings.playbackSpeed;
    trimSilence = settingsBloc.currentSettings.trimSilence;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      height: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'Playback Speed',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Divider(
            color: Colors.blue,
            // color: Theme.of(context).colorScheme.background,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              '${speed.toString()}x',
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Slider(
              value: speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              // label: '${speed.toString()}x',
              onChanged: (value) {
                setState(() {
                  speed = value;
                  audioBloc.playbackSpeed(speed);
                });
              },
              onChangeEnd: (value) {
                settingsBloc.setPlaybackSpeed(value);
              },
            ),
          ),
          Divider(
            color: Colors.blue,
            // color: Theme.of(context).colorScheme.background,
          ),
          theme.platform == TargetPlatform.android
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Trim silence',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                    Switch.adaptive(
                      value: trimSilence,
                      onChanged: (value) {
                        setState(() {
                          trimSilence = value;
                          audioBloc.trimSilence(value);
                          settingsBloc.setTrimSilence(value);
                        });
                      },
                    ),
                  ],
                )
              : SizedBox(
                  width: 0.0,
                  height: 0.0,
                ),
        ],
      ),
    );
  }
}
