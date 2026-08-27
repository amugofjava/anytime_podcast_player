// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/audio/ffmpeg_audio_converter_runner.dart';
import 'package:anytime/services/audio/mp3_converter_service.dart';
import 'package:anytime/services/download/download_manager.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:logging/logging.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:rxdart/rxdart.dart';

/// An implementation of a [DownloadService] that handles downloading
/// of episodes on mobile.
class MobileDownloadService extends DownloadService {
  static BehaviorSubject<DownloadProgress> downloadProgress = BehaviorSubject<DownloadProgress>();

  final log = Logger('MobileDownloadService');
  final Repository repository;
  final DownloadManager downloadManager;
  final PodcastService podcastService;

  /// Ensures downloaded episodes are saved as MP3. Injected so tests can
  /// substitute a fake; defaults to the real ffmpeg-backed converter.
  final Mp3ConverterService audioConverter;

  /// Reads user settings (e.g. whether to convert to MP3). When null, the
  /// shared settings singleton is used.
  final SettingsService? settingsService;

  MobileDownloadService({
    required this.repository,
    required this.downloadManager,
    required this.podcastService,
    Mp3ConverterService? audioConverter,
    this.settingsService,
  }) : audioConverter = audioConverter ?? Mp3ConverterService(FFmpegAudioConverterRunner()) {
    downloadManager.downloadProgress.pipe(downloadProgress);
    downloadProgress.listen((progress) {
      _updateDownloadProgress(progress);
    });
    recoverUnfinishedTranscodes();
  }

  @override
  void dispose() {
    downloadManager.dispose();
  }

