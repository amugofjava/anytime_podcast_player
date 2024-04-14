// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
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
import 'package:anytime/ui/widgets/sync_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  var brightness = Brightness.dark;
  bool toolbarCollapsed = false;
  SystemUiOverlayStyle? _systemOverlayStyle;

  @override
  void initState() {
    super.initState();

    // Load the details of the Podcast specified in the URL
    log.fine('initState() - load feed');

    widget._podcastBloc.load(Feed(
      podcast: widget.podcast,
      backgroundFresh: true,
      silently: true,
    ));

    // We only want to display the podcast title when the toolbar is in a
    // collapsed state. Add a listener and set toollbarCollapsed variable
    // as required. The text display property is then based on this boolean.
    _sliverScrollController.addListener(() {
      if (!toolbarCollapsed &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset > (300 - kToolbarHeight)) {
        setState(() {
          toolbarCollapsed = true;
          _updateSystemOverlayStyle();
        });
      } else if (toolbarCollapsed &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset < (300 - kToolbarHeight)) {
        setState(() {
          toolbarCollapsed = false;
          _updateSystemOverlayStyle();
        });
      }
    });

    widget._podcastBloc.backgroundLoading.where((event) => event is BlocPopulatedState<void>).listen((event) {
      if (mounted) {
        /// If we have not scrolled (save a few pixels) just refresh the episode list;
        /// otherwise prompt the user to prevent unexpected list jumping
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
  void didChangeDependencies() {
    _systemOverlayStyle = SystemUiOverlayStyle(
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
      statusBarColor: Theme.of(context).appBarTheme.backgroundColor!.withOpacity(toolbarCollapsed ? 1.0 : 0.5),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    log.fine('_handleRefresh');

    widget._podcastBloc.load(Feed(
      podcast: widget.podcast,
      refresh: true,
    ));
  }

  void _resetSystemOverlayStyle() {
    setState(() {
      _systemOverlayStyle = SystemUiOverlayStyle(
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent,
      );
    });
  }

  void _updateSystemOverlayStyle() {
    setState(() {
      _systemOverlayStyle = SystemUiOverlayStyle(
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarColor: Theme.of(context).appBarTheme.backgroundColor!.withOpacity(toolbarCollapsed ? 1.0 : 0.5),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return Semantics(
      header: false,
      label: L.of(context)!.semantics_podcast_details_header,
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          _resetSystemOverlayStyle();
        },
        child: ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              displacement: 60.0,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _sliverScrollController,
                slivers: <Widget>[
                  SliverAppBar(
                      systemOverlayStyle: _systemOverlayStyle,
                      title: AnimatedOpacity(
                          opacity: toolbarCollapsed ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(widget.podcast.title)),
                      leading: PlatformBackButton(
                        iconColour: toolbarCollapsed && Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).appBarTheme.foregroundColor!
                            : Colors.white,
                        decorationColour: toolbarCollapsed ? const Color(0x00000000) : const Color(0x22000000),
                        onPressed: () {
                          _resetSystemOverlayStyle();
                          Navigator.pop(context);
                        },
                      ),
                      expandedHeight: 300.0,
                      floating: false,
                      pinned: true,
                      snap: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Hero(
                          key: Key('detailhero${widget.podcast.imageUrl}:${widget.podcast.link}'),
                          tag: '${widget.podcast.imageUrl}:${widget.podcast.link}',
                          child: ExcludeSemantics(
                            child: StreamBuilder<BlocState<Podcast>>(
                                initialData: BlocEmptyState<Podcast>(),
                                stream: podcastBloc.details,
                                builder: (context, snapshot) {
                                  final state = snapshot.data;
                                  Podcast? podcast = widget.podcast;

                                  if (state is BlocLoadingState<Podcast>) {
                                    podcast = state.data;
                                  }

                                  if (state is BlocPopulatedState<Podcast>) {
                                    podcast = state.results;
                                  }

                                  return PodcastHeaderImage(
                                    podcast: podcast!,
                                    placeholderBuilder: placeholderBuilder,
                                  );
                                }),
                          ),
                        ),
                      )),
                  StreamBuilder<BlocState<Podcast>>(
                      initialData: BlocEmptyState<Podcast>(),
                      stream: podcastBloc.details,
                      builder: (context, snapshot) {
                        final state = snapshot.data;

                        if (state is BlocLoadingState) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                children: <Widget>[
                                  PlatformProgressIndicator(),
                                ],
                              ),
                            ),
                          );
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
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is BlocPopulatedState<Podcast>) {
                          return SliverToBoxAdapter(
                              child: PlaybackErrorListener(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                PodcastTitle(state.results!),
                                const Divider(),
                                NoEpisodesFound(state.results!),
                              ],
                            ),
                          ));
                        }

                        return const SliverToBoxAdapter(
                          child: SizedBox(
                            width: 0.0,
                            height: 0.0,
                          ),
                        );
                      }),
                  StreamBuilder<List<Episode?>?>(
                      stream: podcastBloc.episodes,
                      builder: (context, snapshot) {
                        return snapshot.hasData && snapshot.data!.isNotEmpty
                            ? PodcastEpisodeList(
                                episodes: snapshot.data!,
                                play: true,
                                download: true,
                              )
                            : SliverToBoxAdapter(child: Container());
                      }),
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
        height: 560,
        width: 560,
      );
    }

    return PodcastBannerImage(
      key: Key('details${podcast.imageUrl}'),
      url: podcast.imageUrl!,
      fit: BoxFit.cover,
      placeholder:
          placeholderBuilder != null ? placeholderBuilder?.builder()(context) : DelayedCircularProgressIndicator(),
      errorPlaceholder: placeholderBuilder != null
          ? placeholderBuilder?.errorBuilder()(context)
          : const Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
    );
  }
}

