// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/expressive_linear_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EpisodeTileSubtitle shows determinate download progress for active downloads', (tester) async {
    final episode = Episode(
      guid: 'ep-progress',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Downloading episode',
      publicationDate: DateTime(2026, 3, 25),
      duration: 1800,
      downloadState: DownloadState.downloading,
      downloadPercentage: 42,
    );

    await tester.pumpWidget(_wrapSubtitle(EpisodeTileSubtitle(episode)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('42%'), findsOneWidget);
    expect(find.byType(ExpressiveLinearProgressIndicator), findsOneWidget);
  });

  testWidgets('EpisodeTileSubtitle shows indeterminate progress for queued downloads', (tester) async {
    final episode = Episode(
      guid: 'ep-queued',
      pguid: 'pod-1',
      podcast: 'Podcast',
      title: 'Queued episode',
      publicationDate: DateTime(2026, 3, 25),
      duration: 1800,
      downloadState: DownloadState.queued,
      downloadPercentage: 0,
    );

    await tester.pumpWidget(_wrapSubtitle(EpisodeTileSubtitle(episode)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}

Widget _wrapSubtitle(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AnytimeLocalisationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
    ],
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    ),
  );
}
