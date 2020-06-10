// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DownloadButton extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final int percent;

  const DownloadButton({
    Key key,
    @required this.label,
    @required this.title,
    @required this.icon,
    @required this.percent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var progress = percent.toDouble() / 100;

    return Semantics(
      label: '$label $title',
      child: CircularPercentIndicator(
        radius: 38.0,
        lineWidth: 2.0,
        backgroundColor: Colors.orange,
        progressColor: Colors.blue,
        animation: true,
        animateFromLastPercent: true,
        percent: progress,
        center: percent > 0
            ? Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12.0,
                ),
              )
            : Icon(
                icon,
                size: 28.0,
                color: Colors.orange,
              ),
      ),
    );
  }
}
