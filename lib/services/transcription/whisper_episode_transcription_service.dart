// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class WhisperEpisodeTranscriptionService implements EpisodeTranscriptionService {
  WhisperEpisodeTranscriptionService({
    WhisperModel model = WhisperModel.base,
  }) : _model = model;

  final WhisperModel _model;
  final Lock _modelDownloadLock = Lock();

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

    try {
      final response = await Whisper(model: _model).transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'auto',
          isNoTimestamps: false,
          isTranslate: false,
          splitOnWord: false,
        ),
        modelPath: modelPath,
      );

      final transcript = transcriptFromWhisperResponse(response);
      transcript.provider = 'whisper';

      onProgress?.call(const EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.completed,
        message: 'Transcript ready.',
        progress: 1.0,
      ));

      return transcript;
    } catch (error) {
      throw EpisodeTranscriptionException(
        'Local AI transcription failed: $error',
      );
    } finally {
      final convertedAudio = File('$audioPath.wav');

      if (convertedAudio.existsSync()) {
        await convertedAudio.delete();
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
