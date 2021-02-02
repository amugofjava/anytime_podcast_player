// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/podcast/player_position_controls.dart';
import 'package:anytime/ui/podcast/player_transport_controls.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:html/parser.dart';
import 'package:provider/provider.dart';

/// This is the full-screen player Widget which is invoked
/// by touching the mini player. This displays the podcast
/// image, episode notes and standard playback controls.
class NowPlaying extends StatefulWidget {
  @override
  _NowPlayingState createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> with WidgetsBindingObserver {
  StreamSubscription<AudioState> playingStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    // If the episode finishes we can close.
    playingStateSubscription = audioBloc.playingState.listen((playingState) async {
      if (playingState == AudioState.stopped) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    playingStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return Scaffold(
      body: StreamBuilder<Episode>(
          stream: audioBloc.nowPlaying,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            var duration = snapshot.data == null ? 0 : snapshot.data.duration;

            return SafeArea(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: AppBar(
                      brightness: Theme.of(context).brightness,
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      leading: IconButton(
                        tooltip: L.of(context).minimise_player_window_button_label,
                        icon: Icon(Icons.keyboard_arrow_down),
                        onPressed: () => {
                          Navigator.pop(context),
                        },
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      snapshot.data == null
                          ? Container()
                          : Expanded(
                              child: NowPlayingHeader(imageUrl: snapshot.data.imageUrl),
                              flex: 6,
                            ),
                      Expanded(
                        child: NowPlayingDetails(title: snapshot.data.title, description: snapshot.data.description),
                        flex: 4,
                      ),
                      SizedBox(
                        height: 160.0,
                        child: NowPlayingTransport(duration: duration),
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
    );
  }
}

class NowPlayingHeader extends StatelessWidget {
  final String imageUrl;

  const NowPlayingHeader({@required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return StreamBuilder<AudioState>(
        stream: audioBloc.playingState,
        builder: (context, statesnap) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: GestureDetector(
              onTap: () {
                if (statesnap.data == AudioState.playing) {
                  audioBloc.transitionState(TransitionState.pause);
                } else {
                  audioBloc.transitionState(TransitionState.play);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) {
                    return Container(
                      color: Theme.of(context).primaryColorLight,
                      constraints: BoxConstraints.expand(),
                    );
                  },
                  errorWidget: (_, __, dynamic ___) {
                    return Container(
                      constraints: BoxConstraints.expand(),
                      child: Placeholder(
                        color: Theme.of(context).errorColor,
                        strokeWidth: 1,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        });
  }
}

class NowPlayingDetails extends StatelessWidget {
  final String title;
  final String description;

  const NowPlayingDetails({
    @required this.title,
    @required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Text(
              parseFragment(description).text,
            ),
          ),
        ]),
      ),
    );
  }
}

class NowPlayingTransport extends StatelessWidget {
  final int duration;

  const NowPlayingTransport({@required this.duration});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Divider(
          height: 0.0,
        ),
        PlayerPositionControls(
          duration: duration,
        ),
        PlayerTransportControls(),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 0.0,
          ),
        ),
      ],
    );
  }
}
