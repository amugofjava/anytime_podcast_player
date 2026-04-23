// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class WhisperEpisodeTranscriptionService implements EpisodeTranscriptionService {
  WhisperEpisodeTranscriptionService({
    WhisperModel model = WhisperModel.tinyEn,
  }) : _model = model;

  final WhisperModel _model;
  final Lock _modelDownloadLock = Lock();
  static final _log = Logger('WhisperEpisodeTranscriptionService');

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      throw const EpisodeTranscriptionException(
        'Local AI transcription is only supported on Android, iOS, and macOS.',
      );
    }

    onProgress?.call(const EpisodeTranscriptionProgress(
      stage: EpisodeTranscriptionStage.preparing,
      message: 'Preparing local audio...',
    ));

    final audioPath = await resolvePath(episode);
    final audioFile = File(audioPath);

    if (!audioFile.existsSync()) {
      throw EpisodeTranscriptionException(
        'Downloaded audio file is missing: $audioPath',
      );
    }

    final modelPath = await _ensureModelDownloaded(onProgress: onProgress);

    onProgress?.call(const EpisodeTranscriptionProgress(
      stage: EpisodeTranscriptionStage.transcribing,
      message: 'Transcribing audio on this device...',
    ));

    final stagedPath = await _stageAudioForWhisper(audioFile);

    final stopwatch = Stopwatch()..start();
    final audioSeconds = _audioDurationSeconds(episode);
    final heartbeat = Timer.periodic(const Duration(seconds: 3), (_) {
      final elapsed = stopwatch.elapsed;
      final pct = _estimateProgress(elapsed, audioSeconds);
      onProgress?.call(EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.transcribing,
        message: _heartbeatMessage(elapsed, audioSeconds),
        progress: pct,
      ));
    });

    try {
      final response = await Whisper(model: _model).transcribe(
        transcribeRequest: TranscribeRequest(
          audio: stagedPath,
          language: 'auto',
          isNoTimestamps: false,
          isTranslate: false,
          splitOnWord: false,
        ),
        modelPath: modelPath,
      );

      final transcript = transcriptFromWhisperResponse(response);
      transcript.provider = 'whisper';

      onProgress?.call(EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.completed,
        message: 'Transcript ready after ${_formatDuration(stopwatch.elapsed)}.',
        progress: 1.0,
      ));

      return transcript;
    } catch (error) {
      throw EpisodeTranscriptionException(
        'Local AI transcription failed: $error',
      );
    } finally {
      heartbeat.cancel();
      stopwatch.stop();
      await _cleanupStaging(stagedPath);
    }
  }

  /// The Episode.duration field is in seconds when populated from RSS feeds
  /// (either raw seconds or HH:MM:SS parsed to seconds). Returns null when we
  /// can't trust the value so the heartbeat falls back to an elapsed-only view.
  int? _audioDurationSeconds(Episode episode) {
    final d = episode.duration;
    if (d <= 0) return null;
    // Guard against the rare case where a feed reports milliseconds. Anything
    // above ~24h in seconds is almost certainly ms, so divide.
    return d > 24 * 3600 ? d ~/ 1000 : d;
  }

  /// Rough progress estimate. The `base` whisper.cpp model on modern Android
  /// hardware runs ~2x realtime, so we assume the job takes ~audio/2 seconds
  /// and cap at 95% until the real response arrives.
  double? _estimateProgress(Duration elapsed, int? audioSeconds) {
    if (audioSeconds == null || audioSeconds <= 0) return null;
    final expected = audioSeconds / 2;
    final pct = elapsed.inSeconds / expected;
    if (pct <= 0) return 0;
    if (pct >= 0.95) return 0.95;
    return pct;
  }

  String _heartbeatMessage(Duration elapsed, int? audioSeconds) {
    final elapsedStr = _formatDuration(elapsed);
    if (audioSeconds == null) {
      return 'Transcribing audio ($elapsedStr elapsed)…';
    }
    final expectedSeconds = audioSeconds ~/ 2;
    final expectedStr = _formatDuration(Duration(seconds: expectedSeconds));
    return 'Transcribing audio — $elapsedStr elapsed / ~$expectedStr expected';
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h${m.toString().padLeft(2, '0')}m${s.toString().padLeft(2, '0')}s';
    }
    if (m > 0) {
      return '${m}m${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  /// Copy or symlink the episode audio into a space-free cache path so that
  /// whisper_ggml's internal ffmpeg conversion does not mis-parse the command
  /// line. whisper_ggml-1.7.0 joins ffmpeg args with a single space, which
  /// breaks on any audio path containing whitespace (e.g. a podcast folder
  /// named "Good Hang with Amy Poehler").
  Future<String> _stageAudioForWhisper(File audioFile) async {
    final tempDir = await getTemporaryDirectory();
    final stagingDir = Directory(path.join(tempDir.path, 'whisper_staging'));
    if (!stagingDir.existsSync()) {
      await stagingDir.create(recursive: true);
    }

    final ext = path.extension(audioFile.path);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final stagedPath = path.join(stagingDir.path, 'episode_$stamp$ext');

    if (stagedPath.contains(' ')) {
      throw EpisodeTranscriptionException(
        'Unable to stage audio at a space-free path: $stagedPath',
      );
    }

    try {
      await Link(stagedPath).create(audioFile.path);
      _log.fine('Staged audio via symlink: $stagedPath -> ${audioFile.path}');
    } catch (linkError) {
      _log.info('Symlink failed ($linkError); copying audio to $stagedPath');
      await audioFile.copy(stagedPath);
    }
    return stagedPath;
  }

  Future<void> _cleanupStaging(String stagedPath) async {
    final convertedAudio = File('$stagedPath.wav');
    if (convertedAudio.existsSync()) {
      try {
        await convertedAudio.delete();
      } catch (error) {
        _log.warning('Failed to delete converted WAV $convertedAudio: $error');
      }
    }

    final link = Link(stagedPath);
    if (link.existsSync()) {
      try {
        await link.delete();
        return;
      } catch (error) {
        _log.warning('Failed to delete staging symlink $stagedPath: $error');
      }
    }

    final stagedFile = File(stagedPath);
    if (stagedFile.existsSync()) {
      try {
        await stagedFile.delete();
      } catch (error) {
        _log.warning('Failed to delete staged audio $stagedPath: $error');
      }
    }
  }

  Future<String> _ensureModelDownloaded({
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    return _modelDownloadLock.synchronized(() async {
      final modelDirectory = await _modelDirectory();
      final modelPath = path.join(modelDirectory.path, 'ggml-${_model.modelName}.bin');
      final modelFile = File(modelPath);

      if (modelFile.existsSync() && modelFile.lengthSync() > 0) {
        return modelPath;
      }

      await modelDirectory.create(recursive: true);

      final partialPath = '$modelPath.part';
      final partialFile = File(partialPath);

      if (partialFile.existsSync()) {
        await partialFile.delete();
      }

      final client = HttpClient()..userAgent = 'Anytime Podcast Player';

      try {
        onProgress?.call(const EpisodeTranscriptionProgress(
          stage: EpisodeTranscriptionStage.downloadingModel,
          message: 'Downloading Whisper model...',
          progress: 0.0,
        ));

        final request = await client.getUrl(_model.modelUri);
        final response = await request.close();

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw EpisodeTranscriptionException(
            'Model download failed with status ${response.statusCode}.',
          );
        }

        final contentLength = response.contentLength;
        final sink = partialFile.openWrite();
        var downloaded = 0;

        await for (final chunk in response) {
          sink.add(chunk);
          downloaded += chunk.length;

          onProgress?.call(EpisodeTranscriptionProgress(
            stage: EpisodeTranscriptionStage.downloadingModel,
            message: 'Downloading Whisper model...',
            progress: contentLength > 0 ? downloaded / contentLength : null,
          ));
        }

        await sink.close();

        if (modelFile.existsSync()) {
          await modelFile.delete();
        }

        await partialFile.rename(modelPath);
        return modelPath;
      } catch (error) {
        if (partialFile.existsSync()) {
          await partialFile.delete();
        }

        if (error is EpisodeTranscriptionException) {
          rethrow;
        }

        throw EpisodeTranscriptionException(
          'Unable to download the Whisper model: $error',
        );
      } finally {
        client.close(force: true);
      }
    });
  }

  Future<Directory> _modelDirectory() async {
    if (Platform.isAndroid) {
      return getApplicationSupportDirectory();
    }

    return getLibraryDirectory();
  }
}

@visibleForTesting
Transcript transcriptFromWhisperResponse(WhisperTranscribeResponse response) {
  final segments = response.segments;

  if (segments == null || segments.isEmpty) {
    throw const EpisodeTranscriptionException(
      'Whisper transcription did not return timestamped segments.',
    );
  }

  final subtitles = <Subtitle>[];

  for (var index = 0; index < segments.length; index++) {
    final segment = segments[index];
    final text = segment.text.trim();

    if (text.isEmpty) {
      continue;
    }

    final end = segment.toTs > segment.fromTs ? segment.toTs : segment.fromTs + const Duration(milliseconds: 500);

    subtitles.add(Subtitle(
      index: index + 1,
      start: segment.fromTs,
      end: end,
      data: text,
    ));
  }

  if (subtitles.isEmpty) {
    throw const EpisodeTranscriptionException(
      'Whisper transcription did not return any usable transcript segments.',
    );
  }

  return Transcript(
    subtitles: List<Subtitle>.unmodifiable(subtitles),
    provenance: TranscriptProvenance.localAi,
    provider: 'whisper',
  );
}