  @override
  Future<bool> downloadEpisode(Episode episode) async {
    try {
      final season = episode.season > 0 ? episode.season.toString() : '';
      final epno = episode.episode > 0 ? episode.episode.toString() : '';
      var dirty = false;

      // If this episode contains chapter, fetch them first.
      if (episode.hasChapters && episode.chaptersUrl != null) {
        var chapters = await podcastService.loadChaptersByUrl(url: episode.chaptersUrl!);

        episode.chapters = chapters;

        dirty = true;
      }

      // Next, if the episode supports transcripts download that next. Vtt takes precedence, followed
      // by json then SRT.
      if (episode.hasTranscripts) {
        var sub = episode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.vtt);
        sub ??= episode.transcriptUrls.firstWhereOrNull((element) => element.type == TranscriptFormat.json);
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

      final episodePath = await resolveDirectory(episode: episode, settingsService: settingsService);
      final downloadPath = await resolveDirectory(episode: episode, full: true, settingsService: settingsService);
      var uri = Uri.parse(episode.contentUrl!);

      // Ensure the download directory exists
      await createDownloadDirectory(episode, settingsService: settingsService);

      var ext = '.mp3';
      final pathLower = uri.path.toLowerCase();
      if (pathLower.endsWith('.m4a')) {
        ext = '.m4a';
      } else if (pathLower.endsWith('.aac')) {
        ext = '.aac';
      } else if (pathLower.endsWith('.wav')) {
        ext = '.wav';
      } else if (pathLower.endsWith('.ogg')) {
        ext = '.ogg';
      } else if (pathLower.endsWith('.mp3')) {
        ext = '.mp3';
      } else {
        final seg = uri.pathSegments.lastWhereOrNull(
          (e) =>
              e.toLowerCase().contains('.mp3') || e.toLowerCase().contains('.m4a') || e.toLowerCase().contains('.aac'),
        );
        if (seg != null) {
          if (seg.toLowerCase().contains('.m4a')) ext = '.m4a';
          if (seg.toLowerCase().contains('.aac')) ext = '.aac';
          if (seg.toLowerCase().contains('.mp3')) ext = '.mp3';
        }
      }

      // Build publication date prefix: YYYY-MM-DD
      var pubDate = '';
      if (episode.publicationDate != null) {
        final d = episode.publicationDate!;
        pubDate =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      // Format episode title, preserving Chinese and Unicode characters
      var cleanTitle = safeFile(episode.title);
      if (cleanTitle == null || cleanTitle == 'episode' || cleanTitle.isEmpty) {
        final seg = uri.pathSegments.lastWhereOrNull((e) => e.isNotEmpty);
        cleanTitle = safeFile(seg) ?? 'episode_${episode.id ?? "unknown"}';
      }

      if (cleanTitle.toLowerCase().endsWith(ext)) {
        cleanTitle = cleanTitle.substring(0, cleanTitle.length - ext.length);
      }

      if (cleanTitle.length > 120) {
        cleanTitle = cleanTitle.substring(0, 120).trim();
      }

      final filename = pubDate.isNotEmpty ? '${pubDate}_$cleanTitle$ext' : '$cleanTitle$ext';

      log.fine('Download episode (${episode.title}) $filename to $downloadPath/$filename');

      final taskId = await downloadManager.enqueueTask(episode.contentUrl!, downloadPath, filename);

      // Update the episode with download data
      episode.filepath = episodePath;
      episode.filename = filename;
      episode.downloadTaskId = taskId;
      episode.downloadState = DownloadState.downloading;
      episode.downloadPercentage = 0;

      await repository.saveEpisode(episode);

      return true;
    } catch (e, stack) {
      log.warning('Episode download failed (${episode.title})', e, stack);
      return false;
    }
  }

  @override
  Future<Episode?> findEpisodeByTaskId(String taskId) {
    return repository.findEpisodeByTaskId(taskId);
  }

  @override
  Future<void> pauseDownload(Episode episode) async {
    if (episode.downloadTaskId != null && episode.downloadTaskId!.isNotEmpty) {
      await downloadManager.pauseTask(episode.downloadTaskId!);
    }
    episode.downloadState = DownloadState.paused;
    await repository.saveEpisode(episode);
  }

  @override
  Future<void> resumeDownload(Episode episode) async {
    if (episode.downloadTaskId != null && episode.downloadTaskId!.isNotEmpty) {
      await downloadManager.resumeTask(episode.downloadTaskId!);
      episode.downloadState = DownloadState.downloading;
      await repository.saveEpisode(episode);
    } else {
      await downloadEpisode(episode);
    }
  }

  @override
  Future<void> retryDownload(Episode episode) async {
    try {
      final filename = await resolvePath(episode);
      final file = File(filename);
      if (await file.exists() &&
          (episode.downloadState == DownloadState.converting || episode.downloadPercentage == 100)) {
        episode.downloadState = DownloadState.converting;
        episode.downloadPercentage = 0;
        await repository.saveEpisode(episode);

        final newFilename = await audioConverter.ensureMp3(
          filename,
          title: episode.title,
          artist: episode.podcast,
          album: episode.podcast,
          year: episode.publicationDate?.year.toString(),
          onProgress: (percent) {
            if (episode.downloadPercentage != percent) {
              episode.downloadPercentage = percent;
              repository.saveEpisode(episode);
            }
          },
        );

        final newBase = newFilename.split(Platform.isWindows ? '\\' : '/').last;
        episode.filename = newBase;
        episode.downloadPercentage = 100;
        episode.downloadState = DownloadState.downloaded;
        await repository.saveEpisode(episode);
        return;
      }
    } catch (_) {}

    await downloadEpisode(episode);
  }

  @override
  Future<void> cancelDownload(Episode episode) async {
    if (episode.downloadTaskId != null && episode.downloadTaskId!.isNotEmpty) {
      try {
        await downloadManager.cancelTask(episode.downloadTaskId!);
      } catch (_) {}
    }

    try {
      final filename = await resolvePath(episode);
      final file = File(filename);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    episode.downloadTaskId = null;
    episode.downloadPercentage = 0;
    episode.downloadState = DownloadState.none;
    episode.filename = null;
    await repository.saveEpisode(episode);
  }

  Future<void> _updateDownloadProgress(DownloadProgress progress) async {
    var episode = await repository.findEpisodeByTaskId(progress.id);

    if (episode != null) {
      // We might be called during the cleanup routine during startup.
      // Do not bother updating if nothing has changed.
      if (episode.downloadPercentage != progress.percentage || episode.downloadState != progress.status) {
        episode.downloadPercentage = progress.percentage;
        episode.downloadState = progress.status;

        if (progress.status == DownloadState.downloaded && progress.percentage == 100) {
          var filename = await resolvePath(episode);

          final settings = settingsService ?? await MobileSettingsService.instance();

          // If the user has enabled auto MP3 conversion, ensure the downloaded
          // file is an MP3. Otherwise (m4a/aac) it is transcoded and the
          // original removed, so `filename` now points at the MP3. When the
          // setting is off we keep the file exactly as downloaded.
          if ((settings?.convertToMp3 ?? true) && !isMp3Extension(filename)) {
            episode.downloadState = DownloadState.converting;
            episode.downloadPercentage = 0;
            await repository.saveEpisode(episode);

            filename = await audioConverter.ensureMp3(
              filename,
              title: episode.title,
              artist: episode.podcast,
              album: episode.podcast,
              year: episode.publicationDate?.year.toString(),
              onProgress: (percent) {
                if (episode.downloadPercentage != percent) {
                  episode.downloadPercentage = percent;
                  repository.saveEpisode(episode);
                }
              },
            );

            // Keep the stored episode filename in sync if conversion changed it.
            final newBase = filename.split(Platform.isWindows ? '\\' : '/').last;
            if (episode.filename != newBase) {
              episode.filename = newBase;
            }

            episode.downloadState = DownloadState.downloaded;
            episode.downloadPercentage = 100;
          }

          try {
            var mp3Info = MP3Processor.fromFile(File(filename));

            /// If we do not have PC2.0 chapters, maybe we have ID3 ones.
            if (!episode.hasChapters) {
              final tags = mp3Info.id3;

              if (tags != null && tags.chapters.isNotEmpty) {
                for (var chapter in tags.chapters) {
                  var ms = chapter.startTime;
                  var ss = ms / 1000;

                  episode.chapters.add(Chapter(
                    title: chapter.title ?? '',
                    imageUrl: null,
                    startTime: ss.toDouble(),
                    endTime: 0.0,
                  ));
                }
              }
            }

            // If we do not have a duration for this file - let's calculate it
            if (episode.duration == 0) {
              episode.duration = mp3Info.duration.inSeconds;
            }
          } catch (e, s) {
            log.warning('Error processing file $filename', e, s);
          }
        }

        await repository.saveEpisode(episode);
      }
    }
  }

  Future<void> recoverUnfinishedTranscodes() async {
    try {
      final settings = settingsService ?? await MobileSettingsService.instance();
      if (!(settings?.convertToMp3 ?? true)) return;

      final episodes = await repository.findEpisodesByDownloadState(DownloadState.converting);
      for (var episode in episodes) {
        var filename = await resolvePath(episode);
        if (File(filename).existsSync() && !isMp3Extension(filename)) {
          filename = await audioConverter.ensureMp3(
            filename,
            title: episode.title,
            artist: episode.podcast,
            album: episode.podcast,
            year: episode.publicationDate?.year.toString(),
            onProgress: (percent) {
              if (episode.downloadPercentage != percent) {
                episode.downloadPercentage = percent;
                repository.saveEpisode(episode);
              }
            },
          );

          final newBase = filename.split(Platform.isWindows ? '\\' : '/').last;
          if (episode.filename != newBase) {
            episode.filename = newBase;
          }
          episode.downloadState = DownloadState.downloaded;
          episode.downloadPercentage = 100;
          await repository.saveEpisode(episode);
        }
      }
    } catch (e, s) {
      log.warning('Error recovering unfinished transcodes', e, s);
    }
  }
}
