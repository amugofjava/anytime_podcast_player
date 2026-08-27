// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/audio/mp3_converter_service.dart';
import 'package:anytime/services/download/download_manager.dart';
import 'package:anytime/services/download/mobile_download_service.dart';
import 'package:anytime/services/podcast/mobile_podcast_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_notification_service.dart';
import '../mocks/mock_path_provider.dart';
import '../mocks/mock_podcast_api.dart';
import '../mocks/mock_settings_service.dart';

class _NoOpRunner implements AudioConverterRunner {
  @override
  Future<bool> run(List<String> args, {void Function(int percentage)? onProgress}) async => true;
}

/// Records calls to ensureMp3 so a test can assert whether conversion ran.
class _RecordingConverter extends Mp3ConverterService {
  final List<String> calls = [];

  _RecordingConverter() : super(_NoOpRunner());

  @override
  Future<String> ensureMp3(
    String sourcePath, {
    String? title,
    String? artist,
    String? album,
    String? year,
    void Function(int percentage)? onProgress,
  }) async {
    calls.add(sourcePath);
    return sourcePath;
  }
}

class _FakeDownloadManager implements DownloadManager {
  /// Public so a test can push progress into the service through the manager.
  final BehaviorSubject<DownloadProgress> progress = BehaviorSubject<DownloadProgress>();
  String? lastUrl;
  String? lastDownloadPath;
  String? lastFileName;

  @override
  Stream<DownloadProgress> get downloadProgress => progress;

  @override
  Future<String?> enqueueTask(String url, String downloadPath, String fileName) async {
    lastUrl = url;
    lastDownloadPath = downloadPath;
    lastFileName = fileName;
    return 'task1';
  }

  @override
  Future<void> pauseTask(String taskId) async {}

  @override
  Future<void> resumeTask(String taskId) async {}

  @override
  Future<void> cancelTask(String taskId) async {}

  @override
  Future<String?> retryTask(String taskId) async => 'task1';

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  PathProviderPlatform.instance = MockPathProvder();

  const dbName = 'anytime-download.db';
  final repository = SembastRepository(databaseName: dbName);
  final notificationService = MockNotificationService();
  final podcastService = MobilePodcastService(
    api: MockPodcastApi(),
    repository: repository,
    notificationService: notificationService,
    settingsService: MockSettingsService(),
  );
  final settings = MockSettingsService();
  final converter = _RecordingConverter();

  // A single service instance is reused across assertions because the static
  // downloadProgress subject can only be piped once.
  final manager = _FakeDownloadManager();
  final service = MobileDownloadService(
    repository: repository,
    downloadManager: manager,
    podcastService: podcastService,
    audioConverter: converter,
    settingsService: settings,
  );

  tearDown(() {
    final f = File('${Directory.systemTemp.path}/$dbName');
    if (f.existsSync()) f.deleteSync();
  });

  Future<void> readyEpisode(String taskId, String filename) async {
    await repository.saveEpisode(Episode(
      guid: 'EP_$taskId',
      podcast: 'Show',
      title: 'Episode',
      downloadTaskId: taskId,
      filepath: Directory.systemTemp.path,
      filename: filename,
    ));
    File('${Directory.systemTemp.path}/$filename').createSync();
  }

  test('MP3 conversion runs when convertToMp3 is enabled', () async {
    settings.convertToMp3 = true;
    await readyEpisode('task-on', 'episode.m4a');

    manager.progress.add(DownloadProgress('task-on', 100, DownloadState.downloaded));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(converter.calls, hasLength(1));
    expect(converter.calls.single, endsWith('episode.m4a'));
  });

  test('MP3 conversion is skipped when convertToMp3 is disabled', () async {
    settings.convertToMp3 = false;
    await readyEpisode('task-off', 'episode2.m4a');

    manager.progress.add(DownloadProgress('task-off', 100, DownloadState.downloaded));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(converter.calls, hasLength(1)); // only the previous 'task-on' call
  });

  test('downloadEpisode formats filename as YYYY-MM-DD_Title.mp3 and preserves Chinese characters', () async {
    final episode = Episode(
      guid: 'EP_chinese_test',
      podcast: '硅谷101',
      title: '第105期 具身智能的商业化黎明',
      contentUrl: 'https://example.com/audio/test.mp3',
      publicationDate: DateTime(2026, 8, 8),
    );

    final success = await service.downloadEpisode(episode);
    expect(success, isTrue);
    expect(manager.lastFileName, '2026-08-08_第105期 具身智能的商业化黎明.mp3');
    expect(manager.lastDownloadPath, contains('硅谷101'));
  });

