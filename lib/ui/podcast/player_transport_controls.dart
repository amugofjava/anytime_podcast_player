// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/widgets/sleep_selector.dart';
import 'package:anytime/ui/widgets/speed_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

/// Builds a transport control bar for rewind, play and fast-forward.
/// See [NowPlaying].
class PlayerTransportControls extends StatefulWidget {
  const PlayerTransportControls({
    super.key,
  });

  @override
  State<PlayerTransportControls> createState() => _PlayerTransportControlsState();
}

class _PlayerTransportControlsState extends State<PlayerTransportControls> {
  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: StreamBuilder<AudioState>(
          stream: audioBloc.playingState,
          initialData: AudioState.none,
          builder: (context, snapshot) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const SleepSelectorWidget(),
                IconButton(
                  onPressed: () {
                    return snapshot.data == AudioState.buffering ? null : _rewind(audioBloc);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: Icon(
                    semanticLabel: L.of(context)!.rewind_button_label,
                    Icons.replay_10,
                    size: 28.0,
                  ),
                ),
                AnimatedPlayButton(audioState: snapshot.data!),
                IconButton(
                  onPressed: () {
                    return snapshot.data == AudioState.buffering ? null : _fastforward(audioBloc);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: Icon(
                    semanticLabel: L.of(context)!.fast_forward_button_label,
                    Icons.forward_30,
                    size: 28.0,
                  ),
                ),
                const SpeedSelectorWidget(),
              ],
            );
          }),
    );
  }

  void _rewind(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.rewind);
  }

  void _fastforward(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.fastforward);
  }
}

typedef PlayHandler = Function(AudioBloc audioBloc);

class AnimatedPlayButton extends StatefulWidget {
  final AudioState audioState;
  final PlayHandler onPlay;
  final PlayHandler onPause;

  const AnimatedPlayButton({
    super.key,
    required this.audioState,
    this.onPlay = _onPlay,
    this.onPause = _onPause,
  });

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

void _onPlay(AudioBloc audioBloc) {
  audioBloc.transitionState(TransitionState.play);
}

void _onPause(AudioBloc audioBloc) {
  audioBloc.transitionState(TransitionState.pause);
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;
  late StreamSubscription<AudioState> _audioStateSubscription;
  bool init = true;

  @override
  void initState() {
    super.initState();

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    _playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    /// Seems a little hacky, but when we load the form we want the play/pause
    /// button to be in the correct state. If we are building the first frame,
    /// just set the animation controller to the correct state; for all other
    /// frames we want to animate. Doing it this way prevents the play/pause
    /// button from animating when the form is first loaded.
    _audioStateSubscription = audioBloc.playingState!.listen((event) {
      if (event == AudioState.playing || event == AudioState.buffering) {
        if (init) {
          _playPauseController.value = 1;
          init = false;
        } else {
          _playPauseController.forward();
        }
      } else {
        if (init) {
          _playPauseController.value = 0;
          init = false;
        } else {
          _playPauseController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _audioStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    final playing = widget.audioState == AudioState.playing;
    final buffering = widget.audioState == AudioState.buffering;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        if (buffering)
          SpinKitRing(
            lineWidth: 4.0,
            color: Theme.of(context).colorScheme.primary,
            size: 88,
          ),
        if (!buffering)
          const SizedBox(
            height: 88,
            width: 88,
          ),
        Tooltip(
          message: playing ? L.of(context)!.pause_button_label : L.of(context)!.play_button_label,
          child: TextButton(
            style: TextButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.all(10.0),
            ),
            onPressed: () {
              if (playing) {
                widget.onPause(audioBloc);
              } else {
                widget.onPlay(audioBloc);
              }
            },
            child: AnimatedIcon(
              size: 56.0,
              semanticLabel: playing ? L.of(context)!.pause_button_label : L.of(context)!.play_button_label,
              icon: AnimatedIcons.play_pause,
              color: Theme.of(context).colorScheme.onPrimary,
              progress: _playPauseController,
            ),
          ),
        ),
      ],
    );
  }
}
