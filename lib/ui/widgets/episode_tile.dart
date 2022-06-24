// Copyright 2020-2022 Ben Hills. All rights reserved.
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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// An EpisodeTitle is built with an [ExpandedTile] widget and displays the
/// episode's basic details, thumbnail and play button. It can then be
/// expanded to present addition information about the episode and further
/// controls.
///
/// TODO: Replace [Opacity] with [Container] with a transparent colour.
class EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool download;
  final bool play;
  final bool playing;
  final bool queued;

  const EpisodeTile({
    @required this.episode,
    @required this.download,
    @required this.play,
    this.playing = false,
    this.queued = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final episodeBloc = Provider.of<EpisodeBloc>(context);
    final queueBloc = Provider.of<QueueBloc>(context);

    return ExpansionTile(
      key: Key('PT${episode.guid}'),
      trailing: Opacity(
        opacity: episode.played ? 0.5 : 1.0,
        child: EpisodeTransportControls(
          episode: episode,
          download: download,
          play: play,
        ),
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
          style: textTheme.bodyText2,
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
              episode.descriptionText,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 5,
              style: Theme.of(context).textTheme.bodyText1.copyWith(
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
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        L.of(context).delete_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                  onPressed: playing
                      ? null
                      : () {
                          if (queued) {
                            queueBloc.queueEvent(QueueRemoveEvent(episode: episode));
                          } else {
                            queueBloc.queueEvent(QueueAddEvent(episode: episode));
                          }
                        },
                  child: Column(
                    children: <Widget>[
                      Icon(
                        queued ? Icons.playlist_add_check_outlined : Icons.playlist_add_outlined,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        queued ? 'Remove' : 'Add',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                    episodeBloc.togglePlayed(episode);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        episode.played ? Icons.unpublished_outlined : Icons.check_circle_outline,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        episode.played ? L.of(context).mark_unplayed_label : L.of(context).mark_played_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                        backgroundColor: theme.bottomAppBarColor,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        builder: (context) {
                          return EpisodeDetails(
                            episode: episode,
                          );
                        });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.unfold_more_outlined,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        L.of(context).more_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
    );
  }
}

class EpisodeTransportControls extends StatelessWidget {
  final Episode episode;
  final bool download;
  final bool play;

  EpisodeTransportControls({
    @required this.episode,
    @required this.download,
    @required this.play,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (download) {
      buttons.add(Padding(
        padding: const EdgeInsets.only(left: 0.0),
        child: DownloadControl(
          episode: episode,
        ),
      ));
    }

    if (play) {
      buttons.add(Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: PlayControl(
          episode: episode,
        ),
      ));
    }

    return SizedBox(
      width: (buttons.length * 38.0) + 8.0,
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

  EpisodeSubtitle(this.episode)
      : date = episode.publicationDate == null
            ? ''
            : DateFormat(episode.publicationDate.year == DateTime.now().year ? 'd MMM' : 'd MMM yy')
                .format(episode.publicationDate),
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
        style: textTheme.caption,
      ),
    );
  }
}
