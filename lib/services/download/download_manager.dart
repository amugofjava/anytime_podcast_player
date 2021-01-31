// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:anytime/entities/downloadable.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logging/logging.dart';

class DownloadProgress {
  final String id;
  final int percentage;
  final DownloadState status;

  DownloadProgress(this.id, this.percentage, this.status);
}

abstract class DownloadManager {
  Future<String> enqueTask(String url, String downloadPath, String fileName);
  Stream<DownloadProgress> get downloadProgress;
  void dispose();
}

class FlutterDownloaderManager implements DownloadManager {
  final log = Logger('FlutterDownloaderManager');
  final ReceivePort _port = ReceivePort();
  final downloadController = StreamController<DownloadProgress>();

  @override
  Stream<DownloadProgress> get downloadProgress => downloadController.stream;

  FlutterDownloaderManager() {
    _init();
  }

  Future _init() async {
    log.fine('Initialising download manager');
    await FlutterDownloader.initialize();

    await IsolateNameServer.removePortNameMapping('downloader_send_port');

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      final id = data[0] as String;
      final status = data[1] as DownloadTaskStatus;
      final progress = data[2] as int;

      var state = DownloadState.none;

      if (status == DownloadTaskStatus.enqueued) {
        state = DownloadState.queued;
      } else if (status == DownloadTaskStatus.canceled) {
        state = DownloadState.cancelled;
      } else if (status == DownloadTaskStatus.complete) {
        state = DownloadState.downloaded;
      } else if (status == DownloadTaskStatus.running) {
        state = DownloadState.downloading;
      } else if (status == DownloadTaskStatus.failed) {
        state = DownloadState.failed;
      } else if (status == DownloadTaskStatus.paused) {
        state = DownloadState.paused;
      }

      downloadController.add(DownloadProgress(id, progress, state));
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  Future<String> enqueTask(String url, String downloadPath, String fileName) async {
    return await FlutterDownloader.enqueue(
      url: url,
      savedDir: downloadPath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: false,
    );
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    downloadController.close();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');

    send.send([id, status, progress]);
  }
}
