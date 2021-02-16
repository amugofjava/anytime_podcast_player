// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/show_notes.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:anytime/ui/widgets/transport_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// An EpisodeTitle is built with an [ExpandedTile] widget and displays the
/// episode's basic details, thumbnail and play button. It can then be
/// expanded to present addition information about the episode and further
/// controls.
class EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool download;
  final bool play;

  const EpisodeTile({
    @required this.episode,
    @required this.download,
    @required this.play,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bloc = Provider.of<EpisodeBloc>(context);

    return ExpansionTile(
      key: Key('PT${episode.guid}'),
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
              style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
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
                child: FlatButton(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  onPressed: episode.downloaded
                      ? () {
                          showPlatformDialog<void>(
                            context: context,
                            builder: (_) => BasicDialogAlert(
                              title: Text(
                                L.of(context).delete_episode_title,
                              ),
                              content: Text(L.of(context).delete_episode_confirmation),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: Text(
                                    L.of(context).cancel_button_label,
                                    style: TextStyle(color: Theme.of(context).primaryColor),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                BasicDialogAction(
                                  title: Text(
                                    L.of(context).delete_button_label,
                                    style: TextStyle(color: Theme.of(context).primaryColor),
                                  ),
                                  onPressed: () {
                                    bloc.deleteDownload(episode);
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
                        color: Theme.of(context).buttonColor,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        L.of(context).delete_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).buttonColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                  onPressed: () {
                    return Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ShowNotes(
                          episode: episode,
                        ),
                        fullscreenDialog: true,
                      ),
                    ).then((value) {});
                  },
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.wysiwyg_outlined,
                        color: Theme.of(context).buttonColor,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        L.of(context).show_notes_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).buttonColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
                  onPressed: () {
                    bloc.togglePlayed(episode);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.bookmark_border_outlined,
                        color: Theme.of(context).buttonColor,
                        size: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        episode.played ? L.of(context).mark_unplayed_label : L.of(context).mark_played_label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).buttonColor,
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
            ),
          ),
          Container(
            height: 4.0,
            width: 56.0 * (episode.percentagePlayed / 100),
            color: Theme.of(context).primaryColor,
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
          style: textTheme.bodyText2.copyWith(fontWeight: FontWeight.normal),
        ),
      ),
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
      : date = episode.publicationDate == null ? '' : DateFormat('d MMM').format(episode.publicationDate),
        length = Duration(seconds: episode.duration);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var timeRemaining = episode.timeRemaining;

    String title;

    if (length.inSeconds < 60) {
      title = '$date - ${length.inSeconds} sec';
    } else {
      title = '$date - ${length.inMinutes} min';
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