/// Renders the podcast title, copyright, description, follow/unfollow and
/// overflow button.
///
/// If the episode description is fairly long, an overflow icon is also shown
/// and a portion of the episode description is shown. Tapping the overflow
/// icons allows the user to expand and collapse the text.
///
/// Description is rendered by [PodcastDescription].
/// Follow/Unfollow button rendered by [FollowButton].
class PodcastTitle extends StatefulWidget {
  final Podcast podcast;

  const PodcastTitle(this.podcast, {super.key});

  @override
  State<PodcastTitle> createState() => _PodcastTitleState();
}

class _PodcastTitleState extends State<PodcastTitle> {
  final GlobalKey descriptionKey = GlobalKey();
  final _maxCollapsedHeight = 100.0;
  PodcastHtml? description;
  bool showOverflow = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final settings = Provider.of<SettingsBloc>(context).currentSettings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 2.0),
                        child: Text(widget.podcast.title, style: textTheme.titleLarge),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Text(widget.podcast.copyright ?? '', style: textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          PodcastDescription(
            key: descriptionKey,
            content: description,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                FollowButton(widget.podcast),
                PodcastContextMenu(widget.podcast),
                SortButton(widget.podcast),
                FilterButton(widget.podcast),
                settings.showFunding
                    ? FundingMenu(widget.podcast.funding)
                    : const SizedBox(
                        width: 0.0,
                        height: 0.0,
                      ),
                const Expanded(
                    child: Align(
                  alignment: Alignment.centerRight,
                  child: SyncSpinner(),
                )),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    description = PodcastHtml(
      content: widget.podcast.description!,
      fontSize: FontSize.medium,
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (descriptionKey.currentContext!.size!.height == _maxCollapsedHeight) {
        setState(() {
          showOverflow = true;
        });
      }
    });
  }
}

/// This class wraps the description in an expandable box.
///
/// This handles the common case whereby the description is very long and, without
/// this constraint, would require the use to always scroll before reaching the
/// podcast episodes.
class PodcastDescription extends StatefulWidget {
  final PodcastHtml? content;

  const PodcastDescription({
    super.key,
    this.content,
  });

  @override
  State<PodcastDescription> createState() => _PodcastDescriptionState();
}

class _PodcastDescriptionState extends State<PodcastDescription> {
  static const padding = 8.0;

