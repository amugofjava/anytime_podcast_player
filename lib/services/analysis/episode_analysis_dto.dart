// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/services/analysis/ad_segment_normalizer.dart';

enum EpisodeAnalysisJobStatus {
  queued,
  processing,
  completed,
  failed,
  unknown,
}

class EpisodeAnalysisSubmitResponse {
  final String jobId;
  final EpisodeAnalysisJobStatus status;
  final bool cached;

  EpisodeAnalysisSubmitResponse({
    required this.jobId,
    this.status = EpisodeAnalysisJobStatus.queued,
    this.cached = false,
  });

  factory EpisodeAnalysisSubmitResponse.fromMap(Map<String, dynamic> data) {
    return EpisodeAnalysisSubmitResponse(
      jobId: _parseRequiredString(data, 'job_id'),
      status: _parseStatus(data['status']),
      cached: _parseBool(data['cached']),
    );
  }
}

class EpisodeAnalysisTranscriptPayload {
  final String format;
  final String content;

  EpisodeAnalysisTranscriptPayload({
    required this.format,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'format': format,
      'content': content,
    };
  }
}

class EpisodeAnalysisTranscriptDto {
  final String format;
  final String content;

  EpisodeAnalysisTranscriptDto({
    required this.format,
    required this.content,
  });

  factory EpisodeAnalysisTranscriptDto.fromMap(Map<String, dynamic> data) {
    return EpisodeAnalysisTranscriptDto(
      format: _parseRequiredString(data, 'format'),
      content: _parseRequiredString(data, 'content'),
    );
  }
}

class EpisodeAnalysisStatusResponse {
  final String jobId;
  final EpisodeAnalysisJobStatus status;
  final String? error;
  final EpisodeAnalysisTranscriptDto? transcript;
  final List<AdSegment> adSegments;
  final bool cached;

  EpisodeAnalysisStatusResponse({
    required this.jobId,
    required this.status,
    this.error,
    this.transcript,
    this.adSegments = const <AdSegment>[],
    this.cached = false,
  });

  bool get isCompleted => status == EpisodeAnalysisJobStatus.completed;

  factory EpisodeAnalysisStatusResponse.fromMap(Map<String, dynamic> data) {
    final status = _parseStatus(data['status']);
    final transcriptData = data['transcript'];
    final adSegmentsData = data['ad_segments'];

    return EpisodeAnalysisStatusResponse(
      jobId: _parseRequiredString(data, 'job_id'),
      status: status,
      error: data['error'] as String?,
      transcript: transcriptData is Map
          ? EpisodeAnalysisTranscriptDto.fromMap(Map<String, dynamic>.from(transcriptData))
          : null,
      adSegments: adSegmentsData is List
          ? AdSegmentNormalizer.normalize(
              adSegmentsData
                  .whereType<Map>()
                  .map((adSegment) => AdSegment(
                        startMs: _parseInt(adSegment['start_ms']),
                        endMs: _parseInt(adSegment['end_ms']),
                        reason: adSegment['reason'] as String?,
                        confidence: _parseDouble(adSegment['confidence']),
                        flags: (adSegment['flags'] as List?)?.map((flag) => flag.toString()).toList(growable: false) ??
                            const <String>[],
                      ))
                  .toList(growable: false),
            )
          : const <AdSegment>[],
      cached: _parseBool(data['cached']),
    );
  }
}

EpisodeAnalysisJobStatus _parseStatus(Object? status) {
  final normalized = status?.toString().trim().toLowerCase();

  switch (normalized) {
    case 'queued':
    case 'pending':
    case 'submitted':
      return EpisodeAnalysisJobStatus.queued;
    case 'processing':
    case 'running':
    case 'in_progress':
      return EpisodeAnalysisJobStatus.processing;
    case 'completed':
    case 'complete':
    case 'done':
      return EpisodeAnalysisJobStatus.completed;
    case 'failed':
    case 'error':
      return EpisodeAnalysisJobStatus.failed;
    default:
      return EpisodeAnalysisJobStatus.unknown;
  }
}

String _parseRequiredString(Map<String, dynamic> data, String key) {
  final value = data[key]?.toString().trim() ?? '';

  if (value.isEmpty) {
    throw FormatException('Missing required key "$key" in episode analysis payload.');
  }

  return value;
}

bool _parseBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();

  return normalized == 'true' || normalized == '1';
}

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is String && value.isNotEmpty && value != 'null') {
    return int.parse(value);
  }

  return 0;
}

double? _parseDouble(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is String && value.isNotEmpty && value != 'null') {
    return double.parse(value);
  }

  return null;
}
