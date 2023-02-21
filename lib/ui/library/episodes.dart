// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/podcast_episode_list.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Place holder for the upcoming Episodes view. This is essentially a copy of the Downloads
/// page for now, but will be updated to include filters and will, eventually, support both
/// the episode & download views.
class Episodes extends StatefulWidget {
  @override
  State<Episodes> createState() => _EpisodesState();
}

/// Displays a list of podcast episodes that the user has downloaded.
class _EpisodesState extends State<Episodes> {
  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<EpisodeBloc>(context, listen: false);

    bloc.fetchEpisodes(false);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<EpisodeBloc>(context);

    return StreamBuilder<BlocState>(
      stream: bloc.episodes,
      builder: (BuildContext context, AsyncSnapshot<BlocState> snapshot) {
        final state = snapshot.data;

        if (state is BlocPopulatedState) {
          return PodcastEpisodeList(
            episodes: state.results as List<Episode>,
            play: true,
            download: true,
            icon: Icons.cloud_download,
            emptyMessage: L.of(context).no_downloads_message,
          );
        } else {
          if (state is BlocLoadingState) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  PlatformProgressIndicator(),
                ],
              ),
            );
          } else if (state is BlocErrorState) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Text('ERROR'),
            );
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: Container(),
          );
        }
      },
    );
  }

  ///TODO: Refactor out into a separate Widget class
  Widget buildResults(BuildContext context, List<Episode> episodes) {
    if (episodes.isNotEmpty) {
      var queueBloc = Provider.of<QueueBloc>(context);

      return StreamBuilder<QueueState>(
          stream: queueBloc.queue,
          builder: (context, snapshot) {
            return SliverList(
                delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var queued = false;
                var episode = episodes[index];

                if (snapshot.hasData) {
                  queued = snapshot.data.queue.any((element) => element.guid == episode.guid);
                }

                return EpisodeTile(
                  episode: episode,
                  download: false,
                  play: true,
                  queued: queued,
                );
              },
              childCount: episodes.length,
              addAutomaticKeepAlives: false,
            ));
          });
    } else {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.cloud_download,
                size: 75,
                color: Theme.of(context).primaryColor,
              ),
              Text(
                L.of(context).no_downloads_message,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
