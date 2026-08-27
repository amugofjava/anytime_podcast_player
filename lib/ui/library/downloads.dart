// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Displays downloaded podcast episodes and active downloads queue.
class Downloads extends StatefulWidget {
  const Downloads({
    super.key,
  });

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  int _selectedTabIndex = 0; // 0 = 已下载 (Downloaded), 1 = 下载中 (Downloading)
  bool _selectionMode = false;
  final Set<String> _selectedGuids = <String>{};

  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<EpisodeBloc>(context, listen: false);
    bloc.fetchDownloads(false);
    bloc.fetchActiveDownloads(false);
  }

  @override
  Widget build(BuildContext context) {
    final episodeBloc = Provider.of<EpisodeBloc>(context);
    final theme = Theme.of(context);

    return MultiSliver(
      children: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _DownloadsHeaderDelegate(
            height: 52.0,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: _selectionMode && _selectedTabIndex == 0
                  ? _buildSelectionHeader(context, episodeBloc)
                  : _buildTabBar(context, episodeBloc),
            ),
          ),
        ),
        if (_selectedTabIndex == 0)
          _buildDownloadedView(context, episodeBloc)
        else
          _buildActiveDownloadsView(context, episodeBloc),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, EpisodeBloc episodeBloc) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _TabButton(
            title: L.of(context)!.downloads_tab_downloaded,
            selected: _selectedTabIndex == 0,
            onTap: () {
              setState(() {
                _selectedTabIndex = 0;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<BlocState>(
            stream: episodeBloc.activeDownloads,
            builder: (context, snapshot) {
              int count = 0;
              final state = snapshot.data;
              if (state is BlocPopulatedState<List<Episode>>) {
                count = state.results?.length ?? 0;
              }

              return _TabButton(
                title: L.of(context)!.downloads_tab_active,
                badgeCount: count,
                selected: _selectedTabIndex == 1,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 1;
                    _selectionMode = false;
                    _selectedGuids.clear();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BuildContext context, EpisodeBloc episodeBloc) {
    final theme = Theme.of(context);

    return StreamBuilder<BlocState>(
      stream: episodeBloc.downloads,
      builder: (context, snapshot) {
        final episodes = (snapshot.data is BlocPopulatedState<List<Episode>>)
            ? ((snapshot.data as BlocPopulatedState<List<Episode>>).results ?? <Episode>[])
            : <Episode>[];

        final allSelected = episodes.isNotEmpty && _selectedGuids.length == episodes.length;

        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: L.of(context)!.multi_select_exit,
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedGuids.clear();
                });
              },
            ),
            const SizedBox(width: 4),
            Text(
              '${_selectedGuids.length} / ${episodes.length}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              child: Text(
                allSelected ? L.of(context)!.multi_select_deselect_all : L.of(context)!.multi_select_select_all,
              ),
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedGuids.clear();
                  } else {
                    _selectedGuids.addAll(
                      episodes.map((e) => e.guid).whereType<String>(),
                    );
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadedView(BuildContext context, EpisodeBloc episodeBloc) {
    final queueBloc = Provider.of<QueueBloc>(context);

    return StreamBuilder<BlocState>(
      stream: episodeBloc.downloads,
      builder: (BuildContext context, AsyncSnapshot<BlocState> snapshot) {
        final state = snapshot.data;

        if (state is BlocPopulatedState<List<Episode>>) {
          final episodes = state.results ?? <Episode>[];

          if (episodes.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 64.0, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      L.of(context)!.no_downloads_message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectionMode) {
            return MultiSliver(
              children: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final episode = episodes[index];
                      final isSelected = _selectedGuids.contains(episode.guid);

                      return _SelectableEpisodeTile(
                        episode: episode,
                        isSelected: isSelected,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedGuids.remove(episode.guid);
                            } else {
                              if (episode.guid != null) {
                                _selectedGuids.add(episode.guid!);
                              }
                            }
                          });
                        },
                      );
                    },
                    childCount: episodes.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildBatchActionBar(context, episodeBloc, episodes),
                ),
              ],
            );
          }

          return StreamBuilder<QueueState>(
            stream: queueBloc.queue,
            builder: (context, queueSnapshot) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final episode = episodes[index];
                    var queued = false;
                    var playing = false;

                    if (queueSnapshot.hasData) {
                      final playingGuid = queueSnapshot.data!.playing?.guid;
                      queued = queueSnapshot.data!.queue.any((e) => e.guid == episode.guid);
                      playing = playingGuid == episode.guid;
                    }

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _selectionMode = true;
                          if (episode.guid != null) {
                            _selectedGuids.add(episode.guid!);
                          }
                        });
                      },
                      child: EpisodeTile(
                        episode: episode,
                        download: false,
                        play: true,
                        playing: playing,
                        queued: queued,
                      ),
                    );
                  },
                  childCount: episodes.length,
                ),
              );
            },
          );
        } else if (state is BlocLoadingState) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: PlatformProgressIndicator(),
            ),
          );
        } else if (state is BlocErrorState) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('ERROR'),
            ),
          );
        }

        return SliverFillRemaining(
          hasScrollBody: false,
          child: Container(),
        );
      },
    );
  }

  Widget _buildBatchActionBar(
    BuildContext context,
    EpisodeBloc episodeBloc,
    List<Episode> allEpisodes,
  ) {
    final theme = Theme.of(context);
    final selectedEpisodes = allEpisodes.where((e) => _selectedGuids.contains(e.guid)).toList();
    final hasSelection = selectedEpisodes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: Icon(Icons.delete_outline, color: hasSelection ? Colors.red : Colors.grey),
            label: Text(
              L.of(context)!.batch_action_delete,
              style: TextStyle(color: hasSelection ? Colors.red : Colors.grey),
            ),
            onPressed: hasSelection ? () => _confirmBatchDelete(context, episodeBloc, selectedEpisodes) : null,
          ),
          TextButton.icon(
            icon: Icon(Icons.playlist_add, color: hasSelection ? theme.primaryColor : Colors.grey),
            label: Text(
              L.of(context)!.batch_action_queue,
              style: TextStyle(color: hasSelection ? theme.primaryColor : Colors.grey),
            ),
            onPressed: hasSelection ? () => _batchAddToQueue(context, episodeBloc, selectedEpisodes) : null,
          ),
          TextButton.icon(
            icon: Icon(Icons.done_all, color: hasSelection ? theme.primaryColor : Colors.grey),
            label: Text(
              L.of(context)!.batch_action_mark_played,
              style: TextStyle(color: hasSelection ? theme.primaryColor : Colors.grey),
            ),
            onPressed: hasSelection ? () => _batchTogglePlayed(context, episodeBloc, selectedEpisodes) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBatchDelete(
    BuildContext context,
    EpisodeBloc bloc,
    List<Episode> selectedEpisodes,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(L.of(context)!.batch_delete_dialog_title),
          content: Text(L.of(context)!.batch_delete_dialog_message),
          actions: [
            TextButton(
              child: Text(L.of(context)!.cancel_button_label),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: Text(
                L.of(context)!.delete_label,
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await bloc.batchDeleteDownloads(selectedEpisodes);
      if (mounted) {
        setState(() {
          _selectionMode = false;
          _selectedGuids.clear();
        });
      }
    }
  }

  Future<void> _batchAddToQueue(
    BuildContext context,
    EpisodeBloc bloc,
    List<Episode> selectedEpisodes,
  ) async {
    await bloc.batchAddToQueue(selectedEpisodes);
    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedGuids.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.of(context)!.batch_add_to_queue_success)),
      );
    }
  }

  Future<void> _batchTogglePlayed(
    BuildContext context,
    EpisodeBloc bloc,
    List<Episode> selectedEpisodes,
  ) async {
    final allPlayed = selectedEpisodes.every((e) => e.played);
    await bloc.batchTogglePlayed(selectedEpisodes, !allPlayed);
    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedGuids.clear();
      });
    }
  }

  Widget _buildActiveDownloadsView(BuildContext context, EpisodeBloc episodeBloc) {
    return StreamBuilder<BlocState>(
      stream: episodeBloc.activeDownloads,
      builder: (BuildContext context, AsyncSnapshot<BlocState> snapshot) {
        final state = snapshot.data;

        if (state is BlocPopulatedState<List<Episode>>) {
          final episodes = state.results ?? <Episode>[];

          if (episodes.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 64.0, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      L.of(context)!.active_downloads_empty_message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final episode = episodes[index];
                return _ActiveDownloadTile(
                  episode: episode,
                  onPause: () => episodeBloc.pauseDownload(episode),
                  onResume: () => episodeBloc.resumeDownload(episode),
                  onRetry: () => episodeBloc.retryDownload(episode),
                  onCancel: () => episodeBloc.cancelDownload(episode),
                );
              },
              childCount: episodes.length,
            ),
          );
        } else if (state is BlocLoadingState) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: PlatformProgressIndicator(),
            ),
          );
        } else if (state is BlocErrorState) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('ERROR'),
            ),
          );
        }

        return SliverFillRemaining(
          hasScrollBody: false,
          child: Container(),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final int badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    this.badgeCount = 0,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$title${badgeCount > 0 ? ', $badgeCount' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: selected
                ? Border.all(color: theme.primaryColor.withOpacity(0.4), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                  fontSize: 14.0,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _DownloadsHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _DownloadsHeaderDelegate oldDelegate) => true;
}

class _SelectableEpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool isSelected;
  final VoidCallback onToggle;

  const _SelectableEpisodeTile({
    required this.episode,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: isSelected,
      label: '${episode.title ?? ''}, ${episode.podcast ?? ''}',
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
              ),
              TileImage(
                url: episode.thumbImageUrl ?? episode.imageUrl ?? '',
                size: 48.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      episode.podcast ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDownloadTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _ActiveDownloadTile({
    required this.episode,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = episode.downloadState;
    final percentage = episode.downloadPercentage ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TileImage(
              url: episode.thumbImageUrl ?? episode.imageUrl ?? '',
              size: 52.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    episode.podcast ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6.0),
                  _buildStatusAndProgress(context, state, percentage),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            _buildActionButtons(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndProgress(BuildContext context, DownloadState state, int percentage) {
    final theme = Theme.of(context);

    if (state == DownloadState.downloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 4.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${L.of(context)!.download_status_downloading} $percentage%',
            style: TextStyle(fontSize: 11.0, color: theme.primaryColor),
          ),
        ],
      );
    } else if (state == DownloadState.converting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 4.0,
              color: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.orange),
              ),
              const SizedBox(width: 6),
              Text(
                '${L.of(context)!.download_status_converting} $percentage%',
                style: const TextStyle(fontSize: 11.0, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    } else if (state == DownloadState.paused) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 4.0,
              color: Colors.grey,
              backgroundColor: Colors.grey.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${L.of(context)!.download_status_paused} $percentage%',
            style: const TextStyle(fontSize: 11.0, color: Colors.grey),
          ),
        ],
      );
    } else if (state == DownloadState.failed) {
      return Row(
        children: [
          const Icon(Icons.error_outline, size: 14.0, color: Colors.red),
          const SizedBox(width: 4.0),
          Text(
            L.of(context)!.download_status_failed,
            style: const TextStyle(fontSize: 11.0, color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.hourglass_empty, size: 14.0, color: Colors.grey),
        const SizedBox(width: 4.0),
        Text(
          L.of(context)!.download_status_queued,
          style: const TextStyle(fontSize: 11.0, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DownloadState state) {
    if (state == DownloadState.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            tooltip: L.of(context)!.download_action_pause,
            onPressed: onPause,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: L.of(context)!.download_action_cancel,
            onPressed: onCancel,
          ),
        ],
      );
    } else if (state == DownloadState.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: L.of(context)!.download_action_resume,
            onPressed: onResume,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: L.of(context)!.download_action_cancel,
            onPressed: onCancel,
          ),
        ],
      );
    } else if (state == DownloadState.converting) {
      return IconButton(
        icon: const Icon(Icons.cancel_outlined),
        tooltip: L.of(context)!.download_action_cancel,
        onPressed: onCancel,
      );
    } else if (state == DownloadState.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: L.of(context)!.download_action_retry,
            onPressed: onRetry,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: L.of(context)!.download_action_cancel,
            onPressed: onCancel,
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.cancel_outlined),
      tooltip: L.of(context)!.download_action_cancel,
      onPressed: onCancel,
    );
  }
}
