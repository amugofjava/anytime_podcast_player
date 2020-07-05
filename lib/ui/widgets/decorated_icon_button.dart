// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';

/// An [IconButton] cannot have a background or border. This class
/// wraps an IconButton in a shape so that it can have a background.
class DecoratedIconButton extends StatelessWidget {
  final Color decorationColour;
  final Color iconColour;
  final IconData icon;
  final VoidCallback onPressed;

  DecoratedIconButton({
    Key key,
    @required this.iconColour,
    @required this.decorationColour,
    @required this.icon,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Ink(
          decoration: ShapeDecoration(
            color: decorationColour,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: iconColour,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
