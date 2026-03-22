// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/podcast/podcast_episode_list.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Displays a list of currently downloaded podcast episodes.
class Downloads extends StatefulWidget {
  const Downloads({
    super.key,
  });

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<EpisodeBloc>(context, listen: false);

    bloc.fetchDownloads(false);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<EpisodeBloc>(context);

    return StreamBuilder<BlocState>(
      stream: bloc.downloads,
      builder: (BuildContext context, AsyncSnapshot<BlocState> snapshot) {
        final state = snapshot.data;

        if (state is BlocPopulatedState<List<Episode>>) {
          final episodes = state.results ?? <Episode>[];
          final totalBytes = episodes.fold<int>(0, (total, episode) => total + episode.length);

          return MultiSliver(
            children: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.of(context)!.downloads,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        '${episodes.length} episodes • ${_formatFileSize(totalBytes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              PodcastEpisodeList(
                episodes: episodes,
                play: true,
                download: false,
                icon: Icons.cloud_download,
                emptyMessage: L.of(context)!.no_downloads_message,
              ),
            ],
          );
        } else {
          if (state is BlocLoadingState) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  PlatformProgressIndicator(),
                ],
              ),
            );
          } else if (state is BlocErrorState) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Text('ERROR'),
            );
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: Container(),
          );
        }
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0 MB';
    }

    final mb = bytes / (1024 * 1024);

    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }

    return '${mb.toStringAsFixed(1)} MB';
  }
}
