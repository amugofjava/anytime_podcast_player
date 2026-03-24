// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/services/transcription/openai_episode_transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;

void main() {
  group('OpenAIEpisodeTranscriptionService', () {
    test('uploads audio and parses an SRT transcript', () async {
      final tempDir = await Directory.systemTemp.createTemp('openai-transcription-test');
      final audioFile = File(path.join(tempDir.path, 'episode.mp3'));
      await audioFile.writeAsBytes(<int>[1, 2, 3, 4]);
      final preparedAudioFile = File(path.join(tempDir.path, 'prepared.m4a'));
      await preparedAudioFile.writeAsBytes(<int>[4, 3, 2, 1]);

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://api.openai.com/v1/audio/transcriptions');
        expect(request.headers['authorization'], 'Bearer sk-test');
        expect(request.method, 'POST');

        return http.Response(
          '1\n00:00:00,000 --> 00:00:02,000\nHello from OpenAI',
          200,
          headers: const <String, String>{'content-type': 'text/plain'},
        );
      });

      final service = OpenAIEpisodeTranscriptionService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: client,
        audioPreparer: _FakeAudioPreparer.single(preparedAudioFile.path),
      );

      final transcript = await service.transcribeDownloadedEpisode(
        episode: Episode(
          guid: 'ep-openai-transcribe',
          podcast: 'Podcast',
          title: 'Episode',
          filepath: tempDir.path,
          filename: 'episode.mp3',
          contentUrl: 'https://cdn.example.com/episode.mp3',
        ),
      );

      expect(transcript.provenance, TranscriptProvenance.openAi);
      expect(transcript.provider, 'whisper-1');
      expect(transcript.subtitles, hasLength(1));
      expect(transcript.subtitles.single.data, 'Hello from OpenAI');
    });

    test('requires an API key before submission', () async {
      final tempDir = await Directory.systemTemp.createTemp('openai-transcription-test');
      final audioFile = File(path.join(tempDir.path, 'episode.mp3'));
      await audioFile.writeAsBytes(<int>[1, 2, 3, 4]);
      final preparedAudioFile = File(path.join(tempDir.path, 'prepared.m4a'));
      await preparedAudioFile.writeAsBytes(<int>[4, 3, 2, 1]);

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final service = OpenAIEpisodeTranscriptionService(
        secureSecretsService: _FakeSecureSecretsService(),
        client: MockClient((request) async => http.Response('', 200)),
        audioPreparer: _FakeAudioPreparer.single(preparedAudioFile.path),
      );

      await expectLater(
        () => service.transcribeDownloadedEpisode(
          episode: Episode(
            guid: 'ep-no-key',
            podcast: 'Podcast',
            title: 'Episode',
            filepath: tempDir.path,
            filename: 'episode.mp3',
            contentUrl: 'https://cdn.example.com/episode.mp3',
          ),
        ),
        throwsA(
          isA<EpisodeTranscriptionException>().having(
            (error) => error.message,
            'message',
            'OpenAI API key is not configured. Add it in Settings > AI.',
          ),
        ),
      );
    });

    test('maps 429 failures to a readable error', () async {
      final tempDir = await Directory.systemTemp.createTemp('openai-transcription-test');
      final audioFile = File(path.join(tempDir.path, 'episode.mp3'));
      await audioFile.writeAsBytes(<int>[1, 2, 3, 4]);
      final preparedAudioFile = File(path.join(tempDir.path, 'prepared.m4a'));
      await preparedAudioFile.writeAsBytes(<int>[4, 3, 2, 1]);

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final service = OpenAIEpisodeTranscriptionService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'error': <String, dynamic>{'message': 'Rate limit exceeded.'},
            }),
            429,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
        audioPreparer: _FakeAudioPreparer.single(preparedAudioFile.path),
      );

      await expectLater(
        () => service.transcribeDownloadedEpisode(
          episode: Episode(
            guid: 'ep-rate-limit',
            podcast: 'Podcast',
            title: 'Episode',
            filepath: tempDir.path,
            filename: 'episode.mp3',
            contentUrl: 'https://cdn.example.com/episode.mp3',
          ),
        ),
        throwsA(
          isA<EpisodeTranscriptionException>().having(
            (error) => error.message,
            'message',
            'OpenAI rate limit reached. Wait a moment and try again.',
          ),
        ),
      );
    });

    test('maps timeout failures to a readable error', () async {
      final tempDir = await Directory.systemTemp.createTemp('openai-transcription-test');
      final audioFile = File(path.join(tempDir.path, 'episode.mp3'));
      await audioFile.writeAsBytes(<int>[1, 2, 3, 4]);
      final preparedAudioFile = File(path.join(tempDir.path, 'prepared.m4a'));
      await preparedAudioFile.writeAsBytes(<int>[4, 3, 2, 1]);

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final service = OpenAIEpisodeTranscriptionService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async => throw TimeoutException('request timed out')),
        audioPreparer: _FakeAudioPreparer.single(preparedAudioFile.path),
      );

      await expectLater(
        () => service.transcribeDownloadedEpisode(
          episode: Episode(
            guid: 'ep-timeout',
            podcast: 'Podcast',
            title: 'Episode',
            filepath: tempDir.path,
            filename: 'episode.mp3',
            contentUrl: 'https://cdn.example.com/episode.mp3',
          ),
        ),
        throwsA(
          isA<EpisodeTranscriptionException>().having(
            (error) => error.message,
            'message',
            'OpenAI transcription timed out. Try again.',
          ),
        ),
      );
    });

    test('merges chunked transcripts with corrected timestamp offsets', () async {
      final tempDir = await Directory.systemTemp.createTemp('openai-transcription-test');
      final audioFile = File(path.join(tempDir.path, 'episode.mp3'));
      final chunkOne = File(path.join(tempDir.path, 'chunk-001.m4a'));
      final chunkTwo = File(path.join(tempDir.path, 'chunk-002.m4a'));
      await audioFile.writeAsBytes(<int>[1, 2, 3, 4]);
      await chunkOne.writeAsBytes(<int>[4, 3, 2, 1]);
      await chunkTwo.writeAsBytes(<int>[5, 6, 7, 8]);

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      var requestCount = 0;
      var disposed = false;

      final service = OpenAIEpisodeTranscriptionService(
        secureSecretsService: _FakeSecureSecretsService(apiKey: 'sk-test'),
        client: MockClient((request) async {
          requestCount += 1;

          if (requestCount == 1) {
            return http.Response(
              '1\n00:00:01,000 --> 00:00:03,000\nFirst chunk line',
              200,
              headers: const <String, String>{'content-type': 'text/plain'},
            );
          }

          return http.Response(
            '1\n00:00:02,500 --> 00:00:04,000\nSecond chunk line',
            200,
            headers: const <String, String>{'content-type': 'text/plain'},
          );
        }),
        audioPreparer: _FakeAudioPreparer(
          chunks: <PreparedOpenAiAudioChunk>[
            PreparedOpenAiAudioChunk(
              path: chunkOne.path,
              startOffset: Duration.zero,
            ),
            PreparedOpenAiAudioChunk(
              path: chunkTwo.path,
              startOffset: const Duration(minutes: 20),
            ),
          ],
          onDispose: () async {
            disposed = true;
          },
        ),
      );

      final transcript = await service.transcribeDownloadedEpisode(
        episode: Episode(
          guid: 'ep-chunked',
          podcast: 'Podcast',
          title: 'Episode',
          filepath: tempDir.path,
          filename: 'episode.mp3',
          contentUrl: 'https://cdn.example.com/episode.mp3',
        ),
      );

      expect(requestCount, 2);
      expect(disposed, isTrue);
      expect(transcript.subtitles, hasLength(2));
      expect(transcript.subtitles[0].index, 1);
      expect(transcript.subtitles[0].start, const Duration(seconds: 1));
      expect(transcript.subtitles[0].end, const Duration(seconds: 3));
      expect(transcript.subtitles[1].index, 2);
      expect(transcript.subtitles[1].start, const Duration(minutes: 20, milliseconds: 2500));
      expect(transcript.subtitles[1].end, const Duration(minutes: 20, seconds: 4));
      expect(transcript.subtitles[1].data, 'Second chunk line');
    });
  });
}

class _FakeSecureSecretsService implements SecureSecretsService {
  final String? apiKey;

  _FakeSecureSecretsService({
    this.apiKey,
  });

  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => apiKey;

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {}
}

class _FakeAudioPreparer implements OpenAiTranscriptionAudioPreparer {
  _FakeAudioPreparer({
    required this.chunks,
    this.onDispose,
  });

  factory _FakeAudioPreparer.single(String path) {
    return _FakeAudioPreparer(
      chunks: <PreparedOpenAiAudioChunk>[
        PreparedOpenAiAudioChunk(
          path: path,
          startOffset: Duration.zero,
        ),
      ],
    );
  }

  final List<PreparedOpenAiAudioChunk> chunks;
  final Future<void> Function()? onDispose;

  @override
  Future<PreparedOpenAiAudio> prepareForTranscription({
    required File inputFile,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    return PreparedOpenAiAudio(
      chunks: chunks,
      onDispose: onDispose,
    );
  }
}
