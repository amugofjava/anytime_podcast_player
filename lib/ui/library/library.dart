// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// This class displays the list of podcasts the user is currently following.
class Library extends StatefulWidget {
  const Library({
    super.key,
  });

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  StreamSubscription? _settingsSubscription;
  String _activeFilter = 'shows';

  @override
  void initState() {
    super.initState();

    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    var currentOrder = settingsBloc.currentSettings.layoutOrder;

    _settingsSubscription = settingsBloc.settings.listen((event) {
      if (event.layoutOrder != currentOrder) {
        podcastBloc.podcastEvent(PodcastEvent.reloadSubscriptions);
        currentOrder = event.layoutOrder;
      }
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder<List<Podcast>>(
      stream: podcastBloc.subscriptions,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
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
        }

        final podcasts = snapshot.data!;

        if (podcasts.isEmpty) {
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
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    L.of(context)!.no_subscriptions_message,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final updated = [...podcasts]..sort((a, b) {
            final newEpisodeCompare = b.newEpisodes.compareTo(a.newEpisodes);
            if (newEpisodeCompare != 0) {
              return newEpisodeCompare;
            }

            return b.episodeCount.compareTo(a.episodeCount);
          });

        final filtered = switch (_activeFilter) {
          'new' => podcasts.where((podcast) => podcast.newEpisodes > 0).toList(growable: false),
          'playlists' => const <Podcast>[],
          _ => podcasts,
        };

        final featured = updated.first;
        final sideCards = updated.skip(1).take(2).toList(growable: false);

        return MultiSliver(
          children: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LibraryFilterChip(
                        label: 'Shows',
                        selected: _activeFilter == 'shows',
                        onTap: () => setState(() => _activeFilter = 'shows'),
                      ),
                      const SizedBox(width: 8.0),
                      _LibraryFilterChip(
                        label: 'Playlists',
                        selected: _activeFilter == 'playlists',
                        onTap: () => setState(() => _activeFilter = 'playlists'),
                      ),
                      const SizedBox(width: 8.0),
                      _LibraryFilterChip(
                        label: 'New Episodes',
                        selected: _activeFilter == 'new',
                        onTap: () => setState(() => _activeFilter = 'new'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_activeFilter != 'playlists') ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                  child: _LibrarySectionHeading(
                    eyebrow: 'Recently Updated',
                    title: 'New Episodes',
                    actionLabel: 'See all',
                    onActionTap: () => setState(() => _activeFilter = 'new'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 0.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 640.0) {
                        return Column(
                          children: [
                            _FeaturedLibraryCard(
                              podcast: featured,
                              onTap: () => _openPodcast(podcastBloc, featured),
                              onPlay: () => audioBloc.playLatestEpisode(featured),
                            ),
                            const SizedBox(height: 14.0),
                            ...sideCards.map(
                              (podcast) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _LibrarySideCard(
                                  podcast: podcast,
                                  onTap: () => _openPodcast(podcastBloc, podcast),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FeaturedLibraryCard(
                              podcast: featured,
                              onTap: () => _openPodcast(podcastBloc, featured),
                              onPlay: () => audioBloc.playLatestEpisode(featured),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              children: sideCards
                                  .map(
                                    (podcast) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _LibrarySideCard(
                                        podcast: podcast,
                                        onTap: () => _openPodcast(podcastBloc, podcast),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 14.0),
                child: Text(
                  _activeFilter == 'new' ? 'New in Your Library' : 'Your Library',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            if (_activeFilter == 'playlists')
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                  child: _LibraryEmptyCard(
                    icon: Icons.queue_music_rounded,
                    title: 'Playlists are next',
                    message:
                        'This screen is following the Stitch structure first. Playlist-specific content still needs its own data path.',
                  ),
                ),
              )
            else if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                  child: _LibraryEmptyCard(
                    icon: Icons.new_releases_outlined,
                    title: 'No new episodes yet',
                    message: 'Your followed shows are up to date right now.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180.0,
                    mainAxisSpacing: 20.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 0.64,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final podcast = filtered[index];
                      return _LibraryGridCard(
                        podcast: podcast,
                        onTap: () => _openPodcast(podcastBloc, podcast),
                      );
                    },
                    childCount: filtered.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openPodcast(PodcastBloc podcastBloc, Podcast podcast) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'podcastdetails'),
        builder: (context) => PodcastDetails(podcast, podcastBloc),
      ),
    ).then((_) {
      podcastBloc.podcastEvent(PodcastEvent.reloadSubscriptions);
    });
  }
}

class _LibraryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LibraryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      selectedColor: theme.colorScheme.primary,
      side: BorderSide.none,
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    );
  }
}

class _LibrarySectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _LibrarySectionHeading({
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _FeaturedLibraryCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _FeaturedLibraryCard({
    required this.podcast,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(30.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 240.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ArtworkFill(imageUrl: podcast.imageUrl, borderRadius: 30.0),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.primary.withValues(alpha: 0.84),
                    ],
                    stops: const [0.18, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        _categoryLabel(podcast),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      _podcastMeta(podcast),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    SizedBox(
                      width: 46.0,
                      height: 46.0,
                      child: IconButton(
                        onPressed: onPlay,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryFixed,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
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

  String _categoryLabel(Podcast podcast) {
    if (podcast.newEpisodes > 0) {
      return '${podcast.newEpisodes} NEW';
    }

    return 'UPDATED';
  }

  String _podcastMeta(Podcast podcast) {
    final subtitle = podcast.copyright?.trim();

    if (subtitle != null && subtitle.isNotEmpty) {
      return '$subtitle • ${podcast.episodeCount > 0 ? '${podcast.episodeCount} episodes' : 'Library show'}';
    }

    return podcast.episodeCount > 0 ? '${podcast.episodeCount} episodes' : 'Library show';
  }
}

class _LibrarySideCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const _LibrarySideCard({
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: SizedBox(
                  width: 82.0,
                  height: 82.0,
                  child: _ArtworkFill(
                    imageUrl: podcast.imageUrl,
                    borderRadius: 18.0,
                  ),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      _podcastMeta(podcast),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _podcastMeta(Podcast podcast) {
    final subtitle = podcast.copyright?.trim();
    final durationText = podcast.newEpisodes > 0 ? '${podcast.newEpisodes} new' : 'Recently refreshed';

    if (subtitle != null && subtitle.isNotEmpty) {
      return '$subtitle • $durationText';
    }

    return durationText;
  }
}

class _LibraryGridCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const _LibraryGridCard({
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.0),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.0),
                      child: _ArtworkFill(
                        imageUrl: podcast.imageUrl,
                        borderRadius: 22.0,
                      ),
                    ),
                  ),
                  if (podcast.newEpisodes > 0)
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        child: Text(
                          '${podcast.newEpisodes} NEW',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2.0),
            Text(
              podcast.copyright?.trim().isNotEmpty == true ? podcast.copyright! : 'Subscribed show',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _LibraryEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 34.0,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14.0),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6.0),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkFill extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;

  const _ArtworkFill({
    required this.imageUrl,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.podcasts_rounded,
          color: theme.colorScheme.primary,
          size: 40.0,
        ),
      );
    }

    return PodcastImage(
      url: imageUrl!,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      placeholder: ColoredBox(
        color: theme.colorScheme.surfaceContainerHigh,
      ),
      errorPlaceholder: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.podcasts_rounded,
          color: theme.colorScheme.primary,
          size: 40.0,
        ),
      ),
    );
  }
}
