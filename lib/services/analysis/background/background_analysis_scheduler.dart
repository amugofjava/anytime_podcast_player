// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

/// Unique name registered with Android `WorkManager`. Used for enqueue,
/// cancel, and status checks (spec §4.7).
const String backgroundAnalysisWorkName = 'anytime.background_analysis';

/// Task name passed through to the callback dispatcher. Matched in
/// `Workmanager().executeTask` to route to the analysis worker.
const String backgroundAnalysisTaskName = 'anytime.background_analysis.run';

/// Thin facade around `Workmanager` so the BLoC / settings code doesn't reach
/// into the plugin directly, and so tests can substitute a fake.
abstract class BackgroundAnalysisScheduler {
  /// Ensures the periodic job is registered with `KEEP` semantics. Safe to
  /// call repeatedly — the unique name keeps this idempotent.
  Future<void> schedule();

  /// Cancels the periodic job if registered. Safe to call when nothing is
  /// scheduled.
  Future<void> cancel();

  /// Returns true if the job is currently enqueued or running.
  Future<bool> isScheduled();
}

class WorkManagerBackgroundAnalysisScheduler implements BackgroundAnalysisScheduler {
  static const Duration _frequency = Duration(hours: 6);
  static const Duration _initialDelay = Duration(minutes: 15);

  final Workmanager _workmanager;
  final _log = Logger('WorkManagerBackgroundAnalysisScheduler');

  WorkManagerBackgroundAnalysisScheduler({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  @override
  Future<void> schedule() async {
    _log.fine('Scheduling periodic background analysis');
    await _workmanager.registerPeriodicTask(
      backgroundAnalysisWorkName,
      backgroundAnalysisTaskName,
      frequency: _frequency,
      initialDelay: _initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresCharging: true,
        requiresDeviceIdle: true,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }

  @override
  Future<void> cancel() async {
    _log.fine('Cancelling periodic background analysis');
    await _workmanager.cancelByUniqueName(backgroundAnalysisWorkName);
  }

  @override
  Future<bool> isScheduled() {
    return _workmanager.isScheduledByUniqueName(backgroundAnalysisWorkName);
  }
}

/// Scheduler used on platforms where `WorkManager` is unavailable (iOS in
/// this phase, desktop, tests). All operations succeed silently.
class NoopBackgroundAnalysisScheduler implements BackgroundAnalysisScheduler {
  const NoopBackgroundAnalysisScheduler();

  @override
  Future<void> schedule() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> isScheduled() async => false;
}
