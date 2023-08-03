// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/l10n/L.dart';
import 'package:flutter/material.dart';

/// Simple widget for rendering either the standard Android close or iOS Back button.
class PlatformBackButton extends StatelessWidget {
  final Color decorationColour;
  final Color iconColour;
  final VoidCallback onPressed;

  const PlatformBackButton({
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
          height: 48.0,
          width: 48.0,
          decoration: ShapeDecoration(
            color: decorationColour,
            shape: const CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(
              Platform.isIOS ? Icons.arrow_back_ios : Icons.close,
              size: Platform.isIOS ? 18.0 : 36.0,
              semanticLabel: L.of(context)?.go_back_button_label,
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
