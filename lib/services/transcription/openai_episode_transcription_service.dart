// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:anytime/core/environment.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:anytime/services/analysis/episode_analysis_transcript_codec.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

class ConfigurableEpisodeTranscriptionService implements EpisodeTranscriptionService {
  ConfigurableEpisodeTranscriptionService({
    required this.settingsService,
    required this.secureSecretsService,
    EpisodeTranscriptionService? localService,
    OpenAIEpisodeTranscriptionService? openAiService,
  })  : _localService = localService ?? DisabledEpisodeTranscriptionService(),
        _openAiService = openAiService ??
            OpenAIEpisodeTranscriptionService(
              secureSecretsService: secureSecretsService,
            );

  final SettingsService settingsService;
  final SecureSecretsService secureSecretsService;
  final EpisodeTranscriptionService _localService;
  final OpenAIEpisodeTranscriptionService _openAiService;

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) {
    switch (settingsService.transcriptionProvider) {
      case TranscriptionProvider.localAi:
        return _localService.transcribeDownloadedEpisode(
          episode: episode,
          onProgress: onProgress,
        );
      case TranscriptionProvider.openAi:
        return _openAiService.transcribeDownloadedEpisode(
          episode: episode,
          onProgress: onProgress,
        );
    }
  }
}

class OpenAIEpisodeTranscriptionService implements EpisodeTranscriptionService {
  OpenAIEpisodeTranscriptionService({
    required this.secureSecretsService,
    http.Client? client,
    String model = 'whisper-1',
    Uri? baseUri,
    OpenAiTranscriptionAudioPreparer? audioPreparer,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _model = model,
        _baseUri = baseUri ?? Uri.parse('https://api.openai.com/v1/'),
        _audioPreparer = audioPreparer ?? DefaultOpenAiTranscriptionAudioPreparer();

  // Upload + server-side transcription for long episodes regularly exceeds 90s.
  static const _requestTimeout = Duration(minutes: 10);
  static final _log = Logger('OpenAIEpisodeTranscriptionService');

  final SecureSecretsService secureSecretsService;
  final http.Client _client;
  final bool _ownsClient;
  final String _model;
  final Uri _baseUri;
  final OpenAiTranscriptionAudioPreparer _audioPreparer;

  @override
  Future<Transcript> transcribeDownloadedEpisode({
    required Episode episode,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    _log.fine('Starting OpenAI transcription for ${episode.guid}');

    onProgress?.call(const EpisodeTranscriptionProgress(
      stage: EpisodeTranscriptionStage.preparing,
      message: 'Preparing audio for OpenAI transcription...',
    ));

    final audioPath = await resolvePath(episode);
    final audioFile = File(audioPath);

    if (!audioFile.existsSync()) {
      _log.warning('Downloaded audio file is missing for ${episode.guid}: $audioPath');
      throw EpisodeTranscriptionException(
        'Downloaded audio file is missing: $audioPath',
      );
    }

    _log.fine('Resolved source audio for ${episode.guid}: $audioPath (${audioFile.lengthSync()} bytes)');

    final apiKey = (await secureSecretsService.read(openAiApiKeySecret))?.trim() ?? '';

    if (apiKey.isEmpty) {
      _log.warning('OpenAI API key missing for ${episode.guid}');
      throw const EpisodeTranscriptionException(
        'OpenAI API key is not configured. Add it in Settings > AI.',
      );
    }

    final preparedAudio = await _audioPreparer.prepareForTranscription(
      inputFile: audioFile,
      onProgress: onProgress,
    );

    try {
      final chunkTranscripts = <Transcript>[];
      final totalChunks = preparedAudio.chunks.length;
      _log.fine('Prepared ${preparedAudio.chunks.length} chunk(s) for ${episode.guid}');

      for (var chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
        final chunk = preparedAudio.chunks[chunkIndex];
        final chunkFile = File(chunk.path);
        final chunkSize = chunkFile.existsSync() ? chunkFile.lengthSync() : -1;
        _log.fine(
          'Uploading chunk ${chunkIndex + 1}/$totalChunks for ${episode.guid}: '
          '${chunk.path} (${chunkSize >= 0 ? chunkSize : 'missing'} bytes, offset=${chunk.startOffset.inSeconds}s)',
        );

        onProgress?.call(EpisodeTranscriptionProgress(
          stage: EpisodeTranscriptionStage.uploading,
          message: totalChunks == 1
              ? 'Uploading audio to OpenAI...'
              : 'Uploading audio ${chunkIndex + 1} of $totalChunks to OpenAI...',
          progress: totalChunks == 1 ? null : chunkIndex / totalChunks,
        ));

        chunkTranscripts.add(await _submitChunkForTranscription(
          apiKey: apiKey,
          audioPath: chunk.path,
        ));
        _log.fine(
          'Received transcript chunk ${chunkIndex + 1}/$totalChunks for ${episode.guid}: '
          '${chunkTranscripts.last.subtitles.length} subtitle(s)',
        );

        onProgress?.call(EpisodeTranscriptionProgress(
          stage: EpisodeTranscriptionStage.transcribing,
          message: totalChunks == 1
              ? 'Processing transcript from OpenAI...'
              : 'Processing transcript ${chunkIndex + 1} of $totalChunks from OpenAI...',
          progress: (chunkIndex + 1) / totalChunks,
        ));
      }

      final transcript = _mergeChunkTranscripts(
        chunkTranscripts: chunkTranscripts,
        chunks: preparedAudio.chunks,
        guid: episode.guid,
      );
      _log.fine('Merged transcript for ${episode.guid}: ${transcript.subtitles.length} subtitle(s)');

      if (!transcript.transcriptAvailable) {
        _log.warning('Merged transcript had no usable subtitles for ${episode.guid}');
        throw const EpisodeTranscriptionException(
          'OpenAI transcription did not return any usable transcript segments.',
        );
      }

      onProgress?.call(const EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.completed,
        message: 'Transcript ready.',
        progress: 1.0,
      ));

      return transcript;
    } on TimeoutException catch (error, stackTrace) {
      _log.warning('OpenAI transcription timed out for ${episode.guid}', error, stackTrace);
      throw const EpisodeTranscriptionException(
        'OpenAI transcription timed out. Try again.',
      );
    } on SocketException catch (error, stackTrace) {
      _log.warning('OpenAI transcription network failure for ${episode.guid}', error, stackTrace);
      throw const EpisodeTranscriptionException(
        'OpenAI transcription could not reach the network. Check your connection and try again.',
      );
    } on http.ClientException catch (error, stackTrace) {
      _log.warning('OpenAI transcription client failure for ${episode.guid}', error, stackTrace);
      throw const EpisodeTranscriptionException(
        'OpenAI transcription could not reach OpenAI. Check your connection and try again.',
      );
    } on EpisodeTranscriptionException catch (error, stackTrace) {
      _log.warning('OpenAI transcription failed for ${episode.guid}: ${error.message}', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _log.severe('Unexpected OpenAI transcription failure for ${episode.guid}', error, stackTrace);
      throw EpisodeTranscriptionException(
        'OpenAI transcription failed: $error',
      );
    } finally {
      await preparedAudio.dispose();
      _log.fine('Disposed prepared audio for ${episode.guid}');
    }
  }

  Future<Transcript> _submitChunkForTranscription({
    required String apiKey,
    required String audioPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _baseUri.resolve('audio/transcriptions'),
    )
      ..headers.addAll(<String, String>{
        'authorization': 'Bearer $apiKey',
        'accept': 'text/plain, application/json',
        'user-agent': Environment.userAgent(),
      })
      ..fields.addAll(<String, String>{
        'model': _model,
        'response_format': 'srt',
        'temperature': '0',
      });

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        filename: path.basename(audioPath),
      ),
    );

    final streamedResponse = await _client.send(request).timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    _log.fine('OpenAI transcription response for ${path.basename(audioPath)}: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EpisodeTranscriptionException(_httpErrorMessage(
        statusCode: response.statusCode,
        body: response.body,
      ));
    }

