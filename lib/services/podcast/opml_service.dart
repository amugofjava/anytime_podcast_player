// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:flutter/material.dart';

enum OPMLImportState {
  none,
  parse,
  load,
  complete,
  error,
}

class OPMLImportEvent {
  final OPMLImportState state;
  final int current;
  final int total;
  final String podcast;

  OPMLImportEvent({
    @required this.state,
    this.current,
    this.total,
    this.podcast,
  });
}

abstract class OPMLService {
  final PodcastService podcastService;
  final Repository repository;

  OPMLService({
    @required this.podcastService,
    @required this.repository,
  });

  Stream<OPMLImportEvent> loadOPMLFile(String file);
}
