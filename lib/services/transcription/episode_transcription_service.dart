// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';

enum EpisodeTranscriptionStage {
  preparing,
  uploading,
  downloadingModel,
  transcribing,
  completed,
}

class EpisodeTranscriptionProgress {
  final EpisodeTranscriptionStage stage;
  final String message;
  final double? progress;

  const EpisodeTranscriptionProgress({
    required this.stage,
    required this.message,
    this.progress,
  });

  bool get isIndeterminate => progress == null;
}

abstract class EpisodeTranscriptionService {
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  });
}

class DisabledEpisodeTranscriptionService implements EpisodeTranscriptionService {
  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) {
    throw const EpisodeTranscriptionException(
      'Local AI transcription is not configured in this build.',
    );
  }
}

class EpisodeTranscriptionException implements Exception {
  final String message;

  const EpisodeTranscriptionException(this.message);

  @override
  String toString() => 'EpisodeTranscriptionException($message)';
}
