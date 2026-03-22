// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/chapter_selector.dart';
import 'package:anytime/ui/podcast/dot_decoration.dart';
import 'package:anytime/ui/podcast/now_playing_options.dart';
import 'package:anytime/ui/podcast/person_avatar.dart';
import 'package:anytime/ui/podcast/playback_error_listener.dart';
import 'package:anytime/ui/podcast/player_position_controls.dart';
import 'package:anytime/ui/podcast/player_transport_controls.dart';
import 'package:anytime/ui/widgets/delayed_progress_indicator.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// This is the full-screen player Widget which is invoked by touching the mini player.
///
/// This is the parent widget of the now playing screen(s). If we are running on a mobile in
/// portrait mode, we display the episode details, controls and additional options
/// as a draggable view. For tablets in portrait or on desktop, we display a split
/// screen. The main details and controls appear in one pane with the additional
/// controls in another.
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
        popped = true;
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    playingStateSubscription.cancel();

    super.dispose();
  }

  bool isMobilePortrait(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final width = MediaQuery.widthOf(context);

    return (orientation == Orientation.portrait || width <= 1000);
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final playerBuilder = PlayerControlsBuilder.of(context);

    return Semantics(
      header: false,
      label: L.of(context)!.semantics_main_player_header,
      explicitChildNodes: true,
      child: StreamBuilder<Episode?>(
          stream: audioBloc.nowPlaying,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            var duration = snapshot.data == null ? 0 : snapshot.data!.duration;
            final WidgetBuilder? transportBuilder = playerBuilder?.builder(duration);

            return isMobilePortrait(context)
                ? NowPlayingMobileScaffold(
                    episode: snapshot.data!,
                    transportBuilder: transportBuilder,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex: 1,
                        child: NowPlayingTabs(episode: snapshot.data!, transportBuilder: transportBuilder),
                      ),
                      const Expanded(
                        flex: 1,
                        child: NowPlayingOptionsSelectorWide(),
                      ),
                    ],
                  );
          }),
    );
  }
}

class NowPlayingMobileScaffold extends StatelessWidget {
  final Episode episode;
  final WidgetBuilder? transportBuilder;

