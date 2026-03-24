// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';

abstract class AdSkipState {
  final Episode episode;
  final AdSegment segment;

  const AdSkipState({
    required this.episode,
    required this.segment,
  });
}

class AdSkipPromptState extends AdSkipState {
  const AdSkipPromptState({
    required super.episode,
    required super.segment,
  });
}

class AdSkipClearedState extends AdSkipState {
  const AdSkipClearedState({
    required super.episode,
    required super.segment,
  });
}
