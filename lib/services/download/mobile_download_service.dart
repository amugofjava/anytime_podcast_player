// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logging/logging.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

class DownloadProgress {
  final String id;
  final int percentage;
  final DownloadState status;

  DownloadProgress(this.id, this.percentage, this.status);
}

/// An implementation of a [DownloadService] that handles downloading
/// of episodes on mobile.
class MobileDownloadService extends DownloadService {
  static BehaviorSubject<DownloadProgress> downloadProgress = BehaviorSubject<DownloadProgress>();

  final log = Logger('MobileDownloadService');

  @override
  final Repository repository;
  final ReceivePort _port = ReceivePort();

  MobileDownloadService({@required this.repository}) : super(repository: repository) {
    _init();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    downloadProgress.close();
  }

  @override
  Future<bool> downloadEpisode(Episode episode) async {
    final season = episode.season > 0 ? episode.season.toString() : '';
    final epno = episode.episode > 0 ? episode.episode.toString() : '';

    if (await hasStoragePermission()) {
      final e = await repository.findEpisodeByGuid(episode.guid);

      if (e != null) {
        episode = e;
      }

      if (await hasStoragePermission()) {
        final downloadPath = join(await getStorageDirectory(), safePath(episode.podcast));
        var uri = Uri.parse(episode.contentUrl);

        // Ensure the download directory exists
        Directory(downloadPath).createSync(recursive: true);

        // Filename should be last segment of URI.
        var filename = safePath(uri.pathSegments.firstWhere((e) => e.toLowerCase().endsWith('.mp3'), orElse: () => null));

        filename ??= safePath(uri.pathSegments.firstWhere((e) => e.toLowerCase().endsWith('.m4a'), orElse: () => null));

        if (filename == null) {
          //TODO: Handle unsupported format.
        } else {
          // The last segment could also be a full URL. Take a second pass.
          if (filename.contains('/')) {
            try {
              uri = Uri.parse(filename);
              filename = uri.pathSegments.last;
            } on FormatException {
              // It wasn't a URL...
            }
          }

          // Some podcasts use the same file name for each episode, but also set the
          // iTunes season and episode number values. If these are set, use them as
          // part of the file name.
          filename = '$season$epno$filename';

          log.fine('Download episode (${episode?.title}) $filename to $downloadPath');

          final taskId = await FlutterDownloader.enqueue(
            url: episode.contentUrl,
            savedDir: downloadPath,
            fileName: filename,
            showNotification: true,
            openFileFromNotification: false,
          );

          // Update the episode with download data
          episode.filepath = downloadPath;
          episode.filename = filename;
          episode.downloadTaskId = taskId;
          episode.downloadState = DownloadState.downloading;
          episode.downloadPercentage = 0;

          await repository.saveEpisode(episode);

          return Future.value(true);
        }
      }
    }

    return Future.value(false);
  }

  @override
  Future<Episode> findEpisodeByTaskId(String taskId) {
    return repository.findEpisodeByTaskId(taskId);
  }

  Future<void> _init() async {
    await FlutterDownloader.initialize();

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
        _saveDownload(DownloadProgress(id, progress, state));
        _clearDownload(id);
      } else if (status == DownloadTaskStatus.running) {
        state = DownloadState.downloading;
      } else if (status == DownloadTaskStatus.failed) {
        state = DownloadState.failed;
      } else if (status == DownloadTaskStatus.paused) {
        state = DownloadState.paused;
      }

      downloadProgress.add(DownloadProgress(id, progress, state));
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  Future<void> _saveDownload(DownloadProgress progress) async {
    var episode = await repository.findEpisodeByTaskId(progress.id);

    if (episode != null) {
      episode.downloadPercentage = progress.percentage;
      episode.downloadState = progress.status;

      if (progress.percentage == 100) {
        if (await hasStoragePermission()) {
          final filename = join(await getStorageDirectory(), safePath(episode.podcast), episode.filename);

          // If we do not have a duration for this file - let's calculate it
          if (episode.duration == 0) {
            var mp3Info = MP3Processor.fromFile(File(filename));

            episode.duration = mp3Info.duration.inSeconds;
          }

          await repository.saveEpisode(episode);
        }
      }
    }
  }

  Future<Null> _clearDownload(String id) {
    return FlutterDownloader.remove(taskId: id, shouldDeleteContent: false);
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');

    send.send([id, status, progress]);
  }
}
