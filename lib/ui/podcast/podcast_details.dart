// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

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
import 'package:anytime/ui/widgets/decorated_icon_button.dart';
import 'package:anytime/ui/widgets/delayed_progress_indicator.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:anytime/ui/widgets/sync_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

/// This Widget takes a search result and builds a list of currently available
/// podcasts. From here a user can option to subscribe/unsubscribe or play a
/// podcast directly from a search result.
class PodcastDetails extends StatefulWidget {
  final Podcast podcast;
  final PodcastBloc _podcastBloc;

  PodcastDetails(this.podcast, this._podcastBloc);

  @override
  State<PodcastDetails> createState() => _PodcastDetailsState();
}

class _PodcastDetailsState extends State<PodcastDetails> {
  final log = Logger('PodcastDetails');
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _sliverScrollController = ScrollController();
  var brightness = Brightness.dark;
  bool toolbarCollapsed = false;
  SystemUiOverlayStyle _systemOverlayStyle;

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
          scaffoldMessengerKey.currentState.showSnackBar(SnackBar(
            content: Text(L.of(context).new_episodes_label),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: L.of(context).new_episodes_view_now_label,
              onPressed: () {
                _sliverScrollController.animateTo(100, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
                widget._podcastBloc.podcastEvent(PodcastEvent.refresh);
              },
            ),
            duration: Duration(seconds: 5),
          ));
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    _systemOverlayStyle = SystemUiOverlayStyle(
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
      statusBarColor: Theme.of(context).appBarTheme.backgroundColor.withOpacity(toolbarCollapsed ? 1.0 : 0.5),
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
        statusBarColor: Theme.of(context).appBarTheme.backgroundColor.withOpacity(toolbarCollapsed ? 1.0 : 0.5),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return WillPopScope(
      onWillPop: () {
        _resetSystemOverlayStyle();
        return Future.value(true);
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
                        duration: Duration(milliseconds: 500),
                        child: Text(widget.podcast.title)),
                    leading: DecoratedIconButton(
                      icon: Platform.isAndroid ? Icons.close : Icons.arrow_back_ios,
                      iconColour: toolbarCollapsed && Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).appBarTheme.foregroundColor
                          : Colors.white,
                      decorationColour: toolbarCollapsed ? Color(0x00000000) : Color(0x22000000),
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
                                var podcast = widget.podcast;

                                if (state is BlocLoadingState<Podcast>) {
                                  podcast = state.data;
                                }

                                if (state is BlocPopulatedState<Podcast>) {
                                  podcast = state.results;
                                }

                                return PodcastHeaderImage(
                                  podcast: podcast,
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
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
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
                                Icon(
                                  Icons.error_outline,
                                  size: 50,
                                ),
                                Text(
                                  L.of(context).no_podcast_details_message,
                                  style: Theme.of(context).textTheme.bodyText2,
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
                              PodcastTitle(state.results),
                              Divider(),
                            ],
                          ),
                        ));
                      }

                      return SliverToBoxAdapter(
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      );
                    }),
                StreamBuilder<List<Episode>>(
                    stream: podcastBloc.episodes,
                    builder: (context, snapshot) {
                      return snapshot.hasData && snapshot.data.isNotEmpty
                          ? PodcastEpisodeList(
                              episodes: snapshot.data,
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
    );
  }
}

class PodcastHeaderImage extends StatelessWidget {
  const PodcastHeaderImage({
    Key key,
    @required this.podcast,
    @required this.placeholderBuilder,
  }) : super(key: key);

  final Podcast podcast;
  final PlaceholderBuilder placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (podcast == null || podcast.imageUrl == null || podcast.imageUrl.isEmpty) {
      return Container(
        height: 560,
        width: 560,
      );
    }

    return PodcastBannerImage(
      key: Key('details${podcast.imageUrl}'),
      url: podcast.imageUrl,
      fit: BoxFit.cover,
      placeholder:
          placeholderBuilder != null ? placeholderBuilder?.builder()(context) : DelayedCircularProgressIndicator(),
      errorPlaceholder: placeholderBuilder != null
          ? placeholderBuilder?.errorBuilder()(context)
          : Image(image: AssetImage('assets/images/anytime-placeholder-logo.png')),
    );
  }
}

class PodcastTitle extends StatefulWidget {
  final Podcast podcast;

  PodcastTitle(this.podcast);

