// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/analysis/episode_analysis_dto.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

abstract class EpisodeAnalysisService {
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  });

  Future<EpisodeAnalysisStatusResponse> poll({
    required String jobId,
  });

  void close();
}

class DisabledEpisodeAnalysisService implements EpisodeAnalysisService {
  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) {
    throw StateError(
      'Episode analysis backend URL is not configured. Provide EPISODE_ANALYSIS_BACKEND_BASE_URL via --dart-define.',
    );
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({
    required String jobId,
  }) {
    throw StateError(
      'Episode analysis backend URL is not configured. Provide EPISODE_ANALYSIS_BACKEND_BASE_URL via --dart-define.',
    );
  }

  @override
  void close() {}
}

class BackendEpisodeAnalysisService implements EpisodeAnalysisService {
  final _log = Logger('BackendEpisodeAnalysisService');
  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  BackendEpisodeAnalysisService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUri = _parseBaseUri(baseUrl ?? Environment.analysisBackendBaseUrl);

  @override
  Future<EpisodeAnalysisSubmitResponse> submit({
    required Episode episode,
    bool force = false,
    EpisodeAnalysisTranscriptPayload? transcript,
  }) async {
    final episodeUrl = episode.contentUrl?.trim() ?? '';

    if (episode.guid.isEmpty) {
      throw ArgumentError.value(episode.guid, 'episode.guid', 'Episode guid is required for analysis submission.');
    }

    if (episodeUrl.isEmpty) {
      throw ArgumentError.value(episode.contentUrl, 'episode.contentUrl', 'Episode contentUrl is required.');
    }

    final uri = _buildUri('episode-analysis');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'episode_url': episodeUrl,
        'guid': episode.guid,
        'force': force,
        if (transcript != null) 'transcript': transcript.toMap(),
      }),
    );

    _log.fine('Submitted episode analysis request for ${episode.guid} to $uri');

    return EpisodeAnalysisSubmitResponse.fromMap(
        _decodeBody(response, expectedStatusCodes: const <int>{200, 201, 202}));
  }

  @override
  Future<EpisodeAnalysisStatusResponse> poll({
    required String jobId,
  }) async {
    if (jobId.trim().isEmpty) {
      throw ArgumentError.value(jobId, 'jobId', 'Analysis job id is required.');
    }

    final uri = _buildUri('episode-analysis/${Uri.encodeComponent(jobId)}');
    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    _log.fine('Fetched episode analysis status for $jobId from $uri');

    return EpisodeAnalysisStatusResponse.fromMap(_decodeBody(response, expectedStatusCodes: const <int>{200}));
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Map<String, String> _headers() {
    return <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      'user-agent': Environment.userAgent(),
      // TODO: Add backend authentication headers and request signing once auth/security is defined.
    };
  }

  Map<String, dynamic> _decodeBody(
    http.Response response, {
    required Set<int> expectedStatusCodes,
  }) {
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw EpisodeAnalysisHttpException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const FormatException('Episode analysis response was not a JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Uri _buildUri(String relativePath) => _baseUri.resolve(relativePath);

  static Uri _parseBaseUri(String baseUrl) {
    final trimmed = baseUrl.trim();

    if (trimmed.isEmpty) {
      throw StateError(
        'Episode analysis backend URL is not configured. Provide EPISODE_ANALYSIS_BACKEND_BASE_URL via --dart-define.',
      );
    }

    final uri = Uri.parse(trimmed);

    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Episode analysis backend URL must be absolute.');
    }

    final normalizedPath = uri.path.isEmpty
        ? '/'
        : uri.path.endsWith('/')
            ? uri.path
            : '${uri.path}/';

    return uri.replace(path: normalizedPath);
  }
}

class EpisodeAnalysisHttpException implements Exception {
  final int statusCode;
  final String body;

  EpisodeAnalysisHttpException({
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() => 'EpisodeAnalysisHttpException(statusCode: $statusCode, body: $body)';
}
