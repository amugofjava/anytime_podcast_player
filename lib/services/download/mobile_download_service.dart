// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/download/download_manager.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logging/logging.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

/// An implementation of a [DownloadService] that handles downloading
/// of episodes on mobile.
class MobileDownloadService extends DownloadService {
  static BehaviorSubject<DownloadProgress> downloadProgress = BehaviorSubject<DownloadProgress>();

  final log = Logger('MobileDownloadService');

  @override
  final Repository repository;
  final DownloadManager downloadManager;

  MobileDownloadService({@required this.repository, @required this.downloadManager}) : super(repository: repository) {
    downloadManager.downloadProgress.pipe(downloadProgress);
    downloadProgress.listen((progress) {
      if (progress.status == DownloadState.downloaded) {
        _saveDownload(progress);
        FlutterDownloader.remove(taskId: progress.id, shouldDeleteContent: false);
      }
    });
  }

  @override
  void dispose() {
    downloadManager.dispose();
  }

  @override
  Future<bool> downloadEpisode(Episode episode) async {
    final season = episode.season > 0 ? episode.season.toString() : '';
    final epno = episode.episode > 0 ? episode.episode.toString() : '';

    if (await hasStoragePermission()) {
      final savedEpisode = await repository.findEpisodeByGuid(episode.guid);

      if (savedEpisode != null) {
        episode = savedEpisode;
      }

      final downloadPath = join(await getStorageDirectory(), safePath(episode.podcast));
      var uri = Uri.parse(episode.contentUrl);

      // Ensure the download directory exists
      Directory(downloadPath).createSync(recursive: true);

      // Filename should be last segment of URI.
      var filename = safePath(uri.pathSegments.lastWhere((e) => e.toLowerCase().endsWith('.mp3'), orElse: () => null));

      filename ??= safePath(uri.pathSegments.lastWhere((e) => e.toLowerCase().endsWith('.m4a'), orElse: () => null));

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

        // Some podcasts use the same file name for each episode. If we have a
        // season and/or episode number provided by iTunes we can use that. We
        // will also append the filename with the publication date if available.
        var pubDate = '';

        if (episode.publicationDate != null) {
          pubDate = '${episode.publicationDate.millisecondsSinceEpoch ~/ 1000}-';
        }

        filename = '$season$epno$pubDate$filename';

        log.fine('Download episode (${episode?.title}) $filename to $downloadPath');

        final taskId = await downloadManager.enqueTask(episode.contentUrl, downloadPath, filename);

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

    return Future.value(false);
  }

  @override
  Future<Episode> findEpisodeByTaskId(String taskId) {
    return repository.findEpisodeByTaskId(taskId);
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
}
