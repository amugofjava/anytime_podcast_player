// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/podcast/now_playing.dart';
import 'package:anytime/ui/widgets/expressive_linear_progress_indicator.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Displays a mini podcast player widget if a podcast is playing or paused.
///
/// If stopped a zero height box is built instead. Tapping on the mini player
/// will open the main player window.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    return StreamBuilder<AudioState>(
        stream: audioBloc.playingState,
        initialData: AudioState.stopped,
        builder: (context, snapshot) {
          return snapshot.data != AudioState.stopped &&
                  snapshot.data != AudioState.none &&
                  snapshot.data != AudioState.error
              ? _MiniPlayerBuilder()
              : const SizedBox(
                  height: 0.0,
                );
        });
  }
}

class _MiniPlayerBuilder extends StatefulWidget {
  @override
  _MiniPlayerBuilderState createState() => _MiniPlayerBuilderState();
}

class _MiniPlayerBuilderState extends State<_MiniPlayerBuilder> with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;
  late StreamSubscription<AudioState> _audioStateSubscription;

  @override
  void initState() {
    super.initState();

    _playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _playPauseController.value = 1;

    _audioStateListener();
  }

  @override
  void dispose() {
    _audioStateSubscription.cancel();
    _playPauseController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final padding = MediaQuery.paddingOf(context);
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        await _audioStateSubscription.cancel();
        audioBloc.transitionState(TransitionState.stop);
        return true;
      },
      direction: DismissDirection.startToEnd,
      background: Container(
        color: theme.colorScheme.surface,
        height: 64.0,
      ),
      child: GestureDetector(
        key: const Key('miniplayergesture'),
        onTap: () async {
          await _audioStateSubscription.cancel();

          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              routeSettings: const RouteSettings(name: 'nowplaying'),
              isScrollControlled: true,
              builder: (BuildContext modalContext) {
                return Padding(
                  padding: EdgeInsets.only(top: padding.top),
                  child: const NowPlaying(),
                );
              },
            ).then((_) {
              _audioStateListener();
            });
          }
        },
        child: Semantics(
          header: true,
          label: L.of(context)!.semantics_mini_player_header,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 24.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<Episode?>(
                        stream: audioBloc.nowPlaying,
                        initialData: audioBloc.nowPlaying?.valueOrNull,
                        builder: (context, snapshot) {
                          return StreamBuilder<AudioState>(
                              stream: audioBloc.playingState,
                              builder: (context, stateSnapshot) {
                                var playing = stateSnapshot.data == AudioState.playing;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(
                                      height: 58.0,
                                      width: 58.0,
                                      child: ExcludeSemantics(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: snapshot.hasData
                                              ? PodcastImage(
                                                  key: Key('mini${snapshot.data!.imageUrl}'),
                                                  url: snapshot.data!.imageUrl!,
                                                  width: 58.0,
                                                  height: 58.0,
                                                  borderRadius: 16.0,
                                                  placeholder: placeholderBuilder != null
                                                      ? placeholderBuilder.builder()(context)
                                                      : const Image(
                                                          image:
                                                              AssetImage('assets/images/anytime-placeholder-logo.png')),
                                                  errorPlaceholder: placeholderBuilder != null
                                                      ? placeholderBuilder.errorBuilder()(context)
                                                      : const Image(
                                                          image:
                                                              AssetImage('assets/images/anytime-placeholder-logo.png')),
                                                )
                                              : Container(),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              snapshot.data?.title ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                snapshot.data?.author ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        )),
                                    SizedBox(
                                      height: 52.0,
                                      width: 52.0,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                          backgroundColor: theme.colorScheme.surfaceContainerLow,
                                          shape: const CircleBorder(),
                                        ),
                                        onPressed: () {
                                          if (playing) {
                                            audioBloc.transitionState(TransitionState.fastforward);
                                          }
                                        },
                                        child: Icon(
                                          Icons.forward_30,
                                          semanticLabel: L.of(context)!.fast_forward_button_label,
                                          size: 36.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 52.0,
                                      width: 52.0,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          shape: const CircleBorder(),
                                        ),
                                        onPressed: () {
                                          if (playing) {
                                            _pause(audioBloc);
                                          } else {
                                            _play(audioBloc);
                                          }
                                        },
                                        child: AnimatedIcon(
                                          semanticLabel: playing
                                              ? L.of(context)!.pause_button_label
                                              : L.of(context)!.play_button_label,
                                          size: 48.0,
                                          icon: AnimatedIcons.play_pause,
                                          color: theme.colorScheme.onPrimary,
                                          progress: _playPauseController,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              });
                        }),
                    StreamBuilder<AudioState>(
                        stream: audioBloc.playingState,
                        initialData: AudioState.none,
                        builder: (context, stateSnapshot) {
                          final animateIndicator =
                              stateSnapshot.data == AudioState.playing || stateSnapshot.data == AudioState.buffering;

                          return StreamBuilder<PositionState>(
                              stream: audioBloc.playPosition,
                              initialData: audioBloc.playPosition?.valueOrNull,
                              builder: (context, snapshot) {
                                var position = snapshot.hasData ? snapshot.data!.position : const Duration(seconds: 0);
                                var length = snapshot.hasData ? snapshot.data!.length : const Duration(seconds: 0);
                                double? progress;

                                if (length.inMilliseconds > 0) {
                                  progress = position.inMilliseconds / length.inMilliseconds;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: ExpressiveLinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4.0,
                                    amplitude: 2.4,
                                    frequency: 12.0,
                                    phaseCycles: 2.6,
                                    animationDuration: const Duration(milliseconds: 600),
                                    animated: animateIndicator,
                                    color: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  ),
                                );
                              });
                        }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// We call this method to setup a listener for changing [AudioState]. This in turns calls upon the [_pauseController]
  /// to animate the play/pause icon. The [AudioBloc] playingState method is backed by a [BehaviorSubject] so we'll
  /// always get the current state when we subscribe. This, however, has a side effect causing the play/pause icon to
  /// animate when returning from the full-size player, which looks a little odd. Therefore, on the first event we move
  /// the controller to the correct state without animating. This feels a little hacky, but stops the UI from looking a
  /// little odd.
  void _audioStateListener() {
    if (mounted) {
      final audioBloc = Provider.of<AudioBloc>(context, listen: false);
      var firstEvent = true;

      _audioStateSubscription = audioBloc.playingState!.listen((event) {
        if (event == AudioState.playing || event == AudioState.buffering) {
          if (firstEvent) {
            _playPauseController.value = 1;
            firstEvent = false;
          } else {
            _playPauseController.forward();
          }
        } else {
          if (firstEvent) {
            _playPauseController.value = 0;
            firstEvent = false;
          } else {
            _playPauseController.reverse();
          }
        }
      });
    }
  }

  void _play(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.play);
  }

  void _pause(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.pause);
  }
}
