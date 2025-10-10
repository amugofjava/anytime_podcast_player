import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Search and menu buttons should not expose duplicate tooltip semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(const _TestApp());

      final searchSemantics = tester.getSemantics(find.byIcon(Icons.search));
      final menuSemantics = tester.getSemantics(find.byIcon(Icons.more_vert));

      expect(searchSemantics.label, isNotEmpty);
      expect(searchSemantics.tooltip ?? '', isEmpty);

      expect(menuSemantics.label, isNotEmpty);
      expect(menuSemantics.tooltip ?? '', isEmpty);

      semantics.dispose();
    },
  );
}

class _TestAppBarWrapper extends StatelessWidget {
  const _TestAppBarWrapper();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
      appBar: _TestAppBar(),
    );
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _TestAppBarWrapper(),
    );
  }
}

class _TestAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TestAppBar();

  @override
  Widget build(BuildContext context) {
    void handleSearch() {}
    void handleMenu() {}

    return AppBar(
      title: const Text('Anytime'),
      actions: [
        Tooltip(
          message: 'Search for podcasts',
          excludeFromSemantics: true,
          child: Semantics(
            label: 'Search for podcasts',
            button: true,
            onTap: handleSearch,
            child: ExcludeSemantics(
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: handleSearch,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Options menu',
          excludeFromSemantics: true,
          child: Semantics(
            label: 'Options menu',
            button: true,
            onTap: handleMenu,
            child: ExcludeSemantics(
              child: PopupMenuButton<int>(
                tooltip: null,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => const [],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
