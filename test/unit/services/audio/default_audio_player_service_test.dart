// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/audio/default_audio_player_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadPreferredPlaybackTranscript', () {
    test('prefers stored transcript over remote feed transcript for streaming episodes', () async {
      final repository = _TranscriptRepository();
      final storedTranscript = Transcript(
        id: 10,
        guid: 'ep-1',
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 1),
            data: 'Stored transcript',
          ),
        ],
      );

      repository.transcriptsById[10] = storedTranscript;

      final episode = Episode(
        guid: 'ep-1',
        podcast: 'Podcast',
        transcriptId: 10,
        transcriptUrls: <TranscriptUrl>[
          TranscriptUrl(url: 'https://cdn.example.com/episode.srt', type: TranscriptFormat.subrip),
        ],
      );

      var remoteCalls = 0;

      final transcript = await loadPreferredPlaybackTranscript(
        episode: episode,
        repository: repository,
        loadRemoteTranscript: (transcriptUrl) async {
          remoteCalls++;
          return Transcript();
        },
      );

      expect(transcript, same(storedTranscript));
      expect(remoteCalls, 0);
    });

    test('falls back to remote transcript for streaming episodes when stored transcript is missing', () async {
      final repository = _TranscriptRepository();
      final episode = Episode(
        guid: 'ep-2',
        podcast: 'Podcast',
        transcriptId: 55,
        transcriptUrls: <TranscriptUrl>[
          TranscriptUrl(url: 'https://cdn.example.com/episode.vtt', type: TranscriptFormat.vtt),
          TranscriptUrl(url: 'https://cdn.example.com/episode.srt', type: TranscriptFormat.subrip),
        ],
      );

      late TranscriptUrl requestedUrl;

      final transcript = await loadPreferredPlaybackTranscript(
        episode: episode,
        repository: repository,
        loadRemoteTranscript: (transcriptUrl) async {
          requestedUrl = transcriptUrl;
          return Transcript(
            subtitles: <Subtitle>[
              Subtitle(
                index: 1,
                start: Duration.zero,
                end: const Duration(seconds: 1),
                data: 'Remote transcript',
              ),
            ],
          );
        },
      );

      expect(requestedUrl.type, TranscriptFormat.vtt);
      expect(transcript!.subtitles.single.data, 'Remote transcript');
    });

    test('does not fetch remote transcripts for downloaded episodes without a stored transcript', () async {
      final repository = _TranscriptRepository();
      final episode = Episode(
        guid: 'ep-3',
        podcast: 'Podcast',
        transcriptUrls: <TranscriptUrl>[
          TranscriptUrl(url: 'https://cdn.example.com/episode.srt', type: TranscriptFormat.subrip),
        ],
      )..streaming = false;

      var remoteCalls = 0;

      final transcript = await loadPreferredPlaybackTranscript(
        episode: episode,
        repository: repository,
        loadRemoteTranscript: (transcriptUrl) async {
          remoteCalls++;
          return Transcript();
        },
      );

      expect(transcript, isNull);
      expect(remoteCalls, 0);
    });
  });
}

class _TranscriptRepository implements Repository {
  final Map<int, Transcript> transcriptsById = <int, Transcript>{};

  @override
  Future<Transcript?> findTranscriptById(int id) async => transcriptsById[id];

  @override
  Stream<Podcast> get podcastListener => Stream<Podcast>.empty();

  @override
  Stream<EpisodeState> get episodeListener => Stream<EpisodeState>.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
