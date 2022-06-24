// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastGridTile extends StatelessWidget {
  final Podcast podcast;

  const PodcastGridTile({
    @required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
              settings: RouteSettings(name: 'podcastdetails'),
              builder: (context) => PodcastDetails(podcast, podcastBloc)),
        );
      },
      child: GridTile(
        child: Hero(
          key: Key('tilehero${podcast.imageUrl}:${podcast.link}'),
          tag: '${podcast.imageUrl}:${podcast.link}',
          child: TileImage(
            url: podcast.imageUrl,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

class PodcastTitledGridTile extends StatelessWidget {
  final Podcast podcast;

  const PodcastTitledGridTile({
    @required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
              settings: RouteSettings(name: 'podcastdetails'),
              builder: (context) => PodcastDetails(podcast, podcastBloc)),
        );
      },
      child: GridTile(
        child: Hero(
          key: Key('tilehero${podcast.imageUrl}:${podcast.link}'),
          tag: '${podcast.imageUrl}:${podcast.link}',
          child: Column(
            children: [
              TileImage(
                url: podcast.imageUrl,
                size: 128.0,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 4.0,
                ),
                child: Text(
                  podcast.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
