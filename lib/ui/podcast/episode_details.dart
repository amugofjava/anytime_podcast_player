// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/podcast/transport_controls.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

class EpisodeDetails extends StatefulWidget {
  final Episode episode;

  EpisodeDetails({
    Key key,
    this.episode,
  }) : super(key: key) {
    print('New EpisodeDetails! ${episode.title}');
  }

  @override
  _EpisodeDetailsState createState() => _EpisodeDetailsState();
}

class _EpisodeDetailsState extends State<EpisodeDetails> {
  @override
  Widget build(BuildContext context) {
    final episodeBloc = Provider.of<EpisodeBloc>(context);
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
                        Opacity(
                          opacity: episode.played ? 0.5 : 1.0,
                          child: TileImage(
                            url: episode.thumbImageUrl ?? episode.imageUrl,
                            size: 56.0,
                            highlight: episode.highlight,
                          ),
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
                    subtitle: Opacity(
                      opacity: episode.played ? 0.5 : 1.0,
                      child: EpisodeSubtitle(episode),
                    ),
                    title: Opacity(
                      opacity: episode.played ? 0.5 : 1.0,
                      child: Text(
                        episode.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    )),
                Container(
                  height: 48.0,
                  color: Theme.of(context).dividerColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: PopupMenuButton<String>(
                          color: Theme.of(context).dialogBackgroundColor,
                          onSelected: (event) {
                            // togglePlayed(value: event, bloc: bloc);
                          },
                          icon: Icon(
                            Icons.playlist_add_outlined,
                            size: 28,
                          ),
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'ma',
                                child: Text(L.of(context).mark_episodes_played_label),
                              ),
                              PopupMenuItem<String>(
                                value: 'ua',
                                child: Text(L.of(context).mark_episodes_not_played_label),
                              ),
                            ];
                          },
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                          ),
                          onPressed: () {
                            episodeBloc.togglePlayed(episode);
                          },
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                          ),
                          onPressed: episode.downloaded
                              ? () {
                                  showPlatformDialog<void>(
                                    context: context,
                                    useRootNavigator: false,
                                    builder: (_) => BasicDialogAlert(
                                      title: Text(
                                        L.of(context).delete_episode_title,
                                      ),
                                      content: Text(L.of(context).delete_episode_confirmation),
                                      actions: <Widget>[
                                        BasicDialogAction(
                                          title: ActionText(
                                            L.of(context).cancel_button_label,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        BasicDialogAction(
                                          title: ActionText(
                                            L.of(context).delete_button_label,
                                          ),
                                          iosIsDefaultAction: true,
                                          iosIsDestructiveAction: true,
                                          onPressed: () {
                                            episodeBloc.deleteDownload(episode);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                          child: Icon(
                            Icons.delete_outline,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