    final content = response.body.trim();

    if (content.isEmpty) {
      throw const EpisodeTranscriptionException(
        'OpenAI transcription returned an empty transcript.',
      );
    }

    return EpisodeAnalysisTranscriptCodec.fromDto(
      EpisodeAnalysisTranscriptDto(
        format: 'srt',
        content: content,
      ),
      provenance: TranscriptProvenance.openAi,
      provider: _model,
    );
  }

  Transcript _mergeChunkTranscripts({
    required List<Transcript> chunkTranscripts,
    required List<PreparedOpenAiAudioChunk> chunks,
    required String? guid,
  }) {
    final subtitles = <Subtitle>[];
    var nextIndex = 1;

    for (var index = 0; index < chunkTranscripts.length; index++) {
      final chunkTranscript = chunkTranscripts[index];
      final startOffset = chunks[index].startOffset;

      for (final subtitle in chunkTranscript.subtitles) {
        subtitles.add(Subtitle(
          index: nextIndex,
          start: subtitle.start + startOffset,
          end: (subtitle.end ?? subtitle.start) + startOffset,
          data: subtitle.data,
          speaker: subtitle.speaker,
        ));
        nextIndex += 1;
      }
    }

    return Transcript(
      guid: guid,
      subtitles: List<Subtitle>.unmodifiable(subtitles),
      provenance: TranscriptProvenance.openAi,
      provider: _model,
    );
  }

  String _httpErrorMessage({
    required int statusCode,
    required String body,
  }) {
    final apiMessage = _extractOpenAiErrorMessage(body);

    switch (statusCode) {
      case 400:
        return apiMessage == null || apiMessage.isEmpty
            ? 'OpenAI rejected the transcription request. Try again later.'
            : 'OpenAI rejected the transcription request: $apiMessage';
      case 401:
        return 'OpenAI API key was rejected. Check the key in Settings > AI.';
      case 413:
        return 'This audio file is too large for the current OpenAI transcription request.';
      case 429:
        return 'OpenAI rate limit reached. Wait a moment and try again.';
      default:
        if (statusCode >= 500) {
          return 'OpenAI is temporarily unavailable. Try again.';
        }

        if (apiMessage == null || apiMessage.isEmpty) {
          return 'OpenAI transcription request failed with status $statusCode.';
        }

        return 'OpenAI transcription request failed: $apiMessage';
    }
  }

  String? _extractOpenAiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return null;
      }

      final error = decoded['error'];

      if (error is! Map) {
        return null;
      }

      final message = error['message'];
      return message is String && message.trim().isNotEmpty ? message.trim() : null;
    } catch (_) {
      return null;
    }
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

