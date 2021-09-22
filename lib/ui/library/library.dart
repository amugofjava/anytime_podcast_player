// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  @override
  Widget build(BuildContext context) {
    final _podcastBloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<List<Podcast>>(
        stream: _podcastBloc.subscriptions,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.headset,
                        size: 75,
                        color: Theme.of(context).primaryColor,
                      ),
                      Text(
                        L.of(context).no_subscriptions_message,
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SliverList(
                  delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return PodcastTile(podcast: snapshot.data.elementAt(index));
                },
                childCount: snapshot.data.length,
                addAutomaticKeepAlives: false,
              ));
            }
          } else {
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
          }
        });
  }
}
