// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';
import 'dart:io';

class PlatformBackButton extends StatelessWidget {
  final Color decorationColour;
  final Color iconColour;
  final VoidCallback onPressed;

  PlatformBackButton({
    Key? key,
    required this.iconColour,
    required this.decorationColour,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Ink(
          width: Platform.isIOS ? 28.0 : 42.0,
          height: Platform.isIOS ? 28.0 : 42.0,
          decoration: ShapeDecoration(
            color: decorationColour,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(
              Platform.isIOS ? Icons.arrow_back_ios : Icons.close,
              size: Platform.isIOS ? 18.0 : 32.0,
            ),
            padding: Platform.isIOS ? const EdgeInsets.only(left: 7.0) : const EdgeInsets.all(0.0),
            color: iconColour,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
