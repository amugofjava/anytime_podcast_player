// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:optimized_cached_image/widgets.dart';

import 'placeholder_builder.dart';

class TileImage extends StatelessWidget {
  const TileImage({
    Key key,
    @required this.url,
    @required this.size,
  }) : super(key: key);

  /// The URL of the image to display.
  final String url;

  /// The size of the image container; both height and width.
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = PlaceholderBuilder.of(context);
    return SizedBox(
        height: size,
        width: size,
        child: OptimizedCacheImage(
          useScaleCacheManager: true,
          imageUrl: url,
          filterQuality: FilterQuality.low,
          width: 120,
          height: 120,
          placeholder: (context, url) {
            return placeholderBuilder != null
                ? placeholderBuilder?.builder()(context)
                : Image(image: AssetImage('assets/images/anytime-placeholder-logo.png'));
          },
          errorWidget: (_, __, dynamic ___) {
            return placeholderBuilder != null
                ? placeholderBuilder?.errorBuilder()(context)
                : Image(image: AssetImage('assets/images/anytime-placeholder-logo.png'));
          },
        ));
  }
}
