// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';

class PlayPauseButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;

  const PlayPauseButton({
    Key key,
    @required this.icon,
    @required this.label,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $title',
      child: CircularPercentIndicator(
        radius: 38.0,
        lineWidth: 2.0,
        backgroundColor: Theme.of(context).buttonColor,
        percent: 0.0,
        center: Icon(
          icon,
          size: 28.0,
          color: Theme.of(context).buttonColor,
        ),
      ),
    );
  }
}

class PlayPauseBusyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;

  const PlayPauseBusyButton({
    Key key,
    @required this.icon,
    @required this.label,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: '$label $title',
        child: Container(
          padding: EdgeInsets.all(0.0),
          height: 40.0,
          width: 38.0,
          child: Stack(
            children: <Widget>[
              CircularPercentIndicator(
                radius: 38.0,
                lineWidth: 2.0,
                backgroundColor: Colors.white,
                percent: 0.0,
                center: Icon(
                  icon,
                  size: 28.0,
                  color: Theme.of(context).buttonColor,
                ),
              ),
              const SpinKitRing(
                lineWidth: 2.0,
                color: Colors.blue,
                size: 38.0,
              ),
            ],
          ),
        ));
  }
}
