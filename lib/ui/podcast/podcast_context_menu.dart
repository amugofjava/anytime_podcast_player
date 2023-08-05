// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This class is responsible for rendering the context menu on the podcast details
/// page.
///
/// It returns either a [_MaterialPodcastMenu] or a [_CupertinoContextMenu}
/// instance depending upon which platform we are running on.
///
/// The target platform is based on the current [Theme]: [ThemeData.platform].
class PodcastContextMenu extends StatelessWidget {
  final Podcast podcast;

  const PodcastContextMenu(
    this.podcast, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _MaterialPodcastMenu(podcast);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _CupertinoContextMenu(podcast);
    }
  }
}

/// This is the material design version of the context menu. This will be rendered
/// for all platforms that are not iOS.
class _MaterialPodcastMenu extends StatelessWidget {
  final Podcast podcast;

  const _MaterialPodcastMenu(this.podcast);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          return PopupMenuButton<String>(
            onSelected: (event) {
              togglePlayed(value: event, bloc: bloc);
            },
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'ma',
                  enabled: podcast.subscribed,
                  child: Text(L.of(context)!.mark_episodes_played_label),
                ),
                PopupMenuItem<String>(
                  value: 'ua',
                  enabled: podcast.subscribed,
                  child: Text(L.of(context)!.mark_episodes_not_played_label),
                ),
              ];
            },
          );
        });
  }

  void togglePlayed({
    required String value,
    required PodcastBloc bloc,
  }) {
    if (value == 'ma') {
      bloc.podcastEvent(PodcastEvent.markAllPlayed);
    } else if (value == 'ua') {
      bloc.podcastEvent(PodcastEvent.clearAllPlayed);
    }
  }
}

/// This is the Cupertino context menu and is rendered only when running on
/// an iOS device.
class _CupertinoContextMenu extends StatelessWidget {
  final Podcast podcast;

  const _CupertinoContextMenu(this.podcast);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          return IconButton(
            tooltip: L.of(context)!.podcast_options_overflow_menu_semantic_label,
            icon: const Icon(CupertinoIcons.ellipsis),
            onPressed: () => showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) {
                return CupertinoActionSheet(
                  actions: <Widget>[
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () {
                        bloc.podcastEvent(PodcastEvent.markAllPlayed);
                        Navigator.pop(context, 'Cancel');
                      },
                      child: Text(L.of(context)!.mark_episodes_played_label),
                    ),
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () {
                        bloc.podcastEvent(PodcastEvent.clearAllPlayed);
                        Navigator.pop(context, 'Cancel');
                      },
                      child: Text(L.of(context)!.mark_episodes_not_played_label),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context, 'Cancel');
                    },
                    child: Text(L.of(context)!.cancel_option_label),
                  ),
                );
              },
            ),
          );
        });
  }
}
