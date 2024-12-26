// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/podcast.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/opml_state.dart';
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
    required this.podcastService,
    required this.repository,
  });

  @override
  Stream<OPMLState> loadOPMLFile(String file) async* {
    yield OPMLParsingState();

    process = true;

    final opmlFile = File(file);
    final document = XmlDocument.parse(opmlFile.readAsStringSync());
    final outlines = document.findAllElements('outline');
    final pods = <OmplOutlineTag>[];

    for (final outline in outlines) {
      pods.add(OmplOutlineTag.parse(outline));
    }

    final total = pods.length;
    var current = 0;

    for (final p in pods) {
      if (process) {
        yield OPMLLoadingState(
          current: ++current,
          total: total,
          podcast: p.text,
        );

        try {
          log.fine('Importing podcast ${p.xmlUrl}');

          final result = await podcastService.loadPodcast(
            podcast: Podcast(guid: '', link: '', title: p.text!, url: p.xmlUrl!),
            refresh: true,
          );

          if (result != null) {
            await podcastService.subscribe(result);
          }
        } catch (e) {
          log.fine('Failed to load podcast ${p.xmlUrl}');
        }
      }
    }

    yield OPMLCompletedState();
  }

  @override
  Stream<OPMLState> saveOPMLFile() async* {
    final subs = await podcastService.subscriptions();

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: () {
          builder.text('Anytime Subscriptions');
        });
        builder.element('dateCreated', nest: () {
          final n = DateTime.now().toUtc();
          final f = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(n);
          builder.text(f);
        });
      });

      builder.element('body', nest: () {
        for (final sub in subs) {
          builder.element('outline', nest: () {
            builder.attribute('text', sub.title);
            builder.attribute('xmlUrl', sub.url);
          });
        }
      });
    });

    final export = builder.buildDocument();

    final output = Platform.isAndroid ? (await getExternalStorageDirectory())! : await getApplicationDocumentsDirectory();
    final outputFile = '${output.path}/anytime_export.opml';
    final file = File(outputFile);

    file.writeAsStringSync(export.toXmlString(pretty: true));

    await Share.shareXFiles(
      [XFile(outputFile)],
      text: 'Anytime OPML',
    );

    yield OPMLCompletedState();
  }

  @override
  void cancel() {
    process = false;
  }
}

class OmplOutlineTag {
  final String? text;
  final String? xmlUrl;

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