abstract class OpenAiTranscriptionAudioPreparer {
  Future<PreparedOpenAiAudio> prepareForTranscription({
    required File inputFile,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  });
}

class PreparedOpenAiAudio {
  PreparedOpenAiAudio({
    required List<PreparedOpenAiAudioChunk> chunks,
    Future<void> Function()? onDispose,
  })  : assert(chunks.isNotEmpty),
        chunks = List<PreparedOpenAiAudioChunk>.unmodifiable(chunks),
        _onDispose = onDispose;

  final List<PreparedOpenAiAudioChunk> chunks;
  final Future<void> Function()? _onDispose;

  Future<void> dispose() async {
    await _onDispose?.call();
  }
}

class PreparedOpenAiAudioChunk {
  const PreparedOpenAiAudioChunk({
    required this.path,
    required this.startOffset,
  });

  final String path;
  final Duration startOffset;
}

class DefaultOpenAiTranscriptionAudioPreparer implements OpenAiTranscriptionAudioPreparer {
  static const _openAiUploadLimitBytes = 25 * 1000 * 1000;
  static const _targetChunkBytes = 23 * 1000 * 1000;
  static const _audioSampleRateHz = 16000;
  static const _audioBitrateKbps = 32;
  static const _minimumChunkDuration = Duration(seconds: 30);
  static final _log = Logger('OpenAiTranscriptionAudioPreparer');

