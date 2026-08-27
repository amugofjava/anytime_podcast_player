import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_settings_service.dart';

void main() {
  group('safePath and safeFile Unicode & Chinese tests', () {
    test('safePath preserves Chinese and alphanumeric characters', () {
      expect(safePath('硅谷101'), '硅谷101');
      expect(safePath('声东击西'), '声东击西');
      expect(safePath('HardHacker 硬地骇客'), 'HardHacker 硬地骇客');
      expect(safePath('日谈公园'), '日谈公园');
    });

    test('safePath replaces filesystem reserved characters', () {
      expect(safePath('硅谷: 101/创新*探索?'), '硅谷_ 101_创新_探索_');
      expect(safePath('Test <one> | "two"'), 'Test _one_ _ _two_');
    });

    test('safePath handles empty or whitespace strings', () {
      expect(safePath(null), isNull);
      expect(safePath('   '), 'Unknown');
      expect(safePath(':::'), 'Unknown');
    });

    test('safeFile preserves Chinese and cleans illegal characters', () {
      expect(safeFile('第105期 具身智能的商业化黎明'), '第105期 具身智能的商业化黎明');
      expect(safeFile('硅谷101/第120期: 专访?'), '硅谷101_第120期_ 专访_');
      expect(safeFile('   '), 'episode');
      expect(safeFile(null), isNull);
    });
  });

  group('Storage directory resolution tests', () {
    test('getStorageDirectory returns custom download path when configured', () async {
      final tempDir = Directory.systemTemp.createTempSync('custom_pod_test');
      try {
        final mockSettings = MockSettingsService();
        mockSettings.customDownloadPath = tempDir.path;

        final dir = await getStorageDirectory(settingsService: mockSettings);
        expect(dir, tempDir.path);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('resolveDirectory places episode in podcast-titled subfolder under custom path', () async {
      final tempDir = Directory.systemTemp.createTempSync('custom_pod_test2');
      try {
        final mockSettings = MockSettingsService();
        mockSettings.customDownloadPath = tempDir.path;

        final episode = Episode(
          guid: 'ep_test_subfolder',
          podcast: '硅谷101',
          title: '第105期 具身智能',
        );

        final resolved = await resolveDirectory(episode: episode, full: true, settingsService: mockSettings);
        expect(resolved, contains(tempDir.path));
        expect(resolved, contains('硅谷101'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
