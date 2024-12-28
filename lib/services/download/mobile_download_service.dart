// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/download/download_manager.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logging/logging.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

/// An implementation of a [DownloadService] that handles downloading
/// of episodes on mobile.
class MobileDownloadService extends DownloadService {
  static BehaviorSubject<DownloadProgress> downloadProgress = BehaviorSubject<DownloadProgress>();

  final log = Logger('MobileDownloadService');
  final Repository repository;
  final SettingsService settingsService;
  final DownloadManager downloadManager;
  final PodcastService podcastService;

  late final StreamSubscription _downloadProgressSubscription;

  /// Lock ensures we wait for task creation and local save
  /// before handling subsequent [Download update events].
  final _downloadLock = Lock();

  MobileDownloadService({
    required this.repository,
    required this.downloadManager,
    required this.settingsService,
    required this.podcastService,
  }) {
    _downloadProgressSubscription = downloadManager.downloadProgress.listen(
      (progress) async => await _downloadLock.synchronized(
        () {
          downloadProgress.add(progress);
          _updateDownloadProgress(progress);
        },
      ),
    );
  }

  @override
  void dispose() {
    downloadManager.dispose();
    _downloadProgressSubscription.cancel();
  }

  @override
  Future<void> downloadEpisode(Episode episode) async {
    try {
      final season = episode.season > 0 ? episode.season.toString() : '';
      final epno = episode.episode > 0 ? episode.episode.toString() : '';
      var dirty = false;

      if (await hasStoragePermission()) {
        // If this episode contains chapter, fetch them first.
        if (episode.hasChapters && episode.chaptersUrl != null) {
          var chapters = await podcastService.loadChaptersByUrl(url: episode.chaptersUrl!);

          episode.chapters = chapters;

          dirty = true;
        }

        // Next, if the episode supports transcripts download that next
        if (episode.hasTranscripts) {
          var sub = episode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.json);

          sub ??= episode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.subrip);

          if (sub != null) {
            var transcript = await podcastService.loadTranscriptByUrl(transcriptUrl: sub);

            transcript = await podcastService.saveTranscript(transcript);

            episode.transcript = transcript;
            episode.transcriptId = transcript.id;

            dirty = true;
          }
        }

        if (dirty) {
          await podcastService.saveEpisode(episode);
        }

        final episodePath = await resolveDirectory(episode: episode);
        final downloadPath = await resolveDirectory(episode: episode, full: true);
        var uri = Uri.parse(episode.contentUrl!);

        // Ensure the download directory exists
        await createDownloadDirectory(episode);

        // Filename should be last segment of URI.
        var filename = safeFile(uri.pathSegments.lastWhereOrNull((e) => e.toLowerCase().endsWith('.mp3')));

        filename ??= safeFile(uri.pathSegments.lastWhereOrNull((e) => e.toLowerCase().endsWith('.m4a')));

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
            pubDate = '${episode.publicationDate!.millisecondsSinceEpoch ~/ 1000}-';
          }

          filename = '$season$epno$pubDate$filename';

          log.fine('Download episode (${episode.title}) $filename to $downloadPath/$filename');

          /// If we get a redirect to an http endpoint the download will fail. Let's fully resolve
          /// the URL before calling download and ensure it is https.
          var url = await resolveUrl(episode.contentUrl!, forceHttps: true);

          await _downloadLock.synchronized(() async {
            final taskId = await downloadManager.enqueueTask(url, downloadPath, filename!);

            // Update the episode with download data
            episode.filepath = episodePath;
            episode.filename = filename;
            episode.downloadTaskId = taskId;
            episode.downloadState = DownloadState.downloading;
            episode.downloadPercentage = 0;

            await repository.saveEpisode(episode);
          });
        }
      }
    } catch (e, stack) {
      log.warning('Episode download failed (${episode.title})', e, stack);
      episode.filename = null;
      episode.filepath = null;
      episode.downloadTaskId = null;
      episode.downloadPercentage = 0;
      episode.downloadState = DownloadState.none;

      await repository.saveEpisode(episode);

      /// If there was an error downloading the episode, push an error state
      /// and then restore to none.
      ///
      /// If failure happens before download actual start, its [id] will be [null].
      final downloadId = episode.downloadTaskId ?? const Uuid().v4();
      downloadProgress
        ..add(DownloadProgress(
          downloadId,
          0,
          DownloadState.failed,
        ))
        ..add(DownloadProgress(
          downloadId,
          0,
          DownloadState.none,
        ));
    }
  }

  @override
  Future<void> deleteDownload(Episode episode) async => _downloadLock.synchronized(() async {
        // If this episode is currently downloading, cancel the download first.
        if (episode.downloadState == DownloadState.downloaded) {
          if (settingsService.markDeletedEpisodesAsPlayed) {
            episode.played = true;
          }
        } else if (episode.downloadState == DownloadState.downloading && episode.downloadPercentage! < 100) {
          await FlutterDownloader.cancel(taskId: episode.downloadTaskId!);
        }

        episode.downloadTaskId = null;
        episode.downloadPercentage = 0;
        episode.position = 0;
        episode.downloadState = DownloadState.none;

        if (episode.transcriptId != null && episode.transcriptId! > 0) {
          await repository.deleteTranscriptById(episode.transcriptId!);
        }

        await repository.saveEpisode(episode);

        if (await hasStoragePermission()) {
          final f = File.fromUri(Uri.file(await resolvePath(episode)));

          log.fine('Deleting file ${f.path}');

          if (await f.exists()) {
            f.delete();
          }
        }

        // downloadProgress.add(DownloadProgress(
        //   episode.downloadTaskId!,
        //   0,
        //   DownloadState.none,
        // ));

        return;
      });

  @override
  Future<Episode?> findEpisodeByTaskId(String taskId) {
    return repository.findEpisodeByTaskId(taskId);
  }

  Future<void> _updateDownloadProgress(DownloadProgress progress) async {
    var episode = await repository.findEpisodeByTaskId(progress.id);

    if (episode != null) {
      // We might be called during the cleanup routine during startup.
      // Do not bother updating if nothing has changed.
      if (episode.downloadPercentage != progress.percentage || episode.downloadState != progress.status) {
        episode.downloadPercentage = progress.percentage;
        episode.downloadState = progress.status;

        if (progress.percentage == 100) {
          if (await hasStoragePermission()) {
            final filename = await resolvePath(episode);

            // If we do not have a duration for this file - let's calculate it
            if (episode.duration == 0) {
              var mp3Info = MP3Processor.fromFile(File(filename));

              episode.duration = mp3Info.duration.inSeconds;
            }
          }
        }

        await repository.saveEpisode(episode);
      }
    }
  }
}