  @override
  Future<PreparedOpenAiAudio> prepareForTranscription({
    required File inputFile,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    final workingDirectory = await Directory.systemTemp.createTemp('anytime-openai-transcription-');
    _log.fine('Preparing ${inputFile.path} (${inputFile.lengthSync()} bytes) in ${workingDirectory.path}');

    try {
      onProgress?.call(const EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.preparing,
        message: 'Downsampling audio for OpenAI transcription...',
      ));

      final preparedAudioPath = path.join(workingDirectory.path, 'prepared.m4a');
      await _runFfmpeg(
        <String>[
          '-y',
          '-i',
          inputFile.path,
          '-vn',
          '-ac',
          '1',
          '-ar',
          '$_audioSampleRateHz',
          '-c:a',
          'aac',
          '-b:a',
          '${_audioBitrateKbps}k',
          preparedAudioPath,
        ],
        failureMessage: 'Failed to prepare audio for OpenAI transcription.',
      );

      final preparedFile = File(preparedAudioPath);

      if (!preparedFile.existsSync() || preparedFile.lengthSync() <= 0) {
        _log.warning('Prepared audio file missing or empty: $preparedAudioPath');
        throw const EpisodeTranscriptionException(
          'Failed to prepare audio for OpenAI transcription.',
        );
      }

      _log.fine('Prepared audio file: $preparedAudioPath (${preparedFile.lengthSync()} bytes)');

      if (preparedFile.lengthSync() <= _openAiUploadLimitBytes) {
        _log.fine('Prepared audio fits in one upload');
        return PreparedOpenAiAudio(
          chunks: <PreparedOpenAiAudioChunk>[
            PreparedOpenAiAudioChunk(
              path: preparedAudioPath,
              startOffset: Duration.zero,
            ),
          ],
          onDispose: () => workingDirectory.delete(recursive: true),
        );
      }

      final preparedDuration = await _probeDuration(preparedAudioPath);

      if (preparedDuration == null || preparedDuration <= Duration.zero) {
        _log.warning('Prepared audio duration unavailable for $preparedAudioPath');
        throw const EpisodeTranscriptionException(
          'Prepared audio is still too large and could not be split for OpenAI transcription.',
        );
      }

      _log.fine('Prepared audio duration: ${preparedDuration.inSeconds}s');

      onProgress?.call(const EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.preparing,
        message: 'Splitting audio into upload-sized chunks...',
      ));

      final chunks = await _splitPreparedAudio(
        preparedFile: preparedFile,
        totalDuration: preparedDuration,
        workingDirectory: workingDirectory,
        onProgress: onProgress,
      );
      _log.fine('Created ${chunks.length} prepared chunk(s)');

      return PreparedOpenAiAudio(
        chunks: chunks,
        onDispose: () => workingDirectory.delete(recursive: true),
      );
    } catch (_) {
      if (workingDirectory.existsSync()) {
        await workingDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<List<PreparedOpenAiAudioChunk>> _splitPreparedAudio({
    required File preparedFile,
    required Duration totalDuration,
    required Directory workingDirectory,
    void Function(EpisodeTranscriptionProgress progress)? onProgress,
  }) async {
    final totalSeconds = math.max(1, totalDuration.inSeconds);
    var chunkDurationSeconds = math.max(
      _minimumChunkDuration.inSeconds,
      ((totalSeconds * _targetChunkBytes) / math.max(preparedFile.lengthSync(), 1)).floor(),
    );

    if (chunkDurationSeconds >= totalSeconds) {
      chunkDurationSeconds = math.max(
        _minimumChunkDuration.inSeconds,
        (totalSeconds / 2).ceil(),
      );
    }

    _log.fine('Initial chunk duration target: ${chunkDurationSeconds}s');

    while (true) {
      final chunks = <PreparedOpenAiAudioChunk>[];
      var startOffset = Duration.zero;
      var chunkIndex = 0;
      var needsSmallerChunks = false;

      while (startOffset < totalDuration) {
        final remaining = totalDuration - startOffset;
        final chunkDuration = remaining < Duration(seconds: chunkDurationSeconds)
            ? remaining
            : Duration(seconds: chunkDurationSeconds);
        final chunkPath = path.join(
          workingDirectory.path,
          'chunk-${chunkIndex.toString().padLeft(3, '0')}.m4a',
        );

        await _runFfmpeg(
          <String>[
            '-y',
            '-ss',
            _formatFfmpegDuration(startOffset),
            '-t',
            _formatFfmpegDuration(chunkDuration),
            '-i',
            preparedFile.path,
            '-c',
            'copy',
            chunkPath,
          ],
          failureMessage: 'Failed to split audio for OpenAI transcription.',
        );

        final chunkFile = File(chunkPath);

        if (!chunkFile.existsSync() || chunkFile.lengthSync() <= 0) {
          _log.warning('Chunk file missing or empty: $chunkPath');
          throw const EpisodeTranscriptionException(
            'Failed to split audio for OpenAI transcription.',
          );
        }

        _log.fine(
          'Prepared chunk ${chunkIndex + 1}: $chunkPath '
          '(${chunkFile.lengthSync()} bytes, offset=${startOffset.inSeconds}s, duration=${chunkDuration.inSeconds}s)',
        );

        if (chunkFile.lengthSync() > _openAiUploadLimitBytes) {
          _log.warning('Chunk exceeds OpenAI upload limit, retrying with smaller chunk size');
          needsSmallerChunks = true;
          break;
        }

        chunks.add(PreparedOpenAiAudioChunk(
          path: chunkPath,
          startOffset: startOffset,
        ));

        startOffset += chunkDuration;
        chunkIndex += 1;

        onProgress?.call(EpisodeTranscriptionProgress(
          stage: EpisodeTranscriptionStage.preparing,
          message: 'Splitting audio into upload-sized chunks...',
          progress: math.min(
            1.0,
            totalDuration.inMilliseconds == 0
                ? 1.0
                : startOffset.inMilliseconds / totalDuration.inMilliseconds,
          ),
        ));
      }

      if (!needsSmallerChunks) {
        return chunks;
      }

      for (final chunk in chunks) {
        final file = File(chunk.path);

        if (file.existsSync()) {
          await file.delete();
        }
      }

      if (chunkDurationSeconds <= _minimumChunkDuration.inSeconds) {
        throw const EpisodeTranscriptionException(
          'This episode is still too large for OpenAI transcription after audio preparation.',
        );
      }

      final nextChunkDurationSeconds = math.max(
        _minimumChunkDuration.inSeconds,
        (chunkDurationSeconds * 0.75).floor(),
      );

      if (nextChunkDurationSeconds >= chunkDurationSeconds) {
        throw const EpisodeTranscriptionException(
          'This episode is still too large for OpenAI transcription after audio preparation.',
        );
      }

      chunkDurationSeconds = nextChunkDurationSeconds;
      _log.fine('Retrying chunk split with target duration ${chunkDurationSeconds}s');
    }
  }

  Future<Duration?> _probeDuration(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final durationSeconds =
        double.tryParse(session.getMediaInformation()?.getDuration()?.trim() ?? '');

    if (durationSeconds == null || durationSeconds <= 0) {
      return null;
    }

    return Duration(milliseconds: (durationSeconds * 1000).round());
  }

  Future<void> _runFfmpeg(
    List<String> commandArguments, {
    required String failureMessage,
  }) async {
    final session = await FFmpegKit.executeWithArguments(commandArguments);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return;
    }

    final output = (await session.getOutput())?.trim();
    _log.warning('FFmpeg command failed: ${commandArguments.join(' ')}');

    if (output != null && output.isNotEmpty) {
      throw EpisodeTranscriptionException('$failureMessage $output');
    }

    throw EpisodeTranscriptionException(failureMessage);
  }

  String _formatFfmpegDuration(Duration duration) {
    return (duration.inMilliseconds / 1000).toStringAsFixed(3);
  }
}
