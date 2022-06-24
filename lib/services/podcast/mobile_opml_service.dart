// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

class MobileOPMLService extends OPMLService {
  final log = Logger('MobileOPMLService');
  var process = false;

  final PodcastService podcastService;
  final Repository repository;

  MobileOPMLService({
    @required this.podcastService,
    @required this.repository,
  });

  @override
  Stream<OPMLState> loadOPMLFile(String file) async* {
    yield OPMLParsingState();

    process = true;

    final opmlFile = File(file);
    final document = XmlDocument.parse(opmlFile.readAsStringSync());
    final outlines = document.findAllElements('outline');
    final pods = <OmplOutlineTag>[];

    for (var outline in outlines) {
      pods.add(OmplOutlineTag.parse(outline));
    }

    var total = pods?.length ?? 0;
    var current = 0;

    for (var p in pods) {
      if (process) {
        yield OPMLLoadingState(
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
    }

    yield OPMLCompletedState();
  }

  @override
  Stream<OPMLState> saveOPMLFile() async* {
    var subs = await podcastService.subscriptions();

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: () {
          builder.text('Anytime Subscriptions');
        });
        builder.element('dateCreated', nest: () {
          var n = DateTime.now().toUtc();
          var f = DateFormat('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'').format(n);
          builder.text(f);
        });
      });

      builder.element('body', nest: () {
        for (var sub in subs) {
          builder.element('outline', nest: () {
            builder.attribute('text', sub.title);
            builder.attribute('xmlUrl', sub.url);
          });
        }
      });
    });

    final export = builder.buildDocument();

    var output = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    var outputFile = '${output.path}/anytime_export.opml';
    var file = File(outputFile);

    file.writeAsStringSync(export.toXmlString(pretty: true));

    await Share.shareFiles(
      [outputFile],
      mimeTypes: ['text/xml', 'application/xml'],
      subject: 'Anytime OPML',
    );

    yield OPMLCompletedState();
  }

  @override
  void cancel() {
    process = false;
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
