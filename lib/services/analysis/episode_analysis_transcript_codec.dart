// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/transcript.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';

class EpisodeAnalysisTranscriptCodec {
  static EpisodeAnalysisTranscriptPayload toPayload(Transcript transcript) {
    return EpisodeAnalysisTranscriptPayload(
      format: 'srt',
      content: _encodeSrt(transcript),
    );
  }

  static Transcript fromDto(
    EpisodeAnalysisTranscriptDto transcript, {
    String? guid,
  }) {
    final normalizedFormat = transcript.format.trim().toLowerCase();

    switch (normalizedFormat) {
      case 'srt':
      case 'subrip':
        return Transcript(
          guid: guid,
          subtitles: _parseSrt(transcript.content),
        );
      default:
        throw UnsupportedError('Unsupported analysis transcript format: ${transcript.format}');
    }
  }

  static String _encodeSrt(Transcript transcript) {
    final buffer = StringBuffer();

    for (var index = 0; index < transcript.subtitles.length; index++) {
      final subtitle = transcript.subtitles[index];
      final subtitleIndex = subtitle.index > 0 ? subtitle.index : index + 1;
      final end = subtitle.end ?? subtitle.start;
      final content = subtitle.speaker.isNotEmpty && (subtitle.data?.isNotEmpty ?? false)
          ? '${subtitle.speaker}: ${subtitle.data}'
          : subtitle.data ?? subtitle.speaker;

      buffer
        ..writeln(subtitleIndex)
        ..writeln('${_formatTimestamp(subtitle.start)} --> ${_formatTimestamp(end)}')
        ..writeln(content.trim())
        ..writeln();
    }

    return buffer.toString().trim();
  }

  static List<Subtitle> _parseSrt(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();

    if (normalized.isEmpty) {
      return const <Subtitle>[];
    }

    final blocks = normalized.split(RegExp(r'\n\s*\n'));
    final subtitles = <Subtitle>[];

    for (final block in blocks) {
      final lines = block.split('\n').map((line) => line.trimRight()).toList(growable: false);

      if (lines.isEmpty) {
        continue;
      }

      var lineIndex = 0;
      var subtitleIndex = subtitles.length + 1;

      if (RegExp(r'^\d+$').hasMatch(lines.first)) {
        subtitleIndex = int.parse(lines.first);
        lineIndex = 1;
      }

      if (lineIndex >= lines.length || !lines[lineIndex].contains('-->')) {
        continue;
      }

      final times = lines[lineIndex].split('-->');

      if (times.length != 2) {
        continue;
      }

      final start = _parseTimestamp(times[0].trim());
      final end = _parseTimestamp(times[1].trim());
      final data = lines.skip(lineIndex + 1).join('\n').trim();

      subtitles.add(Subtitle(
        index: subtitleIndex,
        start: start,
        end: end,
        data: data,
      ));
    }

    return List<Subtitle>.unmodifiable(subtitles);
  }

  static String _formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');

    return '$hours:$minutes:$seconds,$milliseconds';
  }

  static Duration _parseTimestamp(String raw) {
    final match = RegExp(r'^(\d{2}):(\d{2}):(\d{2})[,.](\d{3})$').firstMatch(raw);

    if (match == null) {
      throw FormatException('Invalid SRT timestamp: $raw');
    }

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final milliseconds = int.parse(match.group(4)!);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
