// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

class Chapter {
  int id;
  final String title;
  final String imageUrl;
  final String url;
  final bool toc;
  final double startTime;
  final double endTime;

  Chapter({
    @required this.title,
    @required this.imageUrl,
    @required this.url,
    @required this.toc,
    @required this.startTime,
    @required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'imageUrl': imageUrl,
      'url': url,
      'toc': toc ? 'true' : 'false',
      'startTime': startTime.toString(),
      'endTime': endTime.toString(),
    };
  }

  static Chapter fromMap(Map<String, dynamic> chapter) {
    return Chapter(
      title: chapter['title'] as String,
      imageUrl: chapter['imageUrl'] as String,
      url: chapter['url'] as String,
      toc: chapter['toc'] == 'true' ? true : false,
      startTime: double.parse(chapter['startTime'] as String),
      endTime: double.parse(chapter['endTime'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter && runtimeType == other.runtimeType && title == other.title && startTime == other.startTime;

  @override
  int get hashCode => title.hashCode ^ startTime.hashCode;
}
