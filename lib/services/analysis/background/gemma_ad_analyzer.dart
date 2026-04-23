// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/services/analysis/background/transcript_chunker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logging/logging.dart';

/// Abstracts on-device Gemma-4 ad-segment detection via `flutter_gemma`
/// function calling (spec §4.5). The concrete `flutter_gemma`-backed
/// implementation lands in a later phase; phase 3 code depends only on this
/// contract.
abstract class GemmaAdAnalyzer {
  /// Run Gemma-4 against a single transcript chunk and return the raw ad
  /// segments it reported. Callers merge across chunks via
  /// `AdSegmentChunkMerger`.
  ///
  /// Implementations MUST fail fast when the model response violates the
  /// function-call schema (AC-009); partial or malformed output is an error,
  /// not a degraded success.
  Future<List<AdSegment>> analyzeChunk({
    required TranscriptChunk chunk,
    required String modelId,
  });

  Future<void> close();
}

/// Raised when a Gemma-4 response cannot be bound to the declared function
/// schema. Worker treats this as a terminal failure for the current attempt.
class GemmaAdAnalyzerException implements Exception {
  final String message;
  const GemmaAdAnalyzerException(this.message);

  @override
  String toString() => 'GemmaAdAnalyzerException($message)';
}

/// Stub used when `flutter_gemma` is not yet wired or not available on the
/// current platform. Any call throws so the worker can surface a failed stage.
class DisabledGemmaAdAnalyzer implements GemmaAdAnalyzer {
  const DisabledGemmaAdAnalyzer();

  @override
  Future<List<AdSegment>> analyzeChunk({
    required TranscriptChunk chunk,
    required String modelId,
  }) {
    throw const GemmaAdAnalyzerException(
      'Gemma-4 ad analyzer is not configured in this build.',
    );
  }

  @override
  Future<void> close() async {}
}

/// Concrete `flutter_gemma`-backed implementation. Creates a Gemma inference
/// model lazily on the first chunk, then reuses it for subsequent calls.
///
/// Each chunk runs in a fresh chat so prior chunks cannot bleed context into
/// later ones — boundary overlap + merge (§4.6) is how we stitch them back
/// together, not chat memory.
class FlutterGemmaAdAnalyzer implements GemmaAdAnalyzer {
  static const int _maxTokens = 8192;

  final FlutterGemmaPlugin _plugin;
  final String? _modelFilePath;
  final PreferredBackend _preferredBackend;
  final _log = Logger('FlutterGemmaAdAnalyzer');

  InferenceModel? _model;

  FlutterGemmaAdAnalyzer({
    String? modelFilePath,
    FlutterGemmaPlugin? plugin,
    PreferredBackend preferredBackend = PreferredBackend.cpu,
  })  : _modelFilePath = modelFilePath,
        _plugin = plugin ?? FlutterGemmaPlugin.instance,
        _preferredBackend = preferredBackend;

  @override
  Future<List<AdSegment>> analyzeChunk({
    required TranscriptChunk chunk,
    required String modelId,
  }) async {
    if (chunk.text.trim().isEmpty) {
      return const <AdSegment>[];
    }

    final model = await _ensureModel();
    final chat = await model.createChat(
      temperature: 0.2,
      randomSeed: 1,
      topK: 1,
    );

    try {
      await chat.addQueryChunk(Message.text(
        text: _buildPrompt(chunk),
        isUser: true,
      ));

      final response = await chat.generateChatResponse();
      if (response is! TextResponse) {
        throw GemmaAdAnalyzerException(
          'Gemma returned non-text response for chunk ${chunk.index}: '
          '${response.runtimeType}',
        );
      }
      final args = _parseJsonArgs(response.token, chunkIndex: chunk.index);
      return _parseSegments(args, chunkIndex: chunk.index);
    } finally {
      // Best-effort chat teardown — errors here shouldn't mask the primary
      // result.
      try {
        await _closeChat(chat);
      } catch (error, stack) {
        _log.fine('Failed to close Gemma chat: $error', error, stack);
      }
    }
  }

  @override
  Future<void> close() async {
    final model = _model;
    _model = null;
    if (model != null) {
      await model.close();
    }
  }

