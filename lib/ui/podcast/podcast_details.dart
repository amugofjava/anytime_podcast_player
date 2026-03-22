// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/podcast/funding_menu.dart';
import 'package:anytime/ui/podcast/playback_error_listener.dart';
import 'package:anytime/ui/podcast/podcast_context_menu.dart';
import 'package:anytime/ui/podcast/podcast_episode_list.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/delayed_progress_indicator.dart';
import 'package:anytime/ui/widgets/episode_filter_selector.dart';
import 'package:anytime/ui/widgets/episode_sort_selector.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/platform_back_button.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

/// This Widget takes a search result and builds a list of currently available podcasts.
///
/// From here a user can option to subscribe/unsubscribe or play a podcast directly
/// from a search result.
class PodcastDetails extends StatefulWidget {
  final Podcast podcast;
  final PodcastBloc _podcastBloc;

  const PodcastDetails(
    this.podcast,
    this._podcastBloc, {
    super.key,
  });

  @override
  State<PodcastDetails> createState() => _PodcastDetailsState();
}

class _PodcastDetailsState extends State<PodcastDetails> {
  final log = Logger('PodcastDetails');
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _sliverScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    log.fine('initState() - load feed');

    widget._podcastBloc.load(Feed(
      podcast: widget.podcast,
      backgroundFetch: true,
      errorSilently: true,
    ));

