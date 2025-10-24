// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/podcast_image.dart';
import 'package:flutter/material.dart';

class TileImage extends StatelessWidget {
  const TileImage({
    super.key,
    required this.url,
    required this.size,
    this.fontSize = 12.0,
    this.highlight = false,
    this.count = 0,
  });

  /// The URL of the image to display.
  final String url;

  /// The size of the image container; both height and width.
  final double size;

  final double fontSize;

  final bool highlight;

  final int count;

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return PodcastImage(
      key: Key('tile$url'),
      highlight: highlight,
      count: count,
      url: url,
      height: size,
      width: size,
      fontSize: fontSize,
      borderRadius: 4.0,
      fit: BoxFit.contain,
      placeholder: placeholderBuilder != null
          ? placeholderBuilder.builder()(context)
          : const Image(
              fit: BoxFit.contain,
              image: AssetImage('assets/images/anytime-placeholder-logo.png'),
            ),
      errorPlaceholder: placeholderBuilder != null
          ? placeholderBuilder.errorBuilder()(context)
          : const Image(
              fit: BoxFit.contain,
              image: AssetImage('assets/images/anytime-placeholder-logo.png'),
            ),
    );
  }
}
