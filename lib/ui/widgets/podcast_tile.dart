// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/core/chrome.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class PodcastTile extends StatelessWidget {
  final Podcast podcast;

  const PodcastTile({
    @required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    final _podcastBloc = Provider.of<PodcastBloc>(context);
    final _theme = Theme.of(context);
    final darkMode = _theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ListTile(
            onTap: () {
              if (darkMode) {
                Chrome.translucentDark();
              } else {
                Chrome.translucentLight();
              }

              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => PodcastDetails(podcast, _podcastBloc, darkMode)),
              );
            },
            leading: Hero(
              tag: '${podcast.imageUrl}:${podcast.link}',
              child: TileImage(
                url: podcast.thumbImageUrl,
                size: 60,
              ),
            ),
            title: Text(
              podcast.title,
              maxLines: 1,
            ),
            subtitle: Text(
              podcast.copyright ?? '',
              maxLines: 2,
            ),
            isThreeLine: false,
          ),
        ],
      ),
    );
  }
}