  test('downloadEpisode downloads into custom download root directory under podcast subfolder', () async {
    final tempDir = Directory.systemTemp.createTempSync('custom_root_download');
    try {
      settings.customDownloadPath = tempDir.path;

      final episode = Episode(
        guid: 'EP_custom_dir_test',
        podcast: '声东击西',
        title: '何处安放的对话',
        contentUrl: 'https://example.com/audio/sondong.mp3',
        publicationDate: DateTime(2026, 8, 15),
      );

      final success = await service.downloadEpisode(episode);
      expect(success, isTrue);
      expect(manager.lastFileName, '2026-08-15_何处安放的对话.mp3');
      expect(manager.lastDownloadPath, '${tempDir.path}/声东击西');
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      settings.customDownloadPath = '';
    }
  });

  test('recoverUnfinishedTranscodes finishes converting episodes left in converting state', () async {
    settings.convertToMp3 = true;
    final tempDir = Directory.systemTemp.createTempSync('test_recover');
    final filename = '2026-08-16_第106期 具身智能续篇.m4a';
    final targetFile = File('${tempDir.path}/$filename');
    targetFile.createSync();

    final episode = Episode(
      guid: 'EP_recovering_test',
      podcast: '硅谷101',
      title: '第106期 具身智能续篇',
      contentUrl: 'https://example.com/audio/ep106.m4a',
      filename: filename,
      filepath: tempDir.path,
      downloadTaskId: 'task_recover_1',
      downloadState: DownloadState.converting,
    );

    try {
      await repository.saveEpisode(episode);
      converter.calls.clear();

      await service.recoverUnfinishedTranscodes();

      expect(converter.calls, isNotEmpty);
      final updated = await repository.findEpisodeByGuid('EP_recovering_test');
      expect(updated?.downloadState, DownloadState.downloaded);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('pause, resume, and cancel download state transitions', () async {
    final episode = Episode(
      guid: 'EP_control_test',
      podcast: '测试播客',
      title: '控制测试单集',
      contentUrl: 'https://example.com/audio/control.mp3',
      downloadTaskId: 'task_ctrl_1',
      downloadState: DownloadState.downloading,
      downloadPercentage: 45,
    );

    await repository.saveEpisode(episode);

    // Test pause
    await service.pauseDownload(episode);
    var updated = await repository.findEpisodeByGuid('EP_control_test');
    expect(updated?.downloadState, DownloadState.paused);

    // Test resume
    await service.resumeDownload(episode);
    updated = await repository.findEpisodeByGuid('EP_control_test');
    expect(updated?.downloadState, DownloadState.downloading);

    // Test cancel
    await service.cancelDownload(episode);
    updated = await repository.findEpisodeByGuid('EP_control_test');
    expect(updated?.downloadState, DownloadState.none);
    expect(updated?.downloadPercentage, 0);
  });

  test('findActiveDownloads returns episodes in active download states', () async {
    final ep1 = Episode(
      guid: 'EP_active_1',
      podcast: 'Active Podcast',
      title: 'Active Episode 1',
      downloadState: DownloadState.downloading,
    );
    final ep2 = Episode(
      guid: 'EP_active_2',
      podcast: 'Active Podcast',
      title: 'Active Episode 2',
      downloadState: DownloadState.converting,
    );
    final ep3 = Episode(
      guid: 'EP_active_3',
      podcast: 'Active Podcast',
      title: 'Active Episode 3',
      downloadState: DownloadState.paused,
    );
    final ep4 = Episode(
      guid: 'EP_inactive_4',
      podcast: 'Active Podcast',
      title: 'Inactive Episode 4',
      downloadState: DownloadState.none,
    );

    await repository.saveEpisode(ep1);
    await repository.saveEpisode(ep2);
    await repository.saveEpisode(ep3);
    await repository.saveEpisode(ep4);

    final activeList = await repository.findActiveDownloads();
    final guids = activeList.map((e) => e.guid).toSet();

    expect(guids.contains('EP_active_1'), isTrue);
    expect(guids.contains('EP_active_2'), isTrue);
    expect(guids.contains('EP_active_3'), isTrue);
    expect(guids.contains('EP_inactive_4'), isFalse);
  });

  tearDownAll(() {
    service.dispose();
  });
}