    widget._podcastBloc.backgroundLoading.where((event) => event is BlocPopulatedState<void>).listen((event) {
      if (mounted) {
        if (_sliverScrollController.offset < 20) {
          widget._podcastBloc.podcastEvent(PodcastEvent.refresh);
        } else {
          scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
            content: Text(L.of(context)!.new_episodes_label),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: L.of(context)!.new_episodes_view_now_label,
              onPressed: () {
                _sliverScrollController.animateTo(100,
                    duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                widget._podcastBloc.podcastEvent(PodcastEvent.refresh);
              },
            ),
            duration: const Duration(seconds: 5),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _sliverScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    log.fine('_handleRefresh');

    widget._podcastBloc.load(Feed(
      podcast: widget.podcast,
      forceFetch: true,
    ));
  }

  /// TODO: This really needs a refactor. There are too many nested streams on this now and it needs simplifying.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final placeholderBuilder = PlaceholderBuilder.of(context);
    final overlayStyle = theme.brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;

    return Semantics(
      header: false,
      label: L.of(context)!.semantics_podcast_details_header,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          podcastBloc.podcastSearchEvent('');
        },
        child: ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: RefreshIndicator(
              displacement: 60.0,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _sliverScrollController,
                slivers: <Widget>[
                  SliverAppBar(
                    systemOverlayStyle: overlayStyle.copyWith(statusBarColor: Colors.transparent),
                    backgroundColor: theme.colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0.0,
                    pinned: true,
                    titleSpacing: 0.0,
                    title: Text(
                      widget.podcast.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: PlatformBackButton(
                      iconColour: theme.colorScheme.onSurface,
                      decorationColour: Colors.transparent,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  StreamBuilder<BlocState<Podcast>>(
                    initialData: BlocEmptyState<Podcast>(),
                    stream: podcastBloc.details,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      var podcast = widget.podcast;
                      var isLoading = false;

                      if (state is BlocLoadingState<Podcast>) {
                        isLoading = true;
                        podcast = state.data ?? widget.podcast;
                      } else if (state is BlocPopulatedState<Podcast>) {
                        podcast = state.results!;
                      }

                      if (state is BlocErrorState) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  Icons.error_outline,
                                  size: 50,
                                ),
                                Text(
                                  L.of(context)!.no_podcast_details_message,
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverToBoxAdapter(
                        child: PlaybackErrorListener(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PodcastTitle(
                                key: ValueKey('header-${podcast.url}'),
                                podcast: podcast,
                                placeholderBuilder: placeholderBuilder,
                              ),
                              EpisodesSectionHeader(
                                key: ValueKey('episodes-header-${podcast.url}'),
                                podcast: podcast,
                              ),
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
                                  child: PlatformProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  StreamBuilder<BlocState<Podcast>>(
                    initialData: BlocEmptyState<Podcast>(),
                    stream: podcastBloc.details,
                    builder: (context1, snapshot1) {
                      final state = snapshot1.data;

                      if (state is BlocPopulatedState<Podcast>) {
                        return StreamBuilder<List<Episode?>?>(
                          stream: podcastBloc.episodes,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return snapshot.data!.isNotEmpty
                                  ? SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 24.0),
                                      sliver: PodcastEpisodeList(
                                        episodes: snapshot.data!,
                                        play: true,
                                        download: true,
                                      ),
                                    )
                                  : const SliverToBoxAdapter(child: NoEpisodesFound());
                            } else {
                              return const SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 120.0,
                                  width: 120.0,
                                ),
                              );
                            }
                          },
                        );
                      }

                      return const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 120.0,
                          width: 120.0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the podcast or episode image.
class PodcastHeaderImage extends StatelessWidget {
  const PodcastHeaderImage({
    super.key,
    required this.podcast,
    required this.placeholderBuilder,
  });

  final Podcast podcast;
  final PlaceholderBuilder? placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (podcast.imageUrl == null || podcast.imageUrl!.isEmpty) {
      return const SizedBox(
        height: 240.0,
        width: 240.0,
      );
    }

    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final imageSize = math.max(176.0, math.min(width - 96.0, 264.0));

    return SizedBox(
      height: imageSize + 44.0,
      width: imageSize + 44.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              width: imageSize + 44.0,
              height: imageSize + 44.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
                    theme.colorScheme.surface.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 36.0,
                  offset: const Offset(0.0, 18.0),
                ),
              ],
            ),
            child: PodcastImage(
              key: Key('details${podcast.imageUrl}'),
              url: podcast.imageUrl!,
              height: imageSize,
              width: imageSize,
              fit: BoxFit.cover,
              borderRadius: 30.0,
              placeholder: placeholderBuilder != null
                  ? SizedBox.square(
                      dimension: imageSize,
                      child: placeholderBuilder?.builder()(context),
                    )
                  : SizedBox.square(
                      dimension: imageSize,
                      child: DelayedCircularProgressIndicator(),
                    ),
              errorPlaceholder: placeholderBuilder != null
                  ? SizedBox.square(
                      dimension: imageSize,
                      child: placeholderBuilder?.errorBuilder()(context),
                    )
                  : SizedBox.square(
                      dimension: imageSize,
                      child: const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the podcast title, about section, and primary actions.
class PodcastTitle extends StatefulWidget {
  final Podcast podcast;
  final PlaceholderBuilder? placeholderBuilder;

  const PodcastTitle({
    required this.podcast,
    this.placeholderBuilder,
    super.key,
  });

  @override
  State<PodcastTitle> createState() => _PodcastTitleState();
}

class _PodcastTitleState extends State<PodcastTitle> {
  final GlobalKey descriptionKey = GlobalKey();
  final maxHeight = 120.0;
  PodcastHtml? description;
  bool showOverflow = false;
  final StreamController<bool> isDescriptionExpandedStream = StreamController<bool>.broadcast();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _subtitle(widget.podcast);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Hero(
              key: Key('detailhero${widget.podcast.imageUrl}:${widget.podcast.link}'),
              tag: '${widget.podcast.imageUrl}:${widget.podcast.link}',
              child: ExcludeSemantics(
                child: PodcastHeaderImage(
                  podcast: widget.podcast,
                  placeholderBuilder: widget.placeholderBuilder,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          const _ShowDetailsChip(label: 'Podcast'),
          const SizedBox(height: 14.0),
          Text(
            widget.podcast.title,
            style: theme.textTheme.headlineLarge?.copyWith(height: 1.02),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8.0),
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FollowButton(widget.podcast),
              IconButton.filledTonal(
                onPressed: () async {
                  await sharePodcast(podcast: widget.podcast);
                },
                tooltip: L.of(context)!.share_podcast_option_label,
                icon: const Icon(Icons.share_outlined),
              ),
              _CircularActionSurface(
                child: PodcastContextMenu(widget.podcast),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: <Widget>[
              if (widget.podcast.episodeCount > 0) _ShowDetailsChip(label: '${widget.podcast.episodeCount} episodes'),
              if (widget.podcast.newEpisodes > 0)
                _ShowDetailsChip(
                  label: L.of(context)!.semantic_new_episodes_count(widget.podcast.newEpisodes),
                ),
            ],
          ),
          const SizedBox(height: 20.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 14.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About the show',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12.0),
                PodcastDescription(
                  key: descriptionKey,
                  content: description,
                  isDescriptionExpandedStream: isDescriptionExpandedStream,
                ),
                if (showOverflow)
                  StreamBuilder<bool>(
                    stream: isDescriptionExpandedStream.stream,
                    initialData: false,
                    builder: (context, snapshot) {
                      final expanded = snapshot.data ?? false;
                      return TextButton.icon(
                        onPressed: () {
                          isDescriptionExpandedStream.add(!expanded);
                        },
                        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                        label: Text(expanded ? 'Show less' : 'Read more'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _setDescription();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = descriptionKey.currentContext?.size?.height ?? 0.0;
      if (height >= maxHeight - 1.0 && mounted) {
        setState(() {
          showOverflow = true;
        });
      }
    });
  }

  void _setDescription() {
    final content = widget.podcast.description?.trim();

    description = PodcastHtml(
      key: ValueKey(widget.podcast.url),
      content: content == null || content.isEmpty ? '<p>No description available.</p>' : content,
      fontSize: FontSize.medium,
      clipboard: false,
    );
  }

  String? _subtitle(Podcast podcast) {
    final hosts = podcast.persons
        ?.map((person) => person.name.trim())
        .where((name) => name.isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (hosts != null && hosts.isNotEmpty) {
      return 'Hosted by ${hosts.join(' & ')}';
    }

    final copyright = podcast.copyright?.trim();

    if (copyright != null && copyright.isNotEmpty) {
      return copyright;
    }

    return null;
  }

  @override
  void dispose() {
    isDescriptionExpandedStream.close();
    description = null;
    super.dispose();
  }
}

class EpisodesSectionHeader extends StatefulWidget {
  final Podcast podcast;

  const EpisodesSectionHeader({
    required this.podcast,
    super.key,
  });

  @override
  State<EpisodesSectionHeader> createState() => _EpisodesSectionHeaderState();
}

class _EpisodesSectionHeaderState extends State<EpisodesSectionHeader> with SingleTickerProviderStateMixin {
  bool showEpisodeSearch = false;
  final _episodeSearchController = TextEditingController();
  final _searchFocus = FocusNode();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsBloc>(context, listen: false).currentSettings;
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Episodes',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Browse the latest releases, filter the feed, or search within this show.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    if (showEpisodeSearch) {
                      _controller.reverse();
                      _searchFocus.unfocus();
                      _episodeSearchController.clear();
                      podcastBloc.podcastSearchEvent('');
                    } else {
                      _controller.forward();
                      _searchFocus.requestFocus();
                    }
                    showEpisodeSearch = !showEpisodeSearch;
                  });
                },
                icon: Icon(showEpisodeSearch ? Icons.close : Icons.search),
                label: Text(L.of(context)!.search_episodes_label),
              ),
              SortButton(widget.podcast),
              FilterButton(widget.podcast),
              if (settings.showFunding)
                _CircularActionSurface(
                  child: FundingMenu(widget.podcast.funding),
                ),
            ],
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextField(
                focusNode: _searchFocus,
                controller: _episodeSearchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      semanticLabel: L.of(context)!.clear_search_button_label,
                    ),
                    onPressed: () {
                      _episodeSearchController.clear();
                      podcastBloc.podcastSearchEvent('');
                    },
                  ),
                  isDense: true,
                  filled: true,
                  hintText: L.of(context)!.search_episodes_label,
                ),
                onChanged: podcastBloc.podcastSearchEvent,
                onSubmitted: podcastBloc.podcastSearchEvent,
                onTapOutside: (event) => _searchFocus.unfocus(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _episodeSearchController.dispose();
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// This class wraps the description in an expandable box.
///
/// This handles the common case whereby the description is very long and, without
/// this constraint, would require the use to always scroll before reaching the
/// podcast episodes.
///
/// TODO: Animate between the two states.
class PodcastDescription extends StatelessWidget {
  final PodcastHtml? content;
  final StreamController<bool>? isDescriptionExpandedStream;
  static const maxHeight = 120.0;
  static const padding = 4.0;

  const PodcastDescription({
    super.key,
    this.content,
    this.isDescriptionExpandedStream,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PodcastDescription.padding),
      child: StreamBuilder<bool>(
        stream: isDescriptionExpandedStream!.stream,
        initialData: false,
        builder: (context, snapshot) {
          final expanded = snapshot.data!;
          return AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: Container(
              constraints: expanded
                  ? const BoxConstraints()
                  : BoxConstraints.loose(const Size(double.infinity, maxHeight - padding)),
              child: expanded
                  ? content
                  : ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.84, 1.0],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: content,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class NoEpisodesFound extends StatelessWidget {
  const NoEpisodesFound({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            L.of(context)!.episode_filter_no_episodes_title_label,
            style: theme.textTheme.titleLarge,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(64.0, 24.0, 64.0, 64.0),
            child: Text(
              L.of(context)!.episode_filter_no_episodes_title_description,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FollowButton extends StatelessWidget {
  final Podcast podcast;

  const FollowButton(this.podcast, {super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0));

    return StreamBuilder<BlocState<Podcast>>(
      stream: bloc.details,
      builder: (context, snapshot) {
        var ready = false;
        var subscribed = false;

        if (snapshot.hasData) {
          final state = snapshot.data;

          if (state is BlocPopulatedState<Podcast>) {
            ready = true;
            subscribed = state.results!.subscribed;
          }
        }

        return Semantics(
          liveRegion: true,
          child: subscribed
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    shape: shape,
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Following'),
                  onPressed: ready
                      ? () {
                          showPlatformDialog<void>(
                            context: context,
                            useRootNavigator: false,
                            builder: (_) => BasicDialogAlert(
                              title: Text(L.of(context)!.unsubscribe_label),
                              content: Text(L.of(context)!.unsubscribe_message),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: ActionText(
                                    L.of(context)!.cancel_button_label,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                BasicDialogAction(
                                  title: ActionText(
                                    L.of(context)!.unsubscribe_button_label,
                                  ),
                                  iosIsDefaultAction: true,
                                  iosIsDestructiveAction: true,
                                  onPressed: () {
                                    bloc.podcastEvent(PodcastEvent.unsubscribe);

                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    shape: shape,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(L.of(context)!.subscribe_label),
                  onPressed: ready
                      ? () {
                          bloc.podcastEvent(PodcastEvent.subscribe);
                        }
                      : null,
                ),
        );
      },
    );
  }
}

class FilterButton extends StatelessWidget {
  final Podcast podcast;

  const FilterButton(this.podcast, {super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
      stream: bloc.details,
      builder: (context, snapshot) {
        Podcast? podcast;

        if (snapshot.hasData) {
          final state = snapshot.data;

          if (state is BlocPopulatedState<Podcast>) {
            podcast = state.results!;
          }
        }

        return EpisodeFilterSelectorWidget(
          podcast: podcast,
        );
      },
    );
  }
}

class SortButton extends StatelessWidget {
  final Podcast podcast;

  const SortButton(this.podcast, {super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
      stream: bloc.details,
      builder: (context, snapshot) {
        Podcast? podcast;

        if (snapshot.hasData) {
          final state = snapshot.data;

          if (state is BlocPopulatedState<Podcast>) {
            podcast = state.results!;
          }
        }

        return EpisodeSortSelectorWidget(
          podcast: podcast,
        );
      },
    );
  }
}

class _ShowDetailsChip extends StatelessWidget {
  final String label;

  const _ShowDetailsChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircularActionSurface extends StatelessWidget {
  final Widget child;

  const _CircularActionSurface({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}
