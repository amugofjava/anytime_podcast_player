// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/repository/repository.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:flutter/material.dart';

/// This service handles the import and export of Podcasts via
/// the OPML format.
abstract class OPMLService {
  final PodcastService podcastService;
  final Repository repository;

  OPMLService({
    @required this.podcastService,
    @required this.repository,
  });

  Stream<OPMLState> loadOPMLFile(String file);
  Stream<OPMLState> saveOPMLFile();
  void cancel();
}
