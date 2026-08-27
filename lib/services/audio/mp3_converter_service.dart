// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Utilities for converting downloaded podcast audio to the MP3 format.
library;

import 'dart:io' show File;

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Returns true if [path] already points to an MP3 file (by extension,
/// case-insensitive).
bool isMp3Extension(String path) => p.extension(path).toLowerCase() == '.mp3';

/// Returns the path where the MP3 counterpart of [sourcePath] would live,
/// replacing the existing extension with `.mp3`.
///
/// e.g. `/a/b/episode.m4a` -> `/a/b/episode.mp3`
String mp3TargetPath(String sourcePath) {
  final ext = p.extension(sourcePath);
  return '${sourcePath.substring(0, sourcePath.length - ext.length)}.mp3';
}

/// Builds the ffmpeg arguments used to transcode [source] into an MP3 at
/// [target]. Uses the LAME encoder at a fixed 192kbps, keeps audio only and
/// overwrites any existing output. Keeping this as a pure function makes it
/// straightforward to unit test without a real ffmpeg binary.
List<String> buildMp3ConversionArgs(
  String source,
  String target, {
  String? title,
  String? artist,
  String? album,
  String? year,
}) {
  final args = [
    '-i',
    source,
    '-vn',
    '-acodec',
    'libmp3lame',
    '-b:a',
    '192k',
  ];

  if (title != null && title.trim().isNotEmpty) {
    args.addAll(['-metadata', 'title=${title.trim()}']);
  }
  if (artist != null && artist.trim().isNotEmpty) {
    args.addAll(['-metadata', 'artist=${artist.trim()}']);
  }
  if (album != null && album.trim().isNotEmpty) {
    args.addAll(['-metadata', 'album=${album.trim()}']);
  }
  if (year != null && year.trim().isNotEmpty) {
    args.addAll(['-metadata', 'date=${year.trim()}']);
  }

  args.addAll([
    '-id3v2_version',
    '3',
    '-write_id3v1',
    '1',
    '-y',
    target,
  ]);

  return args;
}

/// Executes an ffmpeg conversion. Abstracted behind an interface so the rest of
/// the code (and the tests) never need to touch the native ffmpeg plugin.
abstract class AudioConverterRunner {
  /// Runs ffmpeg with [args] and returns true on success.
  Future<bool> run(List<String> args, {void Function(int percentage)? onProgress});
}

/// Ensures a downloaded audio file is an MP3, converting it when necessary.
///
/// This is the single place the app decides whether and how to transcode a
/// downloaded episode to MP3. It keeps the pure logic ([isMp3Extension],
/// [mp3TargetPath], [buildMp3ConversionArgs]) separate from the actual
/// ffmpeg invocation ([AudioConverterRunner]).
class Mp3ConverterService {
  final AudioConverterRunner _runner;
  final Logger _log = Logger('Mp3ConverterService');

  Mp3ConverterService(this._runner);

  /// If [sourcePath] is not already an MP3, transcodes it to MP3 and removes
  /// the original file. Returns the path of an MP3 file: the converted one on
  /// success, otherwise the original (unchanged) path.
  Future<String> ensureMp3(
    String sourcePath, {
    String? title,
    String? artist,
    String? album,
    String? year,
    void Function(int percentage)? onProgress,
  }) async {
    if (isMp3Extension(sourcePath)) {
      return sourcePath;
    }

    final targetPath = mp3TargetPath(sourcePath);
    _log.fine('Converting non-MP3 file $sourcePath -> $targetPath (title: $title, artist: $artist)');

    try {
      final args = buildMp3ConversionArgs(
        sourcePath,
        targetPath,
        title: title,
        artist: artist,
        album: album,
        year: year,
      );
      final ok = await _runner.run(args, onProgress: onProgress);
      if (ok && File(targetPath).existsSync()) {
        // The MP3 is complete, so the original is no longer needed. Removing it
        // is best-effort; a failure here should not fail the download.
        try {
          File(sourcePath).deleteSync();
        } catch (_) {}
        _log.fine('Converted $sourcePath -> $targetPath');
        return targetPath;
      }
      _log.warning('MP3 conversion returned failure for $sourcePath');
    } catch (e, s) {
      _log.warning('MP3 conversion error for $sourcePath', e, s);
    }

    return sourcePath;
  }
}
