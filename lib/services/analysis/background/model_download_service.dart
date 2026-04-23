// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/services/analysis/background/analysis_model_catalog.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logging/logging.dart';

/// Progress emitted while a Gemma model is downloading. Percent is an
/// overall 0-100 value across all files that make up the model spec.
class GemmaDownloadProgress {
  final int percent;
  final String filename;

  const GemmaDownloadProgress({required this.percent, required this.filename});
}

/// Handles acquisition of the on-device Gemma model files required by the
/// background ad analysis pipeline (spec REQ-008, AC-007). Abstracts over
/// `flutter_gemma` so non-Android builds and tests can use a noop.
abstract class GemmaModelDownloadService {
  Future<bool> isInstalled(BackgroundAnalysisLocalModel variant);

  /// Stream 0-100% progress values for the given variant. The service uses
  /// `flutter_gemma`'s Android foreground-service mechanism, so the user can
  /// cancel from the system notification.
  Stream<GemmaDownloadProgress> download(
    BackgroundAnalysisLocalModel variant, {
    String? huggingFaceToken,
  });

  /// Absolute path to the primary model file once installed, or null if the
  /// model has not yet been downloaded.
  Future<String?> resolveLocalPath(BackgroundAnalysisLocalModel variant);

  Future<void> delete(BackgroundAnalysisLocalModel variant);
}

class FlutterGemmaModelDownloadService implements GemmaModelDownloadService {
  final FlutterGemmaPlugin _plugin;
  final _log = Logger('FlutterGemmaModelDownloadService');

  FlutterGemmaModelDownloadService({FlutterGemmaPlugin? plugin})
      : _plugin = plugin ?? FlutterGemmaPlugin.instance;

  @override
  Future<bool> isInstalled(BackgroundAnalysisLocalModel variant) async {
    try {
      return await _plugin.modelManager.isModelInstalled(_specFor(variant));
    } catch (error, stack) {
      _log.warning('isModelInstalled failed for $variant: $error', error, stack);
      return false;
    }
  }

  @override
  Stream<GemmaDownloadProgress> download(
    BackgroundAnalysisLocalModel variant, {
    String? huggingFaceToken,
  }) {
    final spec = _specFor(variant);
    final token = (huggingFaceToken?.trim().isEmpty ?? true) ? null : huggingFaceToken!.trim();
    return _plugin.modelManager.downloadModelWithProgress(spec, token: token).map(
          (p) => GemmaDownloadProgress(
            percent: p.overallProgress,
            filename: p.currentFileName,
          ),
        );
  }

  @override
  Future<String?> resolveLocalPath(BackgroundAnalysisLocalModel variant) async {
    final spec = _specFor(variant);
    try {
      final paths = await _plugin.modelManager.getModelFilePaths(spec);
      if (paths == null || paths.isEmpty) return null;
      return paths.values.first;
    } catch (error, stack) {
      _log.warning('getModelFilePaths failed for $variant: $error', error, stack);
      return null;
    }
  }

  @override
  Future<void> delete(BackgroundAnalysisLocalModel variant) async {
    await _plugin.modelManager.deleteModel(_specFor(variant));
  }

  InferenceModelSpec _specFor(BackgroundAnalysisLocalModel variant) {
    final url = AnalysisModelCatalog.downloadUrlFor(variant).toString();
    return InferenceModelSpec.fromLegacyUrl(
      name: AnalysisModelCatalog.modelIdFor(variant),
      modelUrl: url,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
    );
  }
}

class NoopGemmaModelDownloadService implements GemmaModelDownloadService {
  const NoopGemmaModelDownloadService();

  @override
  Future<bool> isInstalled(BackgroundAnalysisLocalModel variant) async => false;

  @override
  Stream<GemmaDownloadProgress> download(
    BackgroundAnalysisLocalModel variant, {
    String? huggingFaceToken,
  }) {
    return const Stream<GemmaDownloadProgress>.empty();
  }

  @override
  Future<String?> resolveLocalPath(BackgroundAnalysisLocalModel variant) async => null;

  @override
  Future<void> delete(BackgroundAnalysisLocalModel variant) async {}
}
