// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

class MobileOPMLService extends OPMLService {
  final log = Logger('MobileOPMLService');

  @override
  final PodcastService podcastService;

  @override
  final Repository repository;

  MobileOPMLService({
    @required this.podcastService,
    @required this.repository,
  });

  @override
  Stream<OPMLImportEvent> loadOPMLFile(String file) async* {
    yield OPMLImportEvent(state: OPMLImportState.parse);

    final opmlFile = File(file);
    final document = XmlDocument.parse(opmlFile.readAsStringSync());
    final outlines = document.findAllElements('outline');
    final pods = <OmplOutlineTag>[];

    for (var x in outlines) {
      pods.add(OmplOutlineTag.parse(x));
    }

    var total = pods?.length ?? 0;
    var current = 0;

    for (var p in pods) {
      yield OPMLImportEvent(
        state: OPMLImportState.load,
        current: ++current,
        total: total,
        podcast: p.text,
      );

      try {
        log.fine('Importing podcast ${p.xmlUrl}');

        var result = await podcastService.loadPodcast(
          podcast: Podcast(guid: '', link: '', title: p.text, url: p.xmlUrl),
          refresh: true,
        );

        await podcastService.subscribe(result);
      } on Exception {
        log.fine('Failed to load podcast ${p.xmlUrl}');
      }
    }

    yield OPMLImportEvent(state: OPMLImportState.complete);
  }
}

class OmplOutlineTag {
  final String text;
  final String xmlUrl;

  OmplOutlineTag({
    this.text,
    this.xmlUrl,
  });

  factory OmplOutlineTag.parse(XmlElement element) {
    return OmplOutlineTag(
      text: element.getAttribute('text')?.trim(),
      xmlUrl: element.getAttribute('xmlUrl')?.trim(),
    );
  }
}
