// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/core/chrome.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/podcast/funding_menu.dart';
import 'package:anytime/ui/podcast/podcast_context_menu.dart';
import 'package:anytime/ui/widgets/decorated_icon_button.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:logging/logging.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// This Widget takes a search result and builds a list of currently available
/// podcasts. From here a user can option to subscribe/unsubscribe or play a
/// podcast directly from a search result.
class PodcastDetails extends StatefulWidget {
  final Podcast podcast;
  final PodcastBloc _podcastBloc;
  final bool _darkMode;

  PodcastDetails(this.podcast, this._podcastBloc, this._darkMode);

  @override
  _PodcastDetailsState createState() => _PodcastDetailsState();
}

class _PodcastDetailsState extends State<PodcastDetails> {
  final log = Logger('PodcastDetails');
  final ScrollController _sliverScrollController = ScrollController();
  var brightness = Brightness.dark;

  bool toolbarCollpased = false;

  @override
  void initState() {
    super.initState();

    // Load the details of the Podcast specified in the URL
    log.fine('initState() - load feed');
    widget._podcastBloc.load(Feed(podcast: widget.podcast));
    brightness = widget._darkMode ? Brightness.dark : Brightness.light;

    // We only want to display the podcast title when the toolbar is in a
    // collapsed state. Add a listener and set toollbarCollapsed variable
    // as required. The text display property is then based on this boolean.
    _sliverScrollController.addListener(() {
      if (!toolbarCollpased &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset > (300 - kToolbarHeight)) {
        setState(() {
          if (widget._darkMode) {
            Chrome.transparentDark();
            brightness = Brightness.light;
          } else {
            Chrome.transparentLight();
            brightness = Brightness.light;
          }

          toolbarCollpased = true;
        });
      } else if (toolbarCollpased &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset < (300 - kToolbarHeight)) {
        setState(() {
          if (widget._darkMode) {
            Chrome.translucentDark();
            brightness = Brightness.light;
          } else {
            Chrome.translucentLight();
            brightness = Brightness.dark;
          }

          toolbarCollpased = false;
        });
      }
    });
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

  void _setChrome({bool darkMode}) {
    if (darkMode) {
      Chrome.transparentDark();
    } else {
      Chrome.transparentLight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColour = Theme.of(context).backgroundColor;
    final defaultBrightness = Theme.of(context).brightness;
    final _podcastBloc = Provider.of<PodcastBloc>(context);

    brightness = toolbarCollpased ? defaultBrightness : Brightness.dark;

    return WillPopScope(
      onWillPop: () {
        _setChrome(darkMode: widget._darkMode);

        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColour,
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          showChildOpacityTransition: false,
          child: CustomScrollView(
            controller: _sliverScrollController,
            slivers: <Widget>[
              SliverAppBar(
                brightness: brightness,
                title: AnimatedOpacity(
                  opacity: toolbarCollpased ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Text(widget.podcast.title),
                ),
                leading: DecoratedIconButton(
                  icon: Icons.close,
                  iconColour: toolbarCollpased && defaultBrightness == Brightness.light ? Colors.black : Colors.white,
                  decorationColour: toolbarCollpased ? Color(0x00000000) : Color(0x22000000),
                  onPressed: () {
                    setState(() {
                      // We need to switch brightness to light here. If we do not,
                      // it will stay dark until the previous screen is rebuilt and
                      // that results in the status bar being blank for a few
                      // milliseconds which looks very odd.
                      brightness = widget._darkMode ? Brightness.dark : Brightness.light;
                    });

                    _setChrome(darkMode: widget._darkMode);

                    Navigator.pop(context);
                  },
                ),
                backgroundColor: Theme.of(context).appBarTheme.color,
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                snap: false,
                flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                  tag: '${widget.podcast.imageUrl}:${widget.podcast.link}',
                  child: ExcludeSemantics(
                    child: OptimizedCacheImage(
                      imageUrl: widget.podcast.imageUrl,
                      fit: BoxFit.fitWidth,
                      placeholder: (context, url) {
                        return Placeholder(
                          color: Colors.grey,
                          strokeWidth: 1,
                        );
                      },
                      errorWidget: (_, __, dynamic ___) {
                        return Placeholder(
                          color: Colors.grey,
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                )),
              ),
              StreamBuilder<BlocState<Podcast>>(
                  initialData: BlocEmptyState<Podcast>(),
                  stream: _podcastBloc.details,
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
                                color: Theme.of(context).buttonColor,
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
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          PodcastTitle(state.results),
                          Divider(),
                        ],
                      ));
                    }

                    return SliverToBoxAdapter(
                      child: Container(),
                    );
                  }),
              StreamBuilder<List<Episode>>(
                  stream: _podcastBloc.episodes,
                  builder: (context, snapshot) {
                    return snapshot.hasData
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return EpisodeTile(
                                episode: snapshot.data[index],
                                download: true,
                                play: true,
                              );
                            },
                            childCount: snapshot.data.length,
                            addAutomaticKeepAlives: false,
                          ))
                        : SliverToBoxAdapter(child: Container());
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class PodcastTitle extends StatelessWidget {
  final Podcast podcast;

  PodcastTitle(this.podcast);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(podcast.title ?? '', style: textTheme.headline6),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(podcast.copyright ?? '', style: textTheme.caption),
          ),
          Html(
            data: podcast.description ?? '',
            style: {'html': Style(fontWeight: textTheme.bodyText1.fontWeight)},
            onLinkTap: (url) => canLaunch(url).then((value) => launch(url)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SubscriptionButton(podcast),
                PodcastContextMenu(podcast),
                FundingMenu(podcast.funding),
              ],
            ),
          )
        ],
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
                  ? OutlineButton.icon(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).buttonColor,
                      ),
                      label: Text(L.of(context).unsubscribe_label),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      onPressed: () {
                        showPlatformDialog<void>(
                          context: context,
                          builder: (_) => BasicDialogAlert(
                            title: Text(L.of(context).unsubscribe_label),
                            content: Text(L.of(context).unsubscribe_message),
                            actions: <Widget>[
                              BasicDialogAction(
                                title: Text(
                                  L.of(context).cancel_button_label,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              BasicDialogAction(
                                title: Text(L.of(context).unsubscribe_button_label),
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
                  : OutlineButton.icon(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).buttonColor,
                      ),
                      label: Text(L.of(context).subscribe_label),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
