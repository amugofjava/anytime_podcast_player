// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/core/extensions.dart';
import 'package:flutter/foundation.dart';

enum TranscriptFormat {
  json,
  subrip,
  unsupported,
  vtt,
}

/// This class represents a Podcasting 2.0 transcript URL.
///
/// [docs](https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md#transcript)
class TranscriptUrl {
  final String url;
  final TranscriptFormat type;
  final String? language;
  final String? rel;
  final DateTime? lastUpdated;

  TranscriptUrl({
    required String url,
    required this.type,
    this.language = '',
    this.rel = '',
    this.lastUpdated,
  }) : url = url.forceHttps;

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
      case TranscriptFormat.vtt:
        t = 3;
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
    final ts = transcript['type'] as int? ?? 2;
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
      case 3:
        t = TranscriptFormat.vtt;
        break;
    }

    return TranscriptUrl(
      url: transcript['url'] as String,
      language: transcript['lang'] as String?,
      rel: transcript['rel'] as String?,
      type: t,
      lastUpdated: transcript['lastUpdated'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(transcript['lastUpdated'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptUrl &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          type == other.type &&
          language == other.language &&
          rel == other.rel;

  @override
  int get hashCode => url.hashCode ^ type.hashCode ^ language.hashCode ^ rel.hashCode;
}

/// This class represents a Podcasting 2.0 transcript container.
/// [docs](https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md#transcript)
class Transcript {
  int? id;
  String? guid;
  final List<Subtitle> subtitles;
  DateTime? lastUpdated;
  bool filtered;

  Transcript({
    this.id,
    this.guid,
    this.subtitles = const <Subtitle>[],
    this.filtered = false,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'subtitles': subtitles.map((subtitle) => subtitle.toMap()).toList(growable: false),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Transcript fromMap(int? key, Map<String, dynamic> transcript) {
    final subtitles = <Subtitle>[];

    if (transcript['subtitles'] != null) {
      for (final subtitle in (transcript['subtitles'] as List)) {
        if (subtitle is Map<String, dynamic>) {
          subtitles.add(Subtitle.fromMap(subtitle));
        }
      }
    }

    return Transcript(
      id: key,
      guid: transcript['guid'] as String? ?? '',
      subtitles: subtitles,
      lastUpdated: transcript['lastUpdated'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(transcript['lastUpdated'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transcript &&
          runtimeType == other.runtimeType &&
          guid == other.guid &&
          listEquals(subtitles, other.subtitles);

  @override
  int get hashCode => guid.hashCode ^ subtitles.hashCode;

  bool get transcriptAvailable => subtitles.isNotEmpty || filtered;
}

/// Represents an individual line within a transcript.
class Subtitle {
  final int index;
  final Duration start;
  Duration? end;
  String? data;
  String speaker;

  Subtitle({
    required this.index,
    required this.start,
    this.end,
    this.data,
    this.speaker = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'i': index,
      'start': start.inMilliseconds,
      'end': end!.inMilliseconds,
      'speaker': speaker,
      'data': data,
    };
  }

  static Subtitle fromMap(Map<String, dynamic> subtitle) {
    return Subtitle(
      index: subtitle['i'] as int? ?? 0,
      start: Duration(milliseconds: subtitle['start'] as int? ?? 0),
      end: Duration(milliseconds: subtitle['end'] as int? ?? 0),
      speaker: subtitle['speaker'] as String? ?? '',
      data: subtitle['data'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subtitle &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          start == other.start &&
          end == other.end &&
          data == other.data &&
          speaker == other.speaker;

  @override
  int get hashCode => index.hashCode ^ start.hashCode ^ end.hashCode ^ data.hashCode ^ speaker.hashCode;
}
