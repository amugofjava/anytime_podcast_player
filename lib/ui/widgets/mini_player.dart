// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/podcast/now_playing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:provider/provider.dart';

/// Displays a mini podcast player widget if a podcast is playing or paused. If stopped a zero height
/// box is built instead.
class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    return StreamBuilder<AudioState>(
        stream: audioBloc.playingState,
        builder: (context, snapshot) {
          return (snapshot.hasData &&
                  !(snapshot.data == AudioState.stopped ||
                      snapshot.data == AudioState.none ||
                      snapshot.data == AudioState.error))
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
  AnimationController _playPauseController;
  StreamSubscription<AudioState> _audioStateSubscription;

  @override
  void initState() {
    super.initState();

    _playPauseController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _playPauseController.value = 1;

    audioStateListener();
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _audioStateSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    return Dismissible(
      key: Key('miniplayerdismissable'),
      confirmDismiss: (direction) async {
        await audioBloc.transitionState(TransitionState.stop);
        return true;
      },
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height: 64.0,
      ),
      child: GestureDetector(
        key: Key('miniplayergesture'),
        onTap: () async {
          await _audioStateSubscription.cancel();

          return Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => NowPlaying(), fullscreenDialog: false),
          ).then((value) {
            audioStateListener();
          });
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
              color: Theme.of(context).bottomAppBarColor,
              border: Border(
                top: Divider.createBorderSide(context, width: 1.0, color: Theme.of(context).dividerColor),
                bottom: Divider.createBorderSide(context, width: 1.0, color: Theme.of(context).dividerColor),
              )),
          child: StreamBuilder<Episode>(
              stream: audioBloc.nowPlaying,
              builder: (context, snapshot) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 58.0,
                      width: 58.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: snapshot.hasData
                            ? OptimizedCacheImage(
                                imageUrl: snapshot.data.imageUrl,
                                placeholder: (context, url) {
                                  return Image(image: AssetImage('assets/images/anytime-placeholder-logo.png'));
                                },
                                errorWidget: (_, __, dynamic ___) {
                                  return Image(image: AssetImage('assets/images/anytime-placeholder-logo.png'));
                                },
                              )
                            : Container(),
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
                              style: textTheme.subtitle1,
                            ),
                            Text(
                              snapshot.data?.author ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyText1,
                            ),
                          ],
                        )),
                    SizedBox(
                      height: 64.0,
                      width: 64.0,
                      child: StreamBuilder<AudioState>(
                          stream: audioBloc.playingState,
                          builder: (context, snapshot) {
                            var playing = snapshot.data == AudioState.playing;

                            return FlatButton(
                              padding: const EdgeInsets.symmetric(horizontal: 0.0),
                              onPressed: () {
                                if (playing) {
                                  _pause(audioBloc);
                                } else {
                                  _play(audioBloc);
                                }
                              },
                              shape: CircleBorder(
                                  side: BorderSide(color: Theme.of(context).bottomAppBarColor, width: 0.0)),
                              child: AnimatedIcon(
                                size: 48.0,
                                icon: AnimatedIcons.play_pause,
                                color: Theme.of(context).buttonColor,
                                progress: _playPauseController,
                              ),
                            );
                          }),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  /// We call this method to setup a listener for changing [AudioState]. This
  /// in turns calls upon the [_pauseController] to animate the play/pause icon.
  /// The [AudioBloc] playingState method is backed by a [BehaviorSubject] so
  /// we'll always get the current state when we subscribe. This, however, has
  /// a side effect causing the play/pause icon to animate when returning from
  /// the full-size player, which looks a little odd. Therefore, on the first
  /// event we move the controller to the correct state without animating. This
  /// feels a little hacky, but stops the UI from looking a little odd.
  void audioStateListener() {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    var firstEvent = true;

    _audioStateSubscription = audioBloc.playingState.listen((event) {
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

  void _play(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.play);
  }

  void _pause(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.pause);
  }
}