  Future<InferenceModel> _ensureModel() async {
    final existing = _model;
    if (existing != null) {
      return existing;
    }

    final path = _modelFilePath;
    if (path != null) {
      // ignore: deprecated_member_use
      await _plugin.modelManager.setModelPath(path);
    }
    final created = await _plugin.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: _preferredBackend,
      maxTokens: _maxTokens,
    );
    _model = created;
    return created;
  }

  String _buildPrompt(TranscriptChunk chunk) {
    final buffer = StringBuffer()
      ..writeln(
        'You are analyzing a podcast transcript chunk for advertising '
        'segments. Reply with a single JSON object on one line, no prose, no '
        'markdown fences. Schema: '
        '{"segments":[{"start_ms":<int>,"end_ms":<int>,"reason":<string>,'
        '"confidence":<number 0..1>}]}. Timestamps are milliseconds since the '
        'start of the episode. If there are no ads, reply with '
        '{"segments":[]}.',
      )
      ..writeln('---')
      ..writeln('Chunk index: ${chunk.index}')
      ..writeln('Chunk start_ms: ${chunk.startMs}')
      ..writeln('Chunk end_ms: ${chunk.endMs}')
      ..writeln('---');

    for (final subtitle in chunk.subtitles) {
      final text = subtitle.data?.trim();
      if (text == null || text.isEmpty) {
        continue;
      }
      final startMs = subtitle.start.inMilliseconds;
      final endMs = subtitle.end?.inMilliseconds ?? startMs;
      buffer.writeln('[$startMs-$endMs] $text');
    }

    return buffer.toString();
  }

  /// Extract the first balanced JSON object from a free-form Gemma reply.
  /// Tolerates leading/trailing prose, ```json fences, and stray whitespace —
  /// the model is asked for clean JSON but reality varies.
  Map<String, dynamic> _parseJsonArgs(String raw, {required int chunkIndex}) {
    final text = raw.trim();
    final start = text.indexOf('{');
    if (start < 0) {
      throw GemmaAdAnalyzerException(
        'No JSON object in chunk $chunkIndex response: $text',
      );
    }
    var depth = 0;
    var inString = false;
    var escape = false;
    for (var i = start; i < text.length; i++) {
      final c = text[i];
      if (escape) {
        escape = false;
        continue;
      }
      if (c == r'\') {
        escape = true;
        continue;
      }
      if (c == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) {
          final slice = text.substring(start, i + 1);
          try {
            final decoded = jsonDecode(slice);
            if (decoded is! Map<String, dynamic>) {
              throw GemmaAdAnalyzerException(
                'Top-level JSON in chunk $chunkIndex is not an object: $slice',
              );
            }
            return decoded;
          } on FormatException catch (e) {
            throw GemmaAdAnalyzerException(
              'Failed to parse JSON in chunk $chunkIndex: ${e.message}',
            );
          }
        }
      }
    }
    throw GemmaAdAnalyzerException(
      'Unbalanced JSON in chunk $chunkIndex response: $text',
    );
  }

  List<AdSegment> _parseSegments(
    Map<String, dynamic> args, {
    required int chunkIndex,
  }) {
    final raw = args['segments'];
    if (raw is! List) {
      throw GemmaAdAnalyzerException(
        'Missing or non-list `segments` in chunk $chunkIndex response',
      );
    }

    final parsed = <AdSegment>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is! Map) {
        throw GemmaAdAnalyzerException(
          'Segment $i in chunk $chunkIndex is not an object',
        );
      }

      final startMs = _requireInt(entry['start_ms'], 'start_ms', chunkIndex, i);
      final endMs = _requireInt(entry['end_ms'], 'end_ms', chunkIndex, i);
      if (endMs < startMs) {
        throw GemmaAdAnalyzerException(
          'Segment $i in chunk $chunkIndex has end_ms < start_ms',
        );
      }

      parsed.add(AdSegment(
        startMs: startMs,
        endMs: endMs,
        reason: entry['reason'] is String ? entry['reason'] as String : null,
        confidence: _optionalDouble(entry['confidence']),
      ));
    }
    return parsed;
  }

  static int _requireInt(Object? value, String field, int chunkIndex, int segIndex) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw GemmaAdAnalyzerException(
      'Segment $segIndex in chunk $chunkIndex has invalid `$field`: $value',
    );
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _closeChat(InferenceChat chat) async {
    // `InferenceChat` does not expose an explicit close on every version of
    // the plugin; rely on GC via the next `createChat` replacing it.
  }
}
