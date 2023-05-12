// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:meta/meta.dart';

enum TranscriptFormat {
  json,
  subrip,
  unsupported,
}

/// This class represents a Podcasting 2.0 transcript URL.
/// [docs](https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md#transcript)
class TranscriptUrl {
  final String url;
  final TranscriptFormat type;
  final String language;
  final String rel;
  final DateTime lastUpdated;

  TranscriptUrl({
    @required this.url,
    @required this.type,
    this.language = '',
    this.rel = '',
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    var t = 0;

    switch (type) {
      case TranscriptFormat.subrip:
        t = 0;
        break;
      case TranscriptFormat.json:
        t = 1;
        break;
      case TranscriptFormat.unsupported:
        t = 2;
        break;
    }

    return <String, dynamic>{
      'url': url,
      'type': t,
      'lang': language,
      'rel': rel,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static TranscriptUrl fromMap(Map<String, dynamic> transcript) {
    var ts = transcript['type'] as int ?? 2;
    var t = TranscriptFormat.unsupported;

    switch (ts) {
      case 0:
        t = TranscriptFormat.subrip;
        break;
      case 1:
        t = TranscriptFormat.json;
        break;
      case 2:
        t = TranscriptFormat.unsupported;
        break;
    }

    return TranscriptUrl(
      url: transcript['url'] as String,
      language: transcript['lang'] as String,
      rel: transcript['rel'] as String,
      type: t,
      lastUpdated: transcript['lastUpdated'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(transcript['lastUpdated'] as int),
    );
  }
}

class Transcript {
  int id;
  final String guid;
  final List<Subtitle> subtitles;
  DateTime lastUpdated;
  final _chunks = <List<Subtitle>>[];

  Transcript({
    this.id,
    this.guid,
    this.subtitles = const <Subtitle>[],
    this.lastUpdated,
  });

  List<List<Subtitle>> conversational() {
    if (_chunks.isEmpty) {
      Subtitle lastChunk;
      var block = <Subtitle>[];

      for (var s in subtitles) {
        lastChunk ??= s;

        if (s.end.inMilliseconds - lastChunk.end.inMilliseconds > 1000) {
          _chunks.add(block);
          block = <Subtitle>[];
        }

        block.add(s);
      }
    }

    return _chunks;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'subtitles': (subtitles ?? <Subtitle>[]).map((subtitle) => subtitle.toMap())?.toList(growable: false),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Transcript fromMap(int key, Map<String, dynamic> transcript) {
    var subtitles = <Subtitle>[];

    if (transcript['subtitles'] != null) {
      for (var subtitle in (transcript['subtitles'] as List)) {
        if (subtitle is Map<String, dynamic>) {
          subtitles.add(Subtitle.fromMap(subtitle));
        }
      }
    }

    return Transcript(
      guid: transcript['guid'] as String ?? '',
      subtitles: subtitles,
      lastUpdated: transcript['lastUpdated'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(transcript['lastUpdated'] as int),
    );
  }
}

class Subtitle {
  final int index;
  final Duration start;
  Duration end;
  String data;
  String speaker;

  Subtitle({
    @required this.index,
    @required this.start,
    this.end,
    this.data,
    this.speaker = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'i': index,
      'start': start.inMilliseconds,
      'end': end.inMilliseconds,
      'speaker': speaker,
      'data': data,
    };
  }

  static Subtitle fromMap(Map<String, dynamic> subtitle) {
    return Subtitle(
      index: subtitle['i'] as int ?? 0,
      start: Duration(milliseconds: subtitle['start'] as int ?? 0),
      end: Duration(milliseconds: subtitle['end'] as int ?? 0),
      speaker: subtitle['speaker'] as String ?? '',
      data: subtitle['data'] as String ?? '',
    );
  }
}
