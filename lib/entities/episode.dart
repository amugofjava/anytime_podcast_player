// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/downloadable.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:logging/logging.dart';

/// An object that represents an individual episode of a Podcast. An Episode can
/// be used in conjunction with a [Downloadable] to determine if the Episode
/// is available on the local filesystem.
class Episode {
  final log = Logger('Episode');

  final String guid;
  String pguid;
  int id;
  String downloadTaskId;
  String filepath;
  String filename;
  DownloadState downloadState = DownloadState.none;
  String podcast;
  String title;
  String description;
  String link;
  String imageUrl;
  String thumbImageUrl;
  DateTime publicationDate;
  String contentUrl;
  String author;
  int season;
  int episode;
  int duration;
  int position;
  int downloadPercentage;
  bool played;
  String chaptersUrl;
  String _descriptionText;
  List<Chapter> chapters;
  DateTime lastUpdated;

  // Index of the currently playing chapter it available. Transient.
  int chapterIndex;
  Chapter currentChapter;

  Episode({
    @required this.guid,
    @required this.pguid,
    @required this.podcast,
    this.id,
    this.downloadTaskId,
    this.filepath,
    this.filename,
    this.downloadState = DownloadState.none,
    this.title,
    this.description,
    this.link,
    this.imageUrl,
    this.thumbImageUrl,
    this.publicationDate,
    this.contentUrl,
    this.author,
    this.season = 0,
    this.episode = 0,
    this.duration = 0,
    this.position = 0,
    this.downloadPercentage = 0,
    this.played = false,
    this.chaptersUrl,
    this.chapters,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'pguid': pguid,
      'downloadTaskId': downloadTaskId,
      'filepath': filepath,
      'filename': filename,
      'downloadState': downloadState.index,
      'podcast': podcast,
      'title': title,
      'description': description,
      'link': link,
      'imageUrl': imageUrl,
      'thumbImageUrl': thumbImageUrl,
      'publicationDate': publicationDate?.millisecondsSinceEpoch.toString(),
      'contentUrl': contentUrl,
      'author': author,
      'season': season.toString(),
      'episode': episode.toString(),
      'duration': duration.toString(),
      'position': position.toString(),
      'downloadPercentage': downloadPercentage.toString(),
      'played': played ? 'true' : 'false',
      'chaptersUrl': chaptersUrl,
      'chapters': (chapters ?? <Chapter>[]).map((chapter) => chapter.toMap())?.toList(growable: false),
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch.toString() ?? '',
    };
  }

  static Episode fromMap(int key, Map<String, dynamic> episode) {
    var chapters = <Chapter>[];

    // We need to perform an 'is' on each loop to prevent Dart
    // from complaining that we have not set the type for chapter.
    if (episode['chapters'] != null) {
      for (var chapter in (episode['chapters'] as List)) {
        if (chapter is Map<String, dynamic>) {
          chapters.add(Chapter.fromMap(chapter));
        }
      }
    }

    return Episode(
      id: key,
      guid: episode['guid'] as String,
      pguid: episode['pguid'] as String,
      downloadTaskId: episode['downloadTaskId'] as String,
      filepath: episode['filepath'] as String,
      filename: episode['filename'] as String,
      downloadState: _determineState(episode['downloadState'] as int),
      podcast: episode['podcast'] as String,
      title: episode['title'] as String,
      description: episode['description'] as String,
      link: episode['link'] as String,
      imageUrl: episode['imageUrl'] as String,
      thumbImageUrl: episode['thumbImageUrl'] as String,
      publicationDate: episode['publicationDate'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(int.parse(episode['publicationDate'] as String)),
      contentUrl: episode['contentUrl'] as String,
      author: episode['author'] as String,
      season: int.parse(episode['season'] as String ?? '0'),
      episode: int.parse(episode['episode'] as String ?? '0'),
      duration: int.parse(episode['duration'] as String ?? '0'),
      position: int.parse(episode['position'] as String ?? '0'),
      downloadPercentage: int.parse(episode['downloadPercentage'] as String ?? '0'),
      played: episode['played'] == 'true' ? true : false,
      chaptersUrl: episode['chaptersUrl'] as String,
      chapters: chapters,
      lastUpdated: episode['lastUpdated'] == null || episode['lastUpdated'] == 'null'
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(int.parse(episode['lastUpdated'] as String)),
    );
  }

  static DownloadState _determineState(int index) {
    switch (index) {
      case 0:
        return DownloadState.none;
        break;
      case 1:
        return DownloadState.queued;
        break;
      case 2:
        return DownloadState.downloading;
        break;
      case 3:
        return DownloadState.failed;
        break;
      case 4:
        return DownloadState.cancelled;
        break;
      case 5:
        return DownloadState.paused;
        break;
      case 6:
        return DownloadState.downloaded;
        break;
    }

    return DownloadState.none;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Episode && runtimeType == other.runtimeType && guid == other.guid && pguid == other.pguid;

  @override
  int get hashCode => guid.hashCode ^ pguid.hashCode;

  bool get downloaded => downloadPercentage == 100;

  Duration get timeRemaining {
    if (position > 0 && duration > 0) {
      var currentPosition = Duration(milliseconds: position);

      var tr = duration - currentPosition.inSeconds;

      return Duration(seconds: tr);
    }

    return Duration(seconds: 0);
  }

  double get percentagePlayed {
    if (position > 0 && duration > 0) {
      var pc = (position / (duration * 1000)) * 100;

      if (pc > 100.0) {
        log.info('ERROR: Calculated episode percentage played over 100%');
        log.info('       - position $position; duration in seconds ${duration * 1000}');
        pc = 100.0;
      }

      return pc;
    }

    return 0.0;
  }

  String get descriptionText {
    if (_descriptionText == null || _descriptionText.isEmpty) {
      if (description == null || description.isEmpty) {
        _descriptionText = '';
      } else {
        _descriptionText = parseFragment(description).text;
      }
    }

    return _descriptionText;
  }

  bool get hasChapters => chaptersUrl != null && chaptersUrl.isNotEmpty;
  bool get chaptersAreLoaded => chapters != null && chapters.isNotEmpty;
  bool get chaptersAreNotLoaded => chapters == null || chapters.isEmpty;

  String get positionalImageUrl {
    if (currentChapter != null && currentChapter.imageUrl != null && currentChapter.imageUrl.isNotEmpty) {
      return currentChapter.imageUrl;
    }

    return imageUrl;
  }
}
