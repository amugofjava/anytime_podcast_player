// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
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

    // We only want to display the podcast title when the toolbar is in a
    // collapsed state. Add a listener and set toollbarCollapsed variable
    // as required. The text display property is then based on this boolean.
    _sliverScrollController.addListener(() {
      if (!toolbarCollpased && _sliverScrollController.hasClients && _sliverScrollController.offset > (300 - kToolbarHeight)) {
        setState(() {
          brightness = Brightness.light;
          toolbarCollpased = true;
        });
      } else if (toolbarCollpased &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset < (300 - kToolbarHeight)) {
        setState(() {
          brightness = Brightness.dark;
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

  @override
  Widget build(BuildContext context) {
    final _podcastBloc = Provider.of<PodcastBloc>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        showChildOpacityTransition: false,
        child: CustomScrollView(
          controller: _sliverScrollController,
          slivers: <Widget>[
            SliverAppBar(
              brightness: brightness,
              title: toolbarCollpased
                  ? Text(widget.podcast.title, style: (TextStyle(color: Colors.black)))
                  : Text(
                      '',
                    ),
              leading: IconButton(
                color: toolbarCollpased ? Colors.black : Colors.white,
                tooltip: L.of(context).close_button_label,
                icon: Icon(
                  Icons.close,
                ),
                onPressed: () {
                  setState(() {
                    // We need to switch brightness to light here. If we do not,
                    // it will stay dark until the previous screen is rebuilt and
                    // that results in the status bar being blank for a a few
                    // milliseconds which looks very odd.
                    brightness = Brightness.light;
                  });

                  Navigator.pop(context);
                },
              ),
              backgroundColor: Colors.white,
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              snap: false,
              flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                tag: '${widget.podcast.imageUrl}:${widget.podcast.link}',
                child: ExcludeSemantics(
                  child: CachedNetworkImage(
                    imageUrl: widget.podcast.imageUrl,
                    fit: BoxFit.fitWidth,
                    placeholder: (context, url) {
                      return Container(
                        constraints: BoxConstraints.expand(height: 60, width: 60),
                        child: Placeholder(
                          color: Colors.grey,
                          strokeWidth: 1,
                          fallbackWidth: 60,
                          fallbackHeight: 60,
                        ),
                      );
                    },
                    errorWidget: (_, __, dynamic ___) {
                      return Container(
                        constraints: BoxConstraints.expand(height: 60, width: 60),
                        child: Placeholder(
                          color: Colors.grey,
                          strokeWidth: 1,
                          fallbackWidth: 60,
                          fallbackHeight: 60,
                        ),
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
                            CircularProgressIndicator(),
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
                              color: Colors.blue[900],
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
                    return SliverToBoxAdapter(child: buildPage(context, state.results));
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
                          delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                          return EpisodeTile(
                            episode: snapshot.data[index],
                            download: true,
                            play: true,
                          );
                        }, childCount: snapshot.data.length))
                      : SliverToBoxAdapter(child: Container());
                }),
          ],
        ),
      ),
    );
  }

  Widget buildPage(BuildContext context, Podcast podcast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PodcastTitle(podcast),
        Divider(),
      ],
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
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(podcast.title ?? '', style: textTheme.headline6),
          Padding(
            padding: EdgeInsets.only(top: 4.0),
          ),
          Text(podcast.copyright ?? '', style: textTheme.caption),
          Padding(
            padding: EdgeInsets.only(top: 16.0),
          ),
          Text(podcast.description ?? '', style: textTheme.bodyText1),
          Padding(
            padding: EdgeInsets.only(top: 16.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SubscriptionButton(podcast),
              EpisodeFilterButton(podcast),
            ],
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
                        color: Colors.orange,
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
                                  style: TextStyle(color: Colors.orange),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              BasicDialogAction(
                                title: Text(L.of(context).unsubscribe_button_label, style: TextStyle(color: Colors.orange)),
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
                        color: Colors.orange,
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

class EpisodeFilterButton extends StatelessWidget {
  final Podcast podcast;

  EpisodeFilterButton(this.podcast);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          return PopupMenuButton<String>(
            onSelected: (event) {
              togglePlayed(value: event, bloc: bloc);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'ma',
                  enabled: podcast.subscribed,
                  child: Text(L.of(context).mark_episodes_played_label),
                ),
                PopupMenuItem<String>(
                  value: 'ua',
                  enabled: podcast.subscribed,
                  child: Text(L.of(context).mark_episodes_not_played_label),
                ),
              ];
            },
          );
        });
  }

  void togglePlayed({
    @required String value,
    @required PodcastBloc bloc,
  }) {
    if (value == 'ma') {
      bloc.podcastEvent(PodcastEvent.markAllPlayed);
    } else if (value == 'ua') {
      bloc.podcastEvent(PodcastEvent.clearAllPlayed);
    }
  }
}
