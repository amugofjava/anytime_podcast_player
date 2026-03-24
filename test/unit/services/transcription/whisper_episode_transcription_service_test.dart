// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/services/transcription/whisper_episode_transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() {
  group('transcriptFromWhisperResponse', () {
    test('maps timestamped whisper segments into a local transcript', () {
      final transcript = transcriptFromWhisperResponse(
        const WhisperTranscribeResponse(
          type: 'transcribe',
          text: 'Hello world',
          segments: <WhisperTranscribeSegment>[
            WhisperTranscribeSegment(
              fromTs: Duration.zero,
              toTs: Duration(seconds: 2),
              text: ' Hello ',
            ),
            WhisperTranscribeSegment(
              fromTs: Duration(seconds: 2),
              toTs: Duration(seconds: 5),
              text: 'world',
            ),
          ],
        ),
      );

      expect(transcript.provenance, TranscriptProvenance.localAi);
      expect(transcript.provider, 'whisper');
      expect(transcript.subtitles, hasLength(2));
      expect(transcript.subtitles.first.data, 'Hello');
      expect(transcript.subtitles.last.start, const Duration(seconds: 2));
      expect(transcript.subtitles.last.end, const Duration(seconds: 5));
    });

    test('rejects responses without timestamped segments', () {
      expect(
        () => transcriptFromWhisperResponse(
          const WhisperTranscribeResponse(
            type: 'transcribe',
            text: 'Hello world',
            segments: <WhisperTranscribeSegment>[],
          ),
        ),
        throwsA(
          isA<EpisodeTranscriptionException>().having(
            (error) => error.message,
            'message',
            'Whisper transcription did not return timestamped segments.',
          ),
        ),
      );
    });
  });
}
