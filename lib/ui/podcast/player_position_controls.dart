// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerPositionControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return StreamBuilder<PositionState>(
        stream: audioBloc.playPosition,
        builder: (context, snapshot) {
          var position = snapshot.hasData ? snapshot.data.position : Duration(seconds: 1);
          var length = snapshot.hasData ? snapshot.data.length : Duration(seconds: 1);
          var p = position.inSeconds;

          if (p < 0) {
            p = 0;
          }

          if (p > length.inSeconds) {
            p = length.inSeconds;
          }

          var timeRemaining = length.inSeconds - position.inSeconds;

          if (timeRemaining < 0) {
            timeRemaining = 0;
          }

          return Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 4.0,
            ),
            child: Row(
              children: <Widget>[
                Text(_formatDuration(position)),
                Expanded(
                  child: snapshot.hasData
                      ? Slider(
                          onChanged: (value) {
                            audioBloc.transitionPosition(value);
                          },
                          value: p.toDouble(),
                          min: 0.0,
                          max: length.inSeconds.toDouble(),
                          activeColor: Theme.of(context).buttonColor,
                        )
                      : Slider(
                          onChanged: null,
                          value: 0,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Theme.of(context).buttonColor,
                        ),
                ),
                Text(_formatDuration(Duration(seconds: timeRemaining))),
              ],
            ),
          );
        });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    var twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).toInt());
    var twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).toInt());

    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
