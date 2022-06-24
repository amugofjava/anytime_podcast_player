// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/ui/podcast/transport_controls.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';

class EpisodeDetails extends StatefulWidget {
  final Episode episode;

  EpisodeDetails({
    Key key,
    this.episode,
  }) : super(key: key);

  @override
  State<EpisodeDetails> createState() => _EpisodeDetailsState();
}

class _EpisodeDetailsState extends State<EpisodeDetails> {
  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;

    /// Ensure we do not highlight this as a new episode
    episode.highlight = false;

    return DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExpansionTile(
                    key: Key('episodemoreinfo'),
                    trailing: PlayControl(
                      episode: episode,
                    ),
                    leading: Stack(
                      alignment: Alignment.bottomLeft,
                      fit: StackFit.passthrough,
                      children: <Widget>[
                        TileImage(
                          url: episode.thumbImageUrl ?? episode.imageUrl,
                          size: 56.0,
                          highlight: episode.highlight,
                        ),
                        SizedBox(
                          height: 5.0,
                          width: 56.0 * (episode.percentagePlayed / 100),
                          child: Container(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    subtitle: EpisodeSubtitle(episode),
                    title: Text(
                      episode.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodyText2,
                    )),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: PodcastHtml(content: episode.description),
                )
              ],
            ),
          );
        });
  }
}
