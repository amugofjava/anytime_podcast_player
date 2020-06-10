// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/podcast/now_playing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Displays a mini podcast player widget if a podcast is playing or paused. If stopped a zero height
/// box is built instead.
class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return StreamBuilder<AudioState>(
        stream: audioBloc.playingState,
        builder: (context, snapshot) {
          return (snapshot.hasData && !(snapshot.data == AudioState.stopped || snapshot.data == AudioState.none))
              ? _MiniPlayerBuilder()
              : const SizedBox(
                  height: 0.0,
                );
        });
  }
}

class _MiniPlayerBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final audioBloc = Provider.of<AudioBloc>(context);

    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        await audioBloc.transitionState(TransitionState.stop);
        return true;
      },
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.orange,
        height: 64.0,
      ),
      child: GestureDetector(
        key: UniqueKey(),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => NowPlaying(), fullscreenDialog: false),
          );
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(width: 1.0, color: Colors.black12),
                bottom: BorderSide(width: 1.0, color: Colors.black12),
              )),
          child: StreamBuilder<Episode>(
              stream: audioBloc.nowPlaying,
              builder: (context, snapshot) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: snapshot.hasData
                            ? CachedNetworkImage(
                                imageUrl: snapshot.data.imageUrl,
                                width: 32,
                                placeholder: (context, url) {
                                  return Container(
                                    constraints: BoxConstraints.expand(height: 48, width: 48),
                                    child: Placeholder(
                                      color: Colors.grey,
                                      strokeWidth: 1,
                                      fallbackWidth: 40,
                                      fallbackHeight: 40,
                                    ),
                                  );
                                },
                                errorWidget: (_, __, dynamic ___) {
                                  return Container(
                                    constraints: BoxConstraints.expand(height: 48, width: 48),
                                    child: Placeholder(
                                      color: Colors.grey,
                                      strokeWidth: 1,
                                      fallbackWidth: 40,
                                      fallbackHeight: 40,
                                    ),
                                  );
                                },
                              )
                            : Container(),
                      ),
                    ),
                    Expanded(
                        flex: 3,
                        child: Container(
                          height: 48.0,
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
                          ),
                        )),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: StreamBuilder<AudioState>(
                            stream: audioBloc.playingState,
                            builder: (context, snapshot) {
                              return (snapshot.data == AudioState.playing)
                                  ? IconButton(
                                      onPressed: () {
                                        _pause(audioBloc);
                                      },
                                      tooltip: L.of(context).pause_button_label,
                                      padding: const EdgeInsets.all(0.0),
                                      icon: Icon(
                                        Icons.pause,
                                        size: 48.0,
                                        color: Colors.orange,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        _play(audioBloc);
                                      },
                                      tooltip: L.of(context).play_button_label,
                                      padding: const EdgeInsets.all(0.0),
                                      icon: Icon(
                                        Icons.play_arrow,
                                        size: 48.0,
                                        color: Colors.orange,
                                      ),
                                    );
                            }),
                      ),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  void _play(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.play);
  }

  void _pause(AudioBloc audioBloc) {
    audioBloc.transitionState(TransitionState.pause);
  }
}