  const NowPlayingMobileScaffold({
    super.key,
    required this.episode,
    required this.transportBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            tooltip: L.of(context)!.minimise_player_window_button_label,
            icon: Icon(
              Icons.expand_more,
              color: theme.colorScheme.onSurface,
              semanticLabel: L.of(context)!.minimise_player_window_button_label,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Now Playing'),
          actions: [
            IconButton(
              tooltip: L.of(context)!.share_episode_option_label,
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                await shareEpisode(episode: episode);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'share') {
                  await shareEpisode(episode: episode);
                } else if (value == 'queue') {
                  final queueBloc = Provider.of<QueueBloc>(context, listen: false);
                  queueBloc.queueEvent(QueueAddEvent(episode: episode));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'queue',
                  child: Text(L.of(context)!.podcast_context_queue_latest_episode_label),
                ),
                PopupMenuItem<String>(
                  value: 'share',
                  child: Text(L.of(context)!.share_episode_option_label),
                ),
              ],
            ),
          ],
        ),
        body: PlaybackErrorListener(
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: NowPlayingArtworkCard(
                          imageUrl: episode.positionalImageUrl ?? episode.imageUrl,
                        ),
                      ),
                      const SizedBox(height: 22.0),
                      _NowPlayingTitleBlock(episode: episode),
                      const SizedBox(height: 18.0),
                      transportBuilder != null
                          ? transportBuilder!(context)
                          : const SizedBox(
                              height: 148.0,
                              child: NowPlayingTransport(),
                            ),
                      const SizedBox(height: 18.0),
                      _NowPlayingDetailsCard(episode: episode),
                      const SizedBox(height: 14.0),
                      const _NowPlayingQueueBar(),
                    ],
                  ),
                ),
              ),
              const Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                    child: NowPlayingOptionsSelectorWide(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NowPlayingArtworkCard extends StatelessWidget {
  final String? imageUrl;

  const NowPlayingArtworkCard({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = PlaceholderBuilder.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = (width - 40.0).clamp(240.0, 360.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: 12.0,
            left: 12.0,
            right: 0.0,
            bottom: 0.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(34.0),
              ),
            ),
          ),
          Positioned(
            top: 4.0,
            left: 0.0,
            right: 12.0,
            bottom: 12.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(34.0),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                      ),
                      child: Icon(
                        Icons.podcasts_rounded,
                        size: 72.0,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : PodcastImage(
                      key: Key('nowplaying$imageUrl'),
                      url: imageUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      borderRadius: 30.0,
                      placeholder: placeholderBuilder != null
                          ? placeholderBuilder.builder()(context)
                          : DelayedCircularProgressIndicator(),
                      errorPlaceholder: placeholderBuilder != null
                          ? placeholderBuilder.errorBuilder()(context)
                          : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingTitleBlock extends StatelessWidget {
  final Episode episode;

  const _NowPlayingTitleBlock({
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    final theme = Theme.of(context);
    final subtitle = _episodeSubtitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                episode.title ?? '',
                style: theme.textTheme.headlineMedium?.copyWith(height: 1.06),
              ),
            ),
            IconButton(
              onPressed: () {
                queueBloc.queueEvent(QueueAddEvent(episode: episode));
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6.0),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _episodeSubtitle() {
    final parts = <String>[];

    final podcast = episode.podcast?.trim();
    if (podcast != null && podcast.isNotEmpty) {
      parts.add(podcast);
    }

    if (episode.episode > 0) {
      parts.add('Ep. ${episode.episode}');
    } else if (episode.season > 0) {
      parts.add('Season ${episode.season}');
    }

    return parts.join(' • ');
  }
}

class _NowPlayingDetailsCard extends StatelessWidget {
  final Episode episode;

  const _NowPlayingDetailsCard({
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    final theme = Theme.of(context);
    final title = episode.podcast?.trim().isNotEmpty == true ? episode.podcast!.trim() : 'This episode';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        children: [
          Container(
            width: 42.0,
            height: 42.0,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(
              Icons.speaker_group_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LISTENING TO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          FilledButton.tonal(
            onPressed: () {
              queueBloc.queueEvent(QueueAddEvent(episode: episode));
            },
            child: const Text('Queue'),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingQueueBar extends StatelessWidget {
  const _NowPlayingQueueBar();

  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder<QueueState>(
      stream: queueBloc.queue,
      initialData: QueueEmptyState(),
      builder: (context, snapshot) {
        final queue = snapshot.data?.queue ?? const <Episode>[];
        final next = queue.isNotEmpty ? queue.first : null;
        final label = next?.title?.trim().isNotEmpty == true ? next!.title! : 'Queue is empty';

        return Container(
          padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 14.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  next == null ? label : 'Up Next: $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              SizedBox(
                width: 18.0,
                height: 14.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(4, (index) {
                    final heights = [14.0, 9.0, 11.0, 7.0];
                    return Padding(
                      padding: EdgeInsets.only(right: index == 3 ? 0.0 : 2.0),
                      child: Container(
                        width: 3.0,
                        height: heights[index],
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// This widget displays the episode logo, episode title and current
/// chapter if available.
///
/// If running in portrait this will be in a vertical format; if in
/// landscape this will be in a horizontal format. The actual displaying
/// of the episode text is handed off to [NowPlayingEpisodeDetails].
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
    final orientation = MediaQuery.orientationOf(context);
    final size = MediaQuery.sizeOf(context);

    return OrientationBuilder(
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: orientation == Orientation.portrait || size.width >= 1000
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Semantics(
                        label: L.of(context)!.semantic_podcast_artwork_label,
                        child: PodcastImage(
                          key: Key('nowplaying$imageUrl'),
                          url: imageUrl!,
                          width: size.width * .75,
                          height: size.height * .75,
                          fit: BoxFit.contain,
                          borderRadius: 6.0,
                          placeholder: placeholderBuilder != null
                              ? placeholderBuilder.builder()(context)
                              : DelayedCircularProgressIndicator(),
                          errorPlaceholder: placeholderBuilder != null
                              ? placeholderBuilder.errorBuilder()(context)
                              : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                        ),
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
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          bottom: 8.0,
                        ),
                        child: PodcastImage(
                          key: Key('nowplaying$imageUrl'),
                          url: imageUrl!,
                          height: 280,
                          width: 280,
                          fit: BoxFit.contain,
                          borderRadius: 8.0,
                          placeholder: placeholderBuilder != null
                              ? placeholderBuilder.builder()(context)
                              : DelayedCircularProgressIndicator(),
                          errorPlaceholder: placeholderBuilder != null
                              ? placeholderBuilder.errorBuilder()(context)
                              : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
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

/// This widget is responsible for displaying the main episode details.
///
/// This displays the current episode title and, if available, the
/// current chapter title and optional link.
class NowPlayingEpisodeDetails extends StatelessWidget {
  final Episode? episode;
  final AutoSizeGroup? textGroup;
  static const minFontSize = 14.0;

  const NowPlayingEpisodeDetails({
    super.key,
    this.episode,
    this.textGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chapterTitle = episode?.currentChapter?.title ?? '';
    final chapterUrl = episode?.currentChapter?.url ?? '';

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
            child: Semantics(
              container: true,
              child: AutoSizeText(
                episode?.title ?? '',
                group: textGroup,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                minFontSize: minFontSize,
                style: theme.textTheme.headlineMedium,
                maxLines: episode!.hasChapters ? 3 : 4,
              ),
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
                    child: Semantics(
                      label: L.of(context)!.semantic_current_chapter_label,
                      container: true,
                      child: AutoSizeText(
                        chapterTitle,
                        group: textGroup,
                        minFontSize: minFontSize,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ),
                  chapterUrl.isEmpty
                      ? const SizedBox(
                          height: 0,
                          width: 0,
                        )
                      : Semantics(
                          label: L.of(context)!.semantic_chapter_link_label,
                          container: true,
                          child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.link,
                              ),
                              color: colorScheme.primary,
                              onPressed: () {
                                _chapterLink(chapterUrl);
                              }),
                        ),
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

/// This widget handles the displaying of the episode show notes.
///
/// This consists of title, show notes and person details
/// (where available).
class NowPlayingShowNotes extends StatelessWidget {
  final Episode? episode;

  const NowPlayingShowNotes({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  style: theme.textTheme.titleLarge!.copyWith(
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
              child: PodcastHtml(content: episode?.content ?? episode?.description ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for rendering main episode tabs.
///
/// This will be episode details and show notes. If the episode supports chapters
/// this will be included also. This is the parent widget. The tabs are
/// rendered via [EpisodeTabBar] and the tab contents via. [EpisodeTabBarView].
class NowPlayingTabs extends StatelessWidget {
  const NowPlayingTabs({
    super.key,
    required this.transportBuilder,
    required this.episode,
  });

  final WidgetBuilder? transportBuilder;
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientation = MediaQuery.orientationOf(context);

    return DefaultTabController(
        length: episode.hasChapters ? 3 : 2,
        initialIndex: episode.hasChapters ? 1 : 0,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: theme.appBarTheme.systemOverlayStyle!
              .copyWith(systemNavigationBarColor: theme.colorScheme.surfaceContainerLow),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              elevation: 0.0,
              leading: IconButton(
                tooltip: L.of(context)!.minimise_player_window_button_label,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurface,
                  semanticLabel: L.of(context)!.minimise_player_window_button_label,
                ),
                onPressed: () => {
                  Navigator.pop(context),
                },
              ),
              flexibleSpace: PlaybackErrorListener(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    EpisodeTabBar(
                      chapters: episode.hasChapters,
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: EpisodeTabBarView(
                    episode: episode,
                    chapters: episode.hasChapters,
                  ),
                ),
                transportBuilder != null
                    ? transportBuilder!(context)
                    : const SizedBox(
                        height: 148.0,
                        child: NowPlayingTransport(),
                      ),
                if (orientation == Orientation.portrait)
                  const Expanded(
                    flex: 1,
                    child: NowPlayingOptionsScaffold(),
                  ),
              ],
            ),
          ),
        ));
  }
}

/// This class is responsible for rendering the tab selection at the top of the screen.
///
/// It displays two or three tabs depending upon whether the current episode supports
/// (and contains) chapters.
class EpisodeTabBar extends StatefulWidget {
  final bool chapters;

  const EpisodeTabBar({
    super.key,
    this.chapters = false,
  });

  @override
  State<EpisodeTabBar> createState() => _EpisodeTabBarState();
}

class _EpisodeTabBarState extends State<EpisodeTabBar> {
  late AudioBloc audioBloc;
  StreamSubscription<Episode?>? episodeSubscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TabBar(
      isScrollable: true,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: DotDecoration(colour: theme.colorScheme.primary),
      tabs: [
        if (widget.chapters)
          Tab(
            child: Align(
              alignment: Alignment.center,
              child: Text(L.of(context)!.chapters_label),
            ),
          ),
        Tab(
          child: Align(
            alignment: Alignment.center,
            child: Text(L.of(context)!.episode_label),
          ),
        ),
        Tab(
          child: Align(
            alignment: Alignment.center,
            child: Text(L.of(context)!.notes_label),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    Episode? previousEpisode;

    audioBloc = Provider.of<AudioBloc>(context, listen: false);

    /// The number of tabs available depends upon whether the episode has chapters or not.
    /// To ensure that we always start the episode on the main playing tab, we sit and list
    /// for episode changes and update the tab index accordingly.
    episodeSubscription = audioBloc.nowPlaying?.listen((Episode? episode) {
      if (episode != previousEpisode) {
        final index = (episode?.hasChapters ?? false) ? 1 : 0;
        DefaultTabController.of(context).animateTo(index, duration: Duration.zero);
      }

      previousEpisode = episode;
    });
  }

  @override
  void dispose() {
    episodeSubscription?.cancel();
    super.dispose();
  }
}

/// This class is responsible for rendering the tab bodies.
///
/// This includes the chapter selection view (if the episode supports chapters),
/// the episode details (image and description) and the show notes view.
class EpisodeTabBarView extends StatelessWidget {
  final Episode? episode;
  final AutoSizeGroup? textGroup;
  final bool chapters;

  const EpisodeTabBarView({
    super.key,
    this.episode,
    this.textGroup,
    this.chapters = false,
  });

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return TabBarView(
      children: [
        if (chapters)
          ChapterSelector(
            episode: episode!,
          ),
        StreamBuilder<Episode?>(
            stream: audioBloc.nowPlaying,
            builder: (context, snapshot) {
              final e = snapshot.hasData ? snapshot.data! : episode!;

              return NowPlayingEpisode(
                episode: e,
                imageUrl: e.positionalImageUrl,
                textGroup: textGroup,
              );
            }),
        NowPlayingShowNotes(episode: episode),
      ],
    );
  }
}

/// This is the parent widget for the episode position and transport
/// controls.
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

/// This widget allows users to inject their own transport controls
/// into the app.
///
/// When rendering the controls, Anytime will check if a PlayerControlsBuilder
/// is in the tree. If so, it will use the builder rather than its own
/// transport controls.
class PlayerControlsBuilder extends InheritedWidget {
  final WidgetBuilder Function(int duration) builder;

  const PlayerControlsBuilder({
    super.key,
    required this.builder,
    required super.child,
  });

  static PlayerControlsBuilder? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PlayerControlsBuilder>();
  }

  @override
  bool updateShouldNotify(PlayerControlsBuilder oldWidget) {
    return builder != oldWidget.builder;
  }
}
