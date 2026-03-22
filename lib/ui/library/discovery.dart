// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart' as search;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// This class is the root class for rendering the Discover tab.
///
/// This UI can optionally show a list of genres provided by iTunes/PodcastIndex.
class Discovery extends StatefulWidget {
  static const fetchSize = 20;
  final bool categories;

  const Discovery({
    super.key,
    this.categories = false,
  });

  @override
  State<StatefulWidget> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<DiscoveryBloc>(context, listen: false);

    bloc.discover(DiscoveryChartEvent(
      count: Discovery.fetchSize,
      genre: bloc.selectedGenre.genre,
      countryCode: PlatformDispatcher.instance.locale.countryCode?.toLowerCase() ?? '',
      languageCode: PlatformDispatcher.instance.locale.languageCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<DiscoveryBloc>(context);
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder<DiscoveryState>(
      stream: bloc.results,
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state is DiscoveryPopulatedState) {
          final results = state.results as search.SearchResult;
          final podcasts = results.items.map(Podcast.fromSearchResultItem).toList(growable: false);

          if (podcasts.isEmpty) {
            return _DiscoveryEmptyState(
              icon: Icons.explore_outlined,
              message: L.of(context)!.no_search_results_message,
            );
          }

          final featured = podcasts.first;
          final recommended = podcasts.skip(1).take(4).toList(growable: false);
          final trending = (podcasts.length > 5 ? podcasts.skip(5) : podcasts.skip(1)).toList(growable: false);

          return MultiSliver(
            children: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 20.0),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _DiscoverFeaturedCard(
                    podcast: featured,
                    onTap: () => _openPodcast(context, featured),
                    onPlay: () => audioBloc.playLatestEpisode(featured),
                  ),
                ),
              ),
              if (widget.categories)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 26.0, 16.0, 0.0),
                    child: _SectionHeading(
                      title: 'Categories',
                      actionLabel: 'View all',
                    ),
                  ),
                ),
              if (widget.categories)
                SliverToBoxAdapter(
                  child: CategorySelectorWidget(
                    discoveryBloc: bloc,
                  ),
                ),
              if (recommended.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 0.0),
                    child: _SectionHeading(
                      title: 'For You',
                      subtitle: 'A more editorial take on the chart picks this week.',
                    ),
                  ),
                ),
              if (recommended.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 238.0,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 0.0),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final podcast = recommended[index];
                        return _DiscoverRecommendationCard(
                          podcast: podcast,
                          onTap: () => _openPodcast(context, podcast),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: 14.0),
                      itemCount: recommended.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 12.0),
                  child: _SectionHeading(
                    title: 'Trending Right Now',
                    subtitle: 'The chart feed, reframed to feel closer to the Stitch direction.',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final podcast = trending[index];
                      return _DiscoverPodcastCard(
                        podcast: podcast,
                        onTap: () => _openPodcast(context, podcast),
                      );
                    },
                    childCount: trending.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            ],
          );
        }

        if (state is DiscoveryLoadingState) {
          return MultiSliver(
            children: const [
              SliverToBoxAdapter(
                child: SizedBox(height: 120.0),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: PlatformProgressIndicator(),
                ),
              ),
            ],
          );
        }

        if (state is BlocErrorState) {
          return _DiscoveryEmptyState(
            icon: Icons.error_outline,
            message: L.of(context)!.no_search_results_message,
          );
        }

        return MultiSliver(
          children: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                child: Text(
                  'Discover',
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPodcast(BuildContext context, Podcast podcast) {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

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

class CategorySelectorWidget extends StatefulWidget {
  const CategorySelectorWidget({
    super.key,
    required this.discoveryBloc,
  });

  final DiscoveryBloc discoveryBloc;

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.discoveryBloc.selectedGenre.genre;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 0.0),
        child: StreamBuilder<List<String>>(
          stream: widget.discoveryBloc.genres,
          initialData: const [],
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(snapshot.data!.length, (index) {
                  final item = snapshot.data![index];
                  final isSelected = item == selectedCategory || (selectedCategory.isEmpty && index == 0);

                  return Padding(
                    padding: EdgeInsets.only(right: index == snapshot.data!.length - 1 ? 0.0 : 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      showCheckmark: false,
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      selectedColor: theme.colorScheme.primary,
                      side: BorderSide.none,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = item;
                        });

                        widget.discoveryBloc.discover(DiscoveryChartEvent(
                          count: Discovery.fetchSize,
                          genre: item,
                          countryCode: PlatformDispatcher.instance.locale.countryCode?.toLowerCase() ?? '',
                          languageCode: PlatformDispatcher.instance.locale.languageCode,
                        ));
                      },
                      label: Text(item),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverFeaturedCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _DiscoverFeaturedCard({
    required this.podcast,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = podcast.copyright?.trim().isNotEmpty == true
        ? podcast.copyright!.trim()
        : 'A chart-topping show worth starting with.';

    return Material(
      borderRadius: BorderRadius.circular(30.0),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 290.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PodcastArtwork(
                imageUrl: podcast.imageUrl,
                borderRadius: 30.0,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      theme.colorScheme.primary.withValues(alpha: 0.86),
                    ],
                    stops: const [0.18, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(
                        'FEATURED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      podcast.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.72),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Listen Now'),
                        ),
                        const SizedBox(width: 12.0),
                        IconButton(
                          onPressed: onTap,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
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

class _DiscoverRecommendationCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const _DiscoverRecommendationCard({
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 162.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24.0),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: SizedBox(
                  width: 162.0,
                  height: 162.0,
                  child: _PodcastArtwork(
                    imageUrl: podcast.imageUrl,
                    borderRadius: 24.0,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                podcast.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4.0),
              Text(
                podcast.copyright?.trim().isNotEmpty == true ? podcast.copyright! : 'Curated recommendation',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverPodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const _DiscoverPodcastCard({
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = podcast.copyright?.trim().isNotEmpty == true ? podcast.copyright! : 'Featured podcast';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                SizedBox(
                  width: 74.0,
                  height: 74.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.0),
                    child: _PodcastArtwork(
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
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;

  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PodcastArtwork extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;

  const _PodcastArtwork({
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
          size: 40.0,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return PodcastImage(
      url: imageUrl!,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      placeholder: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      errorPlaceholder: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.podcasts_rounded,
          size: 40.0,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _DiscoveryEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DiscoveryEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 72.0,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
