// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/analysis/background/analysis_model_catalog.dart';
import 'package:anytime/services/analysis/background/background_analysis_scheduler.dart';
import 'package:anytime/services/analysis/background/background_analysis_service.dart';
import 'package:anytime/services/analysis/background/background_analysis_worker.dart';
import 'package:anytime/services/analysis/background/gemma_ad_analyzer.dart';
import 'package:anytime/services/analysis/background/model_download_service.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/transcription/whisper_episode_transcription_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

final Logger _log = Logger('BackgroundAnalysisDispatcher');

/// Entry point invoked by `WorkManager` in a background isolate. Must be a
/// top-level function and annotated `vm:entry-point` so the Dart runtime
/// preserves it through tree-shaking.
///
/// This mirrors the minimal bootstrapping required inside the isolate: the
/// isolate owns no state from the UI process, so we construct a fresh
/// repository, settings service, transcription service, and Gemma analyzer,
/// then delegate to `BackgroundAnalysisWorker.runNext()`.
@pragma('vm:entry-point')
void backgroundAnalysisCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundAnalysisTaskName) {
      _log.warning('Unexpected task name in dispatcher: $taskName');
      return true;
    }
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await FlutterGemma.initialize();
      await runBackgroundAnalysisOnce();
      return true;
    } catch (error, stack) {
      _log.severe('Background analysis dispatcher failed', error, stack);
      // Return true so WorkManager doesn't hammer retries — the worker has
      // already recorded `BackgroundAnalysisStage.failed` where appropriate
      // and the episode remains queued for the next cycle.
      return true;
    }
  });
}

/// One pass of the background pipeline: dequeue-and-run a single episode.
/// Exposed for instrumentation and manual triggering from developer tools.
Future<void> runBackgroundAnalysisOnce() async {
  final settingsService = await MobileSettingsService.instance();
  if (settingsService == null) {
    _log.warning('Settings service unavailable; skipping background run');
    return;
  }

  if (!settingsService.backgroundAnalysisEnabled) {
    _log.fine('Background analysis disabled; nothing to do');
    return;
  }

  final repository = SembastRepository(cleanup: false);
  final transcriptionService = WhisperEpisodeTranscriptionService();
  final analysisService = DefaultBackgroundAnalysisService(repository);

  final variant = settingsService.backgroundLocalModel;
  var modelId = AnalysisModelCatalog.modelIdFor(variant);

  // Smoke-test override (dev-only). If `<app-support>/smoke_test_model.task`
  // exists, use it directly and bypass the catalog/download flow. Lets us
  // bisect MediaPipe vs Gemma3n-specific crashes without rewiring downloads.
  final supportDir = await getApplicationSupportDirectory();
  final smokePath = p.join(supportDir.path, 'smoke_test_model.task');
  String? overridePath;
  if (File(smokePath).existsSync()) {
    overridePath = smokePath;
    modelId = 'smoke-test:${p.basename(smokePath)}';
    _log.info('Using smoke-test model at $smokePath');
  }

  final downloadService = FlutterGemmaModelDownloadService();
  final modelPath = overridePath ?? await downloadService.resolveLocalPath(variant);
  if (modelPath == null) {
    _log.warning('Gemma model not installed yet for $variant; skipping run');
    return;
  }

  final analyzer = FlutterGemmaAdAnalyzer(modelFilePath: modelPath);

  final worker = BackgroundAnalysisWorker(
    repository: repository,
    transcriptionService: transcriptionService,
    gemmaAnalyzer: analyzer,
    service: analysisService,
    modelId: modelId,
  );

  try {
    await worker.runNext();
  } finally {
    await analyzer.close();
  }
}
