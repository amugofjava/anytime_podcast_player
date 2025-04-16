// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/person_avatar.dart';
import 'package:anytime/ui/podcast/transport_controls.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

/// This class renders the more info widget that is accessed from the 'more'
/// button on an episode.
///
/// The widget is displayed as a draggable, scrollable sheet. This contains
/// episode icon and play/pause control, below which the episode title, show
/// notes and person(s) details (if available).
class EpisodeDetails extends StatefulWidget {
  final Episode episode;

  const EpisodeDetails({
    super.key,
    required this.episode,
  });

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
                    key: const Key('episodemoreinfo'),
                    trailing: PlayControl(
                      episode: episode,
                    ),
                    leading: TileImage(
                      url: episode.thumbImageUrl ?? episode.imageUrl!,
                      size: 56.0,
                      highlight: episode.highlight,
                    ),
                    subtitle: EpisodeSubtitle(episode),
                    title: Text(
                      episode.title!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )),
                const Divider(),
                EpisodeToolBar(
                  episode: episode,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      episode.title!,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (episode.persons.isNotEmpty)
                  SizedBox(
                    height: 120.0,
                    child: ListView.builder(
                      itemCount: episode.persons.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return PersonAvatar(person: episode.persons[index]);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: PodcastHtml(content: episode.content ?? episode.description!),
                )
              ],
            ),
          );
        });
  }
}

class EpisodeToolBar extends StatelessWidget {
  final Episode episode;

  const EpisodeToolBar({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final episodeBloc = Provider.of<EpisodeBloc>(context);
    final queueBloc = Provider.of<QueueBloc>(context);

    return StreamBuilder<QueueState>(
        stream: queueBloc.queue,
        initialData: QueueEmptyState(),
        builder: (context, queueSnapshot) {
          final data = queueSnapshot.data!;
          final queued = queueSnapshot.data!.queue.any((element) => element.guid == episode.guid);

          return Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    semanticLabel: L.of(context)!.delete_episode_button_label,
                    size: 20,
                  ),
                  onPressed: episode.downloaded
                      ? () {
                          showPlatformDialog<void>(
                            context: context,
                            useRootNavigator: false,

                            /// TODO: Extract to own delete dialog for reuse
                            builder: (_) => BasicDialogAlert(
                              title: Text(
                                L.of(context)!.delete_episode_title,
                              ),
                              content: Text(L.of(context)!.delete_episode_confirmation),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: ActionText(
                                    L.of(context)!.cancel_button_label,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                BasicDialogAction(
                                  title: ActionText(
                                    L.of(context)!.delete_button_label,
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
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    queued ? Icons.playlist_add_check_outlined : Icons.playlist_add_outlined,
                    semanticLabel:
                        queued ? L.of(context)!.semantics_remove_from_queue : L.of(context)!.semantics_add_to_queue,
                    size: 20,
                  ),
                  onPressed: data.playing?.guid == episode.guid
                      ? null
                      : () {
                          if (queued) {
                            queueBloc.queueEvent(QueueRemoveEvent(episode: episode));
                          } else {
                            queueBloc.queueEvent(QueueAddEvent(episode: episode));
                          }
                        },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    data.playing?.played ?? false ? Icons.unpublished_outlined : Icons.check_circle_outline,
                    semanticLabel: data.playing?.played ?? false
                        ? L.of(context)!.mark_unplayed_label
                        : L.of(context)!.mark_played_label,
                    size: 20,
                  ),
                  onPressed: data.playing?.played ?? false
                      ? null
                      : () {
                          episodeBloc.togglePlayed(episode);
                        },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.share_outlined,
                    semanticLabel: L.of(context)!.delete_episode_button_label,
                    size: 20,
                  ),
                  onPressed: episode.guid.isEmpty
                      ? null
                      : () {
                          _shareEpisode();
                        },
                ),
              ],
            ),
          );
        });
  }

  void _shareEpisode() async {
    await shareEpisode(episode: episode);
  }
}
