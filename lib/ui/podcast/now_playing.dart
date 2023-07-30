// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/ui/podcast/now_playing_floating_player.dart';
import 'package:anytime/ui/podcast/now_playing_options.dart';
import 'package:anytime/ui/podcast/now_playing_tabs.dart';
import 'package:anytime/ui/podcast/person_avatar.dart';
import 'package:anytime/ui/podcast/player_position_controls.dart';
import 'package:anytime/ui/podcast/player_transport_controls.dart';
import 'package:anytime/ui/widgets/delayed_progress_indicator.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// This is the full-screen player Widget which is invoked by touching the mini player.
///
/// This displays the podcast image, episode notes and standard playback controls.
///
/// TODO: The fade in/out transition applied when scrolling the queue is the first implementation.
/// Using [Opacity] is a very inefficient way of achieving this effect, but will do as a place
/// holder until a better animation can be achieved.
class NowPlaying extends StatefulWidget {
  const NowPlaying({
    super.key,
  });

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> with WidgetsBindingObserver {
  late StreamSubscription<AudioState> playingStateSubscription;
  var textGroup = AutoSizeGroup();
  double scrollPos = 0.0;
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    var popped = false;

    // If the episode finishes we can close.
    playingStateSubscription =
        audioBloc.playingState!.where((state) => state == AudioState.stopped).listen((playingState) async {
      // Prevent responding to multiple stop events after we've popped and lost context.
      if (!popped) {
        Navigator.pop(context);
        popped = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    playingStateSubscription.cancel();

    super.dispose();
  }

  bool isNarrow(BuildContext context) {
    final query = MediaQuery.of(context);
    return (query.orientation == Orientation.portrait || query.size.width <= 800);
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final playerBuilder = PlayerControlsBuilder.of(context);

    return Semantics(
      header: true,
      label: L.of(context)!.semantics_main_player_header,
      child: StreamBuilder<Episode?>(
          stream: audioBloc.nowPlaying,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            var duration = snapshot.data == null ? 0 : snapshot.data!.duration;
            final WidgetBuilder? transportBuilder = playerBuilder?.builder(duration);

            return isNarrow(context) ? NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() {
                  if (notification.extent > (notification.minExtent)) {
                    opacity = 1 - (notification.maxExtent - notification.extent);
                    scrollPos = 1.0;
                  } else {
                    opacity = 0.0;
                    scrollPos = 0.0;
                  }
                });

                return true;
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NowPlayingTabs(episode: snapshot.data!, transportBuilder: transportBuilder),
                  SizedBox.expand(
                      child: SafeArea(
                    child: Column(
                      children: [
                        /// Sized boxes without a child are 'invisible' so they do not prevent taps below
                        /// the stack but are still present in the layout. We have a sized box here to stop
                        /// the draggable panel from jumping as you start to pull it up. I am really looking
                        /// forward to the Dart team fixing the nested scroll issues with [DraggableScrollableSheet]
                        SizedBox(
                          height: 64.0,
                          child: scrollPos == 1
                              ? Opacity(
                                  opacity: opacity,
                                  child: const FloatingPlayer(),
                                )
                              : null,
                        ),
                        const Expanded(
                          child: NowPlayingOptionsSelector(),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ) : Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(flex: 1, child: NowPlayingTabs(episode: snapshot.data!, transportBuilder: transportBuilder)),
                const Expanded(flex: 1, child: NowPlayingOptionsSelectorWide()),
              ],
            );
          }),
    );
  }
}

class NowPlayingEpisode extends StatelessWidget {
  final String? imageUrl;
  final Episode episode;
  final AutoSizeGroup? textGroup;

  const NowPlayingEpisode({
    super.key,
    required this.imageUrl,
    required this.episode,
    required this.textGroup,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return OrientationBuilder(
      builder: (context, orientation) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: MediaQuery.of(context).orientation == Orientation.portrait || MediaQuery.of(context).size.width >= 800
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: PodcastImage(
                        key: Key('nowplaying$imageUrl'),
                        url: imageUrl!,
                        width: MediaQuery.of(context).size.width * .75,
                        height: MediaQuery.of(context).size.height * .75,
                        fit: BoxFit.contain,
                        borderRadius: 6.0,
                        placeholder: placeholderBuilder != null
                            ? placeholderBuilder.builder()(context)
                            : const DelayedCircularProgressIndicator(),
                        errorPlaceholder: placeholderBuilder != null
                            ? placeholderBuilder.errorBuilder()(context)
                            : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: NowPlayingEpisodeDetails(
                        episode: episode,
                        textGroup: textGroup,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: PodcastImage(
                        key: Key('nowplaying$imageUrl'),
                        url: imageUrl!,
                        height: 280,
                        width: 280,
                        fit: BoxFit.contain,
                        borderRadius: 8.0,
                        placeholder: placeholderBuilder != null
                            ? placeholderBuilder.builder()(context)
                            : const DelayedCircularProgressIndicator(),
                        errorPlaceholder: placeholderBuilder != null
                            ? placeholderBuilder.errorBuilder()(context)
                            : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: NowPlayingEpisodeDetails(
                        episode: episode,
                        textGroup: textGroup,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class NowPlayingEpisodeDetails extends StatelessWidget {
  final Episode? episode;
  final AutoSizeGroup? textGroup;
  static const minFontSize = 14.0;

  const NowPlayingEpisodeDetails({
    Key? key,
    this.episode,
    this.textGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chapterTitle = episode?.currentChapter?.title ?? '';
    final chapterUrl = episode?.currentChapter?.url ?? '';

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
            child: AutoSizeText(
              episode?.title ?? '',
              group: textGroup,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              minFontSize: minFontSize,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
              maxLines: episode!.hasChapters ? 3 : 4,
            ),
          ),
        ),
        if (episode!.hasChapters)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      chapterTitle,
                      group: textGroup,
                      minFontSize: minFontSize,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.normal,
                        fontSize: 16.0,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  chapterUrl.isEmpty
                      ? const SizedBox(
                          height: 0,
                          width: 0,
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.link),
                          color: Theme.of(context).primaryIconTheme.color,
                          onPressed: () {
                            _chapterLink(chapterUrl);
                          }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _chapterLink(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch chapter link: $url';
    }
  }
}

class NowPlayingShowNotes extends StatelessWidget {
  final Episode? episode;

  const NowPlayingShowNotes({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Text(
                  episode!.title!,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            if (episode!.persons.isNotEmpty)
              SizedBox(
                height: 120.0,
                child: ListView.builder(
                  itemCount: episode!.persons.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    return PersonAvatar(person: episode!.persons[index]);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                left: 8.0,
                right: 8.0,
              ),
              child: PodcastHtml(content: episode!.description!),
            ),
          ],
        ),
      ),
    );
  }
}

class NowPlayingTransport extends StatelessWidget {
  const NowPlayingTransport({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Divider(
          height: 0.0,
        ),
        PlayerPositionControls(),
        PlayerTransportControls(),
      ],
    );
  }
}

class PlayerControlsBuilder extends InheritedWidget {
  final WidgetBuilder Function(int duration) builder;

  const PlayerControlsBuilder({
    Key? key,
    required this.builder,
    required Widget child,
  }) : super(key: key, child: child);

  static PlayerControlsBuilder? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PlayerControlsBuilder>();
  }

  @override
  bool updateShouldNotify(PlayerControlsBuilder oldWidget) {
    return builder != oldWidget.builder;
  }
}
