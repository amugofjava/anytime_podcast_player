// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Displays a download button for an episode.
///
/// Can be passed a percentage representing the download progress which
/// the button will then animate to show progress.
class DownloadButton extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final int percent;
  final VoidCallback onPressed;

  const DownloadButton({
    super.key,
    required this.label,
    required this.title,
    required this.icon,
    required this.percent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var progress = percent.toDouble() / 100;

    return Semantics(
      label: '$label $title',
      child: InkWell(
        onTap: onPressed,
        child: CircularPercentIndicator(
          radius: 19.0,
          lineWidth: 2.0,
          backgroundColor: colorScheme.surfaceContainerHigh,
          progressColor: colorScheme.primary,
          animation: true,
          animateFromLastPercent: true,
          percent: progress,
          center: percent > 0
              ? Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 12.0,
                  ),
                )
              : Icon(
                  icon,
                  size: 22.0,
                  color: colorScheme.primary,
                ),
        ),
      ),
    );
  }
}