  @override
  State<PodcastTitle> createState() => _PodcastTitleState();
}

class _PodcastTitleState extends State<PodcastTitle> {
  final GlobalKey descriptionKey = GlobalKey();
  final maxHeight = 100.0;
  PodcastHtml description;
  bool showOverflow = false;
  final StreamController<bool> isDescriptionExpandedStream = StreamController<bool>.broadcast();

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 2.0),
                      child: Text(widget.podcast.title ?? '', style: textTheme.headline6),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(widget.podcast.copyright ?? '', style: textTheme.caption),
                    ),
                  ],
                ),
              ),
              StreamBuilder<bool>(
                stream: isDescriptionExpandedStream.stream,
                initialData: false,
                builder: (context, snapshot) {
                  final expanded = snapshot.data;
                  return Visibility(
                    visible: showOverflow,
                    child: expanded
                        ? TextButton(
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Icon(Icons.expand_less),
                            onPressed: () {
                              isDescriptionExpandedStream.add(false);
                            },
                          )
                        : TextButton(
                            style: ButtonStyle(visualDensity: VisualDensity.compact),
                            child: Icon(Icons.expand_more),
                            onPressed: () {
                              isDescriptionExpandedStream.add(true);
                            },
                          ),
                  );
                }
              )
            ],
          ),
          PodcastDescription(
            key: descriptionKey,
            content: description,
            isDescriptionExpandedStream: isDescriptionExpandedStream,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SubscriptionButton(widget.podcast),
                PodcastContextMenu(widget.podcast),
                settings.showFunding
                    ? FundingMenu(widget.podcast.funding)
                    : const SizedBox(
                        width: 0.0,
                        height: 0.0,
                      ),
                Expanded(
                    child: Align(
                  alignment: Alignment.centerRight,
                  child: const SyncSpinner(),
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
      content: widget.podcast.description,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (descriptionKey.currentContext.size.height == maxHeight) {
        setState(() {
          showOverflow = true;
        });
      }
    });
  }
}

/// This class wraps the description in an expandable box. This handles the
/// common case whereby the description is very long and, without this constraint,
/// would require the use to always scroll before reaching the podcast episodes.
///
/// TODO: Animate between the two states.
class PodcastDescription extends StatelessWidget {
  final PodcastHtml content;
  final StreamController<bool> isDescriptionExpandedStream;
  static const maxHeight = 100.0;
  static const padding = 4.0;

  const PodcastDescription({
    Key key,
    this.content,
    this.isDescriptionExpandedStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PodcastDescription.padding),
      child:  StreamBuilder<bool>(
        stream: isDescriptionExpandedStream.stream,
        initialData: false,
        builder: (context, snapshot) {
          return AnimatedSize(
                  duration: Duration(milliseconds : 150),
                  curve: Curves.fastOutSlowIn,
                  // size: snapshot.data ? null : maxHeight- padding,
                  child: Container( 
                  constraints: snapshot.data ? BoxConstraints() :  BoxConstraints.loose(Size(double.infinity, maxHeight - padding)),
                    child: ShaderMask(
                      shaderCallback: LinearGradient(
                        colors: [Colors.white, Colors.white.withAlpha(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.9, 1],
                      ).createShader,
                      child: content),
                ),);
        }
      ),
    );
  }
}

class SubscriptionButton extends StatelessWidget {
  final Podcast podcast;

  SubscriptionButton(this.podcast);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is BlocPopulatedState<Podcast>) {
              var p = state.results;

              return p.subscribed
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      icon: Icon(
                        Icons.delete_outline,
                      ),
                      label: Text(L.of(context).unsubscribe_label),
                      onPressed: () {
                        showPlatformDialog<void>(
                          context: context,
                          useRootNavigator: false,
                          builder: (_) => BasicDialogAlert(
                            title: Text(L.of(context).unsubscribe_label),
                            content: Text(L.of(context).unsubscribe_message),
                            actions: <Widget>[
                              BasicDialogAction(
                                title: ActionText(
                                  L.of(context).cancel_button_label,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              BasicDialogAction(
                                title: ActionText(
                                  L.of(context).unsubscribe_button_label,
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
                      icon: Icon(
                        Icons.add,
                      ),
                      label: Text(L.of(context).subscribe_label),
                      onPressed: () {
                        bloc.podcastEvent(PodcastEvent.subscribe);
                      },
                    );
            }
          }
          return Container();
        });
  }
}
