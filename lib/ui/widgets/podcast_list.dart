// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/podcast_tile.dart';
import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart' as search;

class PodcastList extends StatelessWidget {
  const PodcastList({
    Key key,
    @required this.results,
  }) : super(key: key);

  final search.SearchResult results;

  @override
  Widget build(BuildContext context) {
    if (results.items.isNotEmpty) {
      return SliverList(
          delegate: SliverChildListDelegate([
        ListView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.all(0.0),
          itemCount: results.items.length,
          itemBuilder: (BuildContext context, int index) {
            final i = results.items[index];
            final p = Podcast.fromSearchResultItem(i);

            return PodcastTile(podcast: p);
          },
        )
      ]));
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
                Icons.search,
                size: 75,
                color: Colors.blue[900],
              ),
              Text(
                L.of(context).no_search_results_message,
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
