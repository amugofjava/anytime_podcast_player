// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Builds a transport control bar for rewind, play and fast-forward.
/// See [NowPlaying].
class PlayerTransportControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AudioBloc audioBloc = Provider.of<AudioBloc>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42.0),
      child: StreamBuilder<AudioState>(
          stream: audioBloc.playingState,
          builder: (context, snapshot) {
            var playing = snapshot.data == AudioState.playing;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    _rewind(audioBloc);
                  },
                  tooltip: L.of(context).rewind_button_label,
                  padding: const EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.replay_30,
                    size: 48.0,
                    color: Colors.orange,
                  ),
                ),
                Tooltip(
                  message: playing ? L.of(context).fast_forward_button_label : L.of(context).play_button_label,
                  child: FlatButton(
                    onPressed: () {
                      if (playing) {
                        _pause(audioBloc);
                      } else {
                        _play(audioBloc);
                      }
                    },
                    shape: CircleBorder(side: BorderSide(color: Colors.orange, width: 2.0)),
                    color: Colors.orange,
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      size: 60.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _fastforward(audioBloc);
                  },
                  padding: const EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.forward_30,
                    size: 48.0,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          }),
    );
  }

  void _play(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.play);
  }

  void _pause(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.pause);
  }

  void _rewind(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.rewind);
  }

  void _fastforward(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.fastforward);
  }
}
