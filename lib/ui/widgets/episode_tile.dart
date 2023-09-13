// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/episode_details.dart';
import 'package:anytime/ui/podcast/transport_controls.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

/// An EpisodeTitle is built with an [ExpandedTile] widget and displays the episode's
/// basic details, thumbnail and play button.
///
/// It can then be expanded to present addition information about the episode and further
/// controls.
///
/// TODO: Replace [Opacity] with [Container] with a transparent colour.
class EpisodeTile extends StatefulWidget {
  final Episode episode;
  final bool download;
  final bool play;
  final bool playing;
  final bool queued;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.download,
    required this.play,
    this.playing = false,
    this.queued = false,
  });

  @override
  State<EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<EpisodeTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final episodeBloc = Provider.of<EpisodeBloc>(context);
    final queueBloc = Provider.of<QueueBloc>(context);

    return Semantics(
      liveRegion: true,
      label:
          expanded ? L.of(context)!.semantics_episode_tile_expanded : L.of(context)!.semantics_episode_tile_collapsed,
      onTapHint: expanded
          ? L.of(context)!.semantics_episode_tile_expanded_hint
          : L.of(context)!.semantics_episode_tile_collapsed_hint,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
        key: Key('PT${widget.episode.guid}'),
        onExpansionChanged: (isExpanded) {
          setState(() {
            expanded = isExpanded;
          });
        },
        trailing: Opacity(
          opacity: widget.episode.played ? 0.5 : 1.0,
          child: EpisodeTransportControls(
            episode: widget.episode,
            download: widget.download,
            play: widget.play,
          ),
        ),
        leading: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.bottomLeft,
            fit: StackFit.passthrough,
            children: <Widget>[
              Opacity(
                opacity: widget.episode.played ? 0.5 : 1.0,
                child: TileImage(
                  url: widget.episode.thumbImageUrl ?? widget.episode.imageUrl!,
                  size: 56.0,
                  highlight: widget.episode.highlight,
                ),
              ),
              SizedBox(
                height: 5.0,
                width: 56.0 * (widget.episode.percentagePlayed / 100),
                child: Container(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        subtitle: Opacity(
          opacity: widget.episode.played ? 0.5 : 1.0,
          child: EpisodeSubtitle(widget.episode),
        ),
        title: Opacity(
          opacity: widget.episode.played ? 0.5 : 1.0,
          child: Text(
            widget.episode.title!,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            softWrap: false,
            style: textTheme.bodyMedium,
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Text(
                widget.episode.descriptionText!,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 5,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    ),
                    onPressed: widget.episode.downloaded
                        ? () {
                            showPlatformDialog<void>(
                              context: context,
                              useRootNavigator: false,
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
                                      episodeBloc.deleteDownload(widget.episode);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.delete_outline,
                          semanticLabel: L.of(context)!.delete_episode_button_label,
                          size: 22,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            L.of(context)!.delete_label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                    ),
                    onPressed: widget.playing
                        ? null
                        : () {
                            if (widget.queued) {
                              queueBloc.queueEvent(QueueRemoveEvent(episode: widget.episode));
                            } else {
                              queueBloc.queueEvent(QueueAddEvent(episode: widget.episode));
                            }
                          },
                    child: Column(
                      children: <Widget>[
                        Icon(
                          widget.queued ? Icons.playlist_add_check_outlined : Icons.playlist_add_outlined,
                          semanticLabel: widget.queued
                              ? L.of(context)!.semantics_remove_from_queue
                              : L.of(context)!.semantics_add_to_queue,
                          size: 22,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            widget.queued ? 'Remove' : 'Add',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                    ),
                    onPressed: () {
                      episodeBloc.togglePlayed(widget.episode);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          widget.episode.played ? Icons.unpublished_outlined : Icons.check_circle_outline,
                          size: 22,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        Text(
                          widget.episode.played ? L.of(context)!.mark_unplayed_label : L.of(context)!.mark_played_label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: theme.bottomAppBarTheme.color,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.0),
                              topRight: Radius.circular(10.0),
                            ),
                          ),
                          builder: (context) {
                            return EpisodeDetails(
                              episode: widget.episode,
                            );
                          });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.unfold_more_outlined,
                          size: 22,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        Text(
                          L.of(context)!.more_label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EpisodeTransportControls extends StatelessWidget {
  final Episode episode;
  final bool download;
  final bool play;

  const EpisodeTransportControls({
    super.key,
    required this.episode,
    required this.download,
    required this.play,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (download) {
      buttons.add(Semantics(
        container: true,
        child: DownloadControl(
          episode: episode,
        ),
      ));
    }

    if (play) {
      buttons.add(Semantics(
        container: true,
        child: PlayControl(
          episode: episode,
        ),
      ));
    }

    return SizedBox(
      width: (buttons.length * 48.0),
      child: Row(
        children: <Widget>[...buttons],
      ),
    );
  }
}

class EpisodeSubtitle extends StatelessWidget {
  final Episode episode;
  final String date;
  final Duration length;

  EpisodeSubtitle(this.episode, {super.key})
      : date = episode.publicationDate == null
            ? ''
            : DateFormat(episode.publicationDate!.year == DateTime.now().year ? 'd MMM' : 'd MMM yy')
                .format(episode.publicationDate!),
        length = Duration(seconds: episode.duration);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var timeRemaining = episode.timeRemaining;

    String title;

    if (length.inSeconds > 0) {
      if (length.inSeconds < 60) {
        title = '$date - ${length.inSeconds} sec';
      } else {
        title = '$date - ${length.inMinutes} min';
      }
    } else {
      title = date;
    }

    if (timeRemaining.inSeconds > 0) {
      if (timeRemaining.inSeconds < 60) {
        title = '$title / ${timeRemaining.inSeconds} sec left';
      } else {
        title = '$title / ${timeRemaining.inMinutes} min left';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: textTheme.bodySmall,
      ),
    );
  }
}
