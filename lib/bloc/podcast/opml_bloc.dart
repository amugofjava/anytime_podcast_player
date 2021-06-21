// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class OPMLBloc extends Bloc {
  final log = Logger('OPMLBloc');
  final PublishSubject<String> _importFile = PublishSubject<String>();
  final PublishSubject<OPMLImportEvent> _importEvent = PublishSubject<OPMLImportEvent>();
  final OPMLService opmlService;

  OPMLBloc({@required this.opmlService}) {
    _init();
  }

  void _init() {
    _listenImportRequest();
  }

  void _listenImportRequest() {
    _importFile.listen((file) {
      log.fine('Received import request for $file');

      opmlService.loadOPMLFile(file).listen((event) {
        _importEvent.add(event);
      });
    });
  }

  void Function(String) get importFile => _importFile.add;
  Stream<OPMLImportEvent> get importEvent => _importEvent.stream;
}
