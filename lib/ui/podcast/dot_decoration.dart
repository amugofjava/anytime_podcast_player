// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

class DotDecoration extends Decoration {
  final Color colour;

  const DotDecoration({@required this.colour});

  @override
  BoxPainter createBoxPainter([void Function() onChanged]) {
    return _DotDecorationPainter(decoration: this);
  }
}

class _DotDecorationPainter extends BoxPainter {
  final DotDecoration decoration;

  _DotDecorationPainter({@required this.decoration});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final center = configuration.size.center(offset);
    final height = configuration.size.height;

    final newOffset = Offset(center.dx, height - 8);

    final paint = Paint();
    paint.color = decoration.colour;
    paint.style = PaintingStyle.fill;

    canvas.drawCircle(newOffset, 4, paint);
  }
}
