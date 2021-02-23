// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/podcast.dart';
import 'package:flutter/foundation.dart';

class Feed {
  final Podcast podcast;
  String imageUrl;
  String thumbImageUrl;
  bool refresh;

  Feed({
    @required this.podcast,
    this.imageUrl,
    this.thumbImageUrl,
    this.refresh = false,
  });
}
