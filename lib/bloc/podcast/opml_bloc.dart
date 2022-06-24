// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class OPMLBloc extends Bloc {
  final log = Logger('OPMLBloc');

  final PublishSubject<OPMLEvent> _opmlEvent = PublishSubject<OPMLEvent>();
  final PublishSubject<OPMLState> _opmlState = PublishSubject<OPMLState>();
  final OPMLService opmlService;

  OPMLBloc({@required this.opmlService}) {
    _listendOpmlEvents();
  }

  void _listendOpmlEvents() {
    _opmlEvent.listen((event) {
      if (event is OPMLImportEvent) {
        opmlService.loadOPMLFile(event.file).listen((state) {
          _opmlState.add(state);
        });
      } else if (event is OPMLExportEvent) {
        opmlService.saveOPMLFile().listen((state) {
          _opmlState.add(state);
        });
      } else if (event is OPMLCancelEvent) {
        opmlService.cancel();
      }
    });
  }

  void Function(OPMLEvent) get opmlEvent => _opmlEvent.add;
  Stream<OPMLState> get opmlState => _opmlState.stream;
}
