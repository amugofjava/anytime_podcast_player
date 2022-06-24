// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/repository/repository.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/podcast/mobile_opml_service.dart';
import 'package:anytime/services/podcast/mobile_podcast_service.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../mocks/mock_path_provider.dart';
import '../mocks/mock_podcast_api.dart';

void main() {
  final api = MockPodcastApi();
  final mockPath = MockPathProvder();
  final dbName = 'anytime-opml.db';
  OPMLService opmlService;
  PodcastService podcastService;
  Repository repository;

  setUp(() async {
    PathProviderPlatform.instance = mockPath;
    repository = SembastRepository(databaseName: dbName);

    podcastService = MobilePodcastService(
      api: api,
      repository: repository,
      settingsService: null,
    );

    opmlService = MobileOPMLService(podcastService: podcastService, repository: repository);
  });

  tearDown(() async {
    var f = File('${Directory.systemTemp.path}/$dbName');

    if (f.existsSync()) {
      f.deleteSync();
    }
  });

  test('Load test OPML file. Single Podcast. Single episode.', () async {
    var stream = opmlService.loadOPMLFile('test_resources/opml_import_test1.opml');

    await expectLater(
        stream,
        emitsInOrder(<Matcher>[
          emits(isInstanceOf<OPMLParsingState>()),
          emits(isInstanceOf<OPMLLoadingState>()),
          emits(isInstanceOf<OPMLCompletedState>()),
        ]));

    var subs = await podcastService.subscriptions();

    expect(subs?.length, 1);
    expect(subs[0].title, 'Podcast Load Test 1');
    expect(subs[0].url, 'test_resources/podcast1.rss');
  });
}
