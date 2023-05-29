// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.



import 'dart:ui';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This class handles the rendering of the positional controls: the current playback
/// time, time remaining and the time [Slider].
class PlayerPositionControls extends StatefulWidget {
  @override
  State<PlayerPositionControls> createState() => _PlayerPositionControlsState();
}

class _PlayerPositionControlsState extends State<PlayerPositionControls> {
  /// Current playback position
  var currentPosition = 0;

  /// Indicates the user is moving the position slide. We should ignore
  /// position updates until the user releases the slide.
  var dragging = false;

  /// Seconds left of this episode.
  var timeRemaining = 0;

  /// The length of the episode in seconds.
  var episodeLength = 0;

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return StreamBuilder<PositionState>(
        stream: audioBloc.playPosition,
        builder: (context, snapshot) {
          var position = snapshot.hasData ? snapshot.data!.position.inSeconds : 0;
          episodeLength = snapshot.hasData ? snapshot.data!.length.inSeconds : 0;
          var divisions = episodeLength == 0 ? 1 : episodeLength;

          if (!dragging) {
            currentPosition = position;

            if (currentPosition < 0) {
              currentPosition = 0;
            }

            if (currentPosition > episodeLength) {
              currentPosition = episodeLength;
            }

            timeRemaining = episodeLength - position;

            if (timeRemaining < 0) {
              timeRemaining = 0;
            }
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
                FittedBox(
                  child: Text(
                    _formatDuration(Duration(seconds: currentPosition)),
                    style: TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: snapshot.hasData
                      ? Slider(
                          label: _formatDuration(Duration(seconds: currentPosition)),
                          onChanged: (value) {
                            setState(() {
                              _calculatePositions(value.toInt());
                            });
                          },
                          onChangeStart: (value) {
                            if (!snapshot.data!.buffering) {
                              setState(() {
                                dragging = true;
                                _calculatePositions(currentPosition);
                              });
                            } else {
                              return null;
                            }
                          },
                          onChangeEnd: (value) {
                            setState(() {
                              dragging = false;
                            });

                            return snapshot.data!.buffering ? null : audioBloc.transitionPosition(value);
                          },
                          value: currentPosition.toDouble(),
                          min: 0.0,
                          max: episodeLength.toDouble(),
                          divisions: divisions,
                          activeColor: Theme.of(context).primaryColor,
                        )
                      : Slider(
                          onChanged: null,
                          value: 0,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                ),
                FittedBox(
                  child: Text(
                    _formatDuration(Duration(seconds: timeRemaining)),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _calculatePositions(int p) {
    currentPosition = p;
    timeRemaining = episodeLength - p;
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