  final GlobalKey _key = GlobalKey();

  static const _maxCollapsedHeight = 100.0;
  double _uncollapsedHeight = 0;
  double _collapsedHeight = 0;
  bool _isExpanded = false;

  // initial load without animation
  Duration _animationDuration = const Duration(milliseconds: 0);

  @override
  void initState() {
    super.initState();

    // determine the height of the content, runs after rendering
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      double? height = _key.currentContext?.size?.height;
      // collapsed height will remain at 0
      if (height == null) return;

      setState(() {
        // true height of the content
        _uncollapsedHeight = height.toDouble();

        // collapsed height
        _collapsedHeight = min(height, _maxCollapsedHeight);
      });

      // wait for initial render to complete before animating
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() {
        _animationDuration = const Duration(milliseconds: 300);
      });
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.fastOutSlowIn,
          height: _isExpanded ? _uncollapsedHeight : _collapsedHeight,
          child: ShaderMask(
            shaderCallback: (Rect bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withAlpha(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // "show more" gradient only visible when the description was cut off
              stops: _isExpanded || _uncollapsedHeight == _collapsedHeight
                  ? [1.0, 1.0]
                  : [0.7, 1.0],
            ).createShader(bounds),
            child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                // toggle if the user hasn't tapped on url
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleExpanded,
                  child: Container(key: _key, child: widget.content),
                )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: padding, bottom: 10),
          child: MergeSemantics(
            child: InkWell(
              onTap: _toggleExpanded,
              child: _uncollapsedHeight == _collapsedHeight
                  ? Container()
                  : Text(
                      _isExpanded
                          ? L.of(context)!.show_less_podcast_description_label
                          : L.of(context)!.show_more_podcast_description_label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class NoEpisodesFound extends StatelessWidget {
  final Podcast podcast;

  const NoEpisodesFound(this.podcast, {super.key});

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context);

    if (podcast.episodes.isEmpty) {
      if (podcast.filter == PodcastEpisodeFilter.none) {
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                L.of(context)!.episode_filter_no_episodes_title_label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        );
      } else {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                L.of(context)!.episode_filter_no_episodes_title_label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Text(
                  L.of(context)!.episode_filter_no_episodes_title_description,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  podcastBloc.podcastEvent(PodcastEvent.episodeFilterNone);
                },
                child: Text(
                  L.of(context)!.episode_filter_clear_filters_button_label,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      return const SizedBox(
        height: 0,
        width: 0,
      );
    }
  }
}

class FollowButton extends StatelessWidget {
  final Podcast podcast;

  const FollowButton(this.podcast, {super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is BlocPopulatedState<Podcast>) {
              var p = state.results!;

              return Semantics(
                liveRegion: true,
                child: p.subscribed
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: Text(L.of(context)!.unsubscribe_label),
                        onPressed: () {
                          showPlatformDialog<void>(
                            context: context,
                            useRootNavigator: false,
                            builder: (_) => BasicDialogAlert(
                              title: Text(L.of(context)!.unsubscribe_label),
                              content: Text(L.of(context)!.unsubscribe_message),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: ExcludeSemantics(
                                    child: ActionText(
                                      L.of(context)!.cancel_button_label,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                BasicDialogAction(
                                  title: ExcludeSemantics(
                                    child: ActionText(
                                      L.of(context)!.unsubscribe_button_label,
                                    ),
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
                        },
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        icon: const Icon(
                          Icons.add,
                        ),
                        label: Text(L.of(context)!.subscribe_label),
                        onPressed: () {
                          bloc.podcastEvent(PodcastEvent.subscribe);
                        },
                      ),
              );
            }
          }
          return Container();
        });
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
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is BlocPopulatedState<Podcast>) {
              var p = state.results!;

              return EpisodeFilterSelectorWidget(
                podcast: p,
              );
            }
          }
          return Container();
        });
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
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is BlocPopulatedState<Podcast>) {
              var p = state.results!;

              return EpisodeSortSelectorWidget(
                podcast: p,
              );
            }
          }
          return Container();
        });
  }
}
