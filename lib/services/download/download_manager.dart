// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/entities/downloadable.dart';

class DownloadProgress {
  final String id;
  final int percentage;
  final DownloadState status;

  DownloadProgress(
    this.id,
    this.percentage,
    this.status,
  );
}

abstract class DownloadManager {
  Future<String?> enqueueTask(String url, String downloadPath, String fileName);

  Future<void> pauseTask(String taskId);

  Future<void> resumeTask(String taskId);

  Future<void> cancelTask(String taskId);

  Future<String?> retryTask(String taskId);

  Stream<DownloadProgress> get downloadProgress;

  void dispose();
}
