// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggableEpisodeTile extends StatelessWidget {
  final Episode episode;
  final int index;
  final bool draggable;

  const DraggableEpisodeTile({
    Key key,
    @required this.episode,
    this.index,
    this.draggable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    return ListTile(
      key: Key('DT${episode.guid}'),
      leading: TileImage(
        url: episode.thumbImageUrl ?? episode.imageUrl,
        size: 56.0,
        highlight: episode.highlight,
      ),
      title: Text(
        episode.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        softWrap: false,
        style: textTheme.bodyText2,
      ),
      subtitle: EpisodeSubtitle(episode),
      trailing: draggable
          ? ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle),
            )
          : SizedBox(
              width: 0.0,
              height: 0.0,
            ),
      onTap: () {
        audioBloc.play(episode);
      },
    );
  }
}
