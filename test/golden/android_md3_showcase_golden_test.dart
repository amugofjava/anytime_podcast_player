import 'package:anytime/ui/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpShowcase(
    WidgetTester tester, {
    required ThemeData theme,
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('android light shell golden', (tester) async {
    await pumpShowcase(
      tester,
      theme: Themes.lightTheme().themeData,
      child: const _DiscoverShowcase(),
    );

    await expectLater(
      find.byType(_DiscoverShowcase),
      matchesGoldenFile('goldens/android_light_shell.png'),
    );
  });

  testWidgets('android dark playback golden', (tester) async {
    await pumpShowcase(
      tester,
      theme: Themes.darkTheme().themeData,
      child: const _PlaybackShowcase(),
    );

    await expectLater(
      find.byType(_PlaybackShowcase),
      matchesGoldenFile('goldens/android_dark_playback.png'),
    );
  });
}

class _DiscoverShowcase extends StatelessWidget {
  const _DiscoverShowcase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: Text(
          'Discover',
          style: theme.textTheme.headlineSmall,
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'Downloads'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const _SearchField(),
          const SizedBox(height: 20),
          Container(
            height: 188,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'TRENDING NOW',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onPrimaryFixed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Midnight Garden',
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top Categories', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip('True Crime'),
              _CategoryChip('Tech', selected: true),
              _CategoryChip('History'),
              _CategoryChip('Science'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Latest Episodes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const _EpisodeCard(
              title: 'Understanding the Wind in the Machine', subtitle: 'The Sound Design Show • 45 min'),
          const SizedBox(height: 12),
          const _EpisodeCard(title: 'The Migration Patterns of the Deep', subtitle: 'Wilderness Log • 1h 12m'),
        ],
      ),
    );
  }
}

class _PlaybackShowcase extends StatelessWidget {
  const _PlaybackShowcase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: Text('Now Playing', style: theme.textTheme.headlineSmall),
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.expand_more)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surfaceContainerLow,
                      theme.colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lightbulb_rounded,
                    size: 120,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('The Architecture of Silence', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Arboretum Narratives • Ep. 42', style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: 0.66,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('24:18', style: theme.textTheme.labelMedium),
                Text('36:45', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SmallControl(icon: Icons.slow_motion_video_outlined, label: '1.5x'),
                _CenterControl(theme: theme),
                const _SmallControl(icon: Icons.bedtime_outlined, label: 'OFF'),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.speaker_group, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LISTENING ON', style: theme.textTheme.labelSmall),
                        Text('Living Room HomePod', style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  FilledButton.tonal(onPressed: () {}, child: const Text('Change')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Artists, episodes, or podcasts',
        prefixIcon: const Icon(Icons.search),
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _CategoryChip(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EpisodeCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallControl extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallControl({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            foregroundColor: theme.colorScheme.primary,
          ),
          onPressed: () {},
          icon: Icon(icon),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _CenterControl extends StatelessWidget {
  final ThemeData theme;

  const _CenterControl({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          height: 84,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: const CircleBorder(),
            ),
            onPressed: () {},
            child: const Icon(Icons.pause, size: 40),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
      ],
    );
  }
}
