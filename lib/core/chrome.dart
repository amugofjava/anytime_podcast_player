// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// This class sets the status bar style depending upon the current form.
/// The current style is stored and can then be restored when the
/// application regains focus.
class Chrome {
  static final log = Logger('Chrome');

  static const _translucentLight = SystemUiOverlayStyle(
    statusBarColor: Color(0x22000000),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const _transparentLight = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFFFFFF),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const _translucentDark = SystemUiOverlayStyle(
    statusBarColor: Color(0x22000000),
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xff222222),
    statusBarBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const _transparentDark = SystemUiOverlayStyle(
    statusBarColor: Color(0xff222222),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xff222222),
    statusBarBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static var _last = _translucentDark;

  static void translucentLight() {
    _last = _translucentLight;

    restoreLast();
  }

  static void transparentLight() {
    _last = _transparentLight;

    restoreLast();
  }

  static void translucentDark() {
    _last = _translucentDark;

    restoreLast();
  }

  static void transparentDark() {
    _last = _transparentDark;

    restoreLast();
  }

  static void restoreLast() {
    SystemChrome.setSystemUIOverlayStyle(_last);
  }
}
