// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final ThemeData kLightTheme = _buildLightTheme();

ThemeData _buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    primaryColor: Colors.orange,
    accentColor: Colors.deepOrangeAccent,
    canvasColor: Colors.transparent,
    primaryIconTheme: IconThemeData(color: Colors.grey[800]),
    iconTheme: IconThemeData(color: Colors.orange),
  );
}

class Themes {
  final ThemeData themeData;

  Themes({@required this.themeData});

  factory Themes.lightTheme() {
    return Themes(themeData: kLightTheme);
  }
}
