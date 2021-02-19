// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';

/// This class displays the show notes for the selected podcast. We make use of [Html]
/// to render the notes and, if in HTML format, display the correct formatting, links etc.
class ShowNotes extends StatelessWidget {
  final ScrollController _sliverScrollController = ScrollController();
  final Episode episode;

  ShowNotes({
    @required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: CustomScrollView(controller: _sliverScrollController, slivers: <Widget>[
          SliverAppBar(
            brightness: Theme.of(context).brightness,
            title: Text(episode.podcast),
            backgroundColor: Theme.of(context).appBarTheme.color,
            floating: false,
            pinned: true,
            snap: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(episode.title ?? '', style: textTheme.headline6),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                  child: Html(
                    data: episode.description,
                    style: {
                      'html': Style(
                        fontSize: FontSize.large,
                      ),
                    },
                    onLinkTap: (url) {
                      canLaunch(url).then((value) => launch(url));
                    },
                  ),
                ),
              ],
            ),
          ),
        ]));
  }
}
