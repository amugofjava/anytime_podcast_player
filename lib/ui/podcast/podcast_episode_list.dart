// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastEpisodeList extends StatelessWidget {
  final List<Episode?>? episodes;
  final IconData icon;
  final String emptyMessage;
  final bool play;
  final bool download;

  static const _defaultIcon = Icons.add_alert;

  const PodcastEpisodeList({
    super.key,
    required this.episodes,
    required this.play,
    required this.download,
    this.icon = _defaultIcon,
    this.emptyMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (episodes != null && episodes!.isNotEmpty) {
      var queueBloc = Provider.of<QueueBloc>(context);

      return StreamBuilder<QueueState>(
          stream: queueBloc.queue,
          builder: (context, snapshot) {
            return AccessibleSliverList(
              episode: episodes![0]!,
              itemBuilder: (BuildContext context, int index) {
                var queued = false;
                var playing = false;
                var episode = episodes![index]!;

                if (snapshot.hasData) {
                  var playingGuid = snapshot.data!.playing?.guid;

                  queued = snapshot.data!.queue.any((element) => element.guid == episode.guid);

                  playing = playingGuid == episode.guid;
                }

                return EpisodeTile(
                  episode: episode,
                  download: download,
                  play: play,
                  playing: playing,
                  queued: queued,
                );
              },
              itemCount: episodes!.length,
            );
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
                icon,
                size: 75,
                color: theme.primaryColor,
              ),
              Text(
                emptyMessage,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// This class is a wrapper around two sliver list implementations. If the user has a screen reader enabled, we
/// return a [SliverPrototypeExtentList.builder]. This version can take advantage of using a prototype tile to
/// calculate the item extend for all episodes. It also fixes a scrolling issue when user VoiceOver on iOS. If
/// the user is not using a screen reader, we return a standard [SliverList] and let it calculate the item extent
/// for each episode tile. This ensures that the item details slide action still works correctly (with a fixed
/// extent the contents would render above the tile below it).
class AccessibleSliverList extends StatelessWidget {
  /// The episode used to calculate the item extent when using a screen reader.
  final Episode episode;

  /// The builder used to build each episode tile.
  final NullableIndexedWidgetBuilder itemBuilder;

  /// The number of episodes in our list
  final int itemCount;

  const AccessibleSliverList({
    super.key,
    required this.episode,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final accessibleNavigation = MediaQuery.accessibleNavigationOf(context);

    return accessibleNavigation
        ? SliverPrototypeExtentList.builder(
            prototypeItem: EpisodeTile(
              episode: episode,
              download: true,
              play: true,
              playing: false,
              queued: false,
            ),
            addAutomaticKeepAlives: false,
            itemBuilder: itemBuilder,
            itemCount: itemCount,
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              addAutomaticKeepAlives: false,
            ),
          );
  }
}
