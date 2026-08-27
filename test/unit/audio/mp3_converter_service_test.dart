// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/services/audio/mp3_converter_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [AudioConverterRunner] that either creates the output file (simulating
/// a successful conversion) or reports failure.
class _FakeRunner implements AudioConverterRunner {
  final bool succeed;
  final List<List<String>> calls = [];
  final int progressToReport;

  _FakeRunner({this.succeed = true, this.progressToReport = -1});

  @override
  Future<bool> run(List<String> args, {void Function(int percentage)? onProgress}) async {
    calls.add(args);
    if (progressToReport >= 0 && onProgress != null) {
      onProgress(progressToReport);
    }
    if (succeed) {
      // The target path is the last argument; create it to simulate output.
      File(args.last).createSync(recursive: true);
      return true;
    }
    return false;
  }
}

class _ThrowingRunner implements AudioConverterRunner {
  @override
  Future<bool> run(List<String> args, {void Function(int percentage)? onProgress}) async =>
      throw Exception('ffmpeg boom');
}

void main() {
  group('isMp3Extension', () {
    test('returns true for .mp3 (case-insensitive)', () {
      expect(isMp3Extension('/a/b/episode.mp3'), isTrue);
      expect(isMp3Extension('/a/b/episode.MP3'), isTrue);
    });

    test('returns false for non-mp3 audio and no extension', () {
      expect(isMp3Extension('/a/b/episode.m4a'), isFalse);
      expect(isMp3Extension('/a/b/episode.aac'), isFalse);
      expect(isMp3Extension('/a/b/episode.wav'), isFalse);
      expect(isMp3Extension('/a/b/episode'), isFalse);
    });
  });

  group('mp3TargetPath', () {
    test('replaces the existing extension with .mp3', () {
      expect(mp3TargetPath('/a/b/episode.m4a'), '/a/b/episode.mp3');
      expect(mp3TargetPath('/a/b/e.aac'), '/a/b/e.mp3');
    });
  });

  group('buildMp3ConversionArgs', () {
    test('builds ffmpeg args transcoding to mp3 with id3 defaults', () {
      final args = buildMp3ConversionArgs('/in.m4a', '/out.mp3');
      expect(args, [
        '-i',
        '/in.m4a',
        '-vn',
        '-acodec',
        'libmp3lame',
        '-b:a',
        '192k',
        '-id3v2_version',
        '3',
        '-write_id3v1',
        '1',
        '-y',
        '/out.mp3',
      ]);
    });

    test('embeds title, artist, album, date metadata into ffmpeg arguments', () {
      final args = buildMp3ConversionArgs(
        '/in.m4a',
        '/out.mp3',
        title: '第105期 具身智能',
        artist: '硅谷101',
        album: '硅谷101',
        year: '2026',
      );
      expect(args, contains('-metadata'));
      expect(args, contains('title=第105期 具身智能'));
      expect(args, contains('artist=硅谷101'));
      expect(args, contains('album=硅谷101'));
      expect(args, contains('date=2026'));
      expect(args, contains('-id3v2_version'));
      expect(args, contains('3'));
    });
  });

  group('Mp3ConverterService.ensureMp3', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('mp3test'));

    tearDown(() => tmp.deleteSync(recursive: true));

    test('returns the same path for an mp3 file without calling the runner', () async {
      final runner = _FakeRunner();
      final svc = Mp3ConverterService(runner);
      final p = '${tmp.path}/episode.mp3';
      File(p).createSync();

      expect(await svc.ensureMp3(p), p);
      expect(runner.calls, isEmpty);
    });

    test('converts a non-mp3 file, deletes the original, returns the mp3 path', () async {
      final runner = _FakeRunner();
      final svc = Mp3ConverterService(runner);
      final src = '${tmp.path}/episode.m4a';
      File(src).createSync();

      final result = await svc.ensureMp3(src);

      expect(result, '${tmp.path}/episode.mp3');
      expect(File(result).existsSync(), isTrue);
      expect(File(src).existsSync(), isFalse);
      expect(runner.calls, hasLength(1));
    });

    test('keeps the original file when conversion reports failure', () async {
      final runner = _FakeRunner(succeed: false);
      final svc = Mp3ConverterService(runner);
      final src = '${tmp.path}/episode.m4a';
      File(src).createSync();

      expect(await svc.ensureMp3(src), src);
      expect(File(src).existsSync(), isTrue);
    });

    test('keeps the original file when the runner throws', () async {
      final runner = _ThrowingRunner();
      final svc = Mp3ConverterService(runner);
      final src = '${tmp.path}/episode.m4a';
      File(src).createSync();

      expect(await svc.ensureMp3(src), src);
      expect(File(src).existsSync(), isTrue);
    });

    test('ensureMp3 passes metadata and triggers onProgress callback', () async {
      final runner = _FakeRunner(succeed: true, progressToReport: 45);
      final svc = Mp3ConverterService(runner);
      final src = '${tmp.path}/episode.m4a';
      File(src).createSync();

      int reportedProgress = 0;
      final result = await svc.ensureMp3(
        src,
        title: '硅谷101专访',
        artist: '硅谷101',
        album: '硅谷101',
        year: '2026',
        onProgress: (p) => reportedProgress = p,
      );

      expect(result, '${tmp.path}/episode.mp3');
      expect(reportedProgress, 45);
      expect(runner.calls.first, contains('title=硅谷101专访'));
      expect(runner.calls.first, contains('artist=硅谷101'));
    });
  });
}
