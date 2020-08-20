// Copyright 2020 Ben Hills. All rights reserved.
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

  static const _translucent = SystemUiOverlayStyle(
    statusBarColor: Color(0x22000000),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const _transparent = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFFFFFF),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static var _last = _translucent;

  static void translucentLight() {
    log.fine('translucentLight()');

    _last = _translucent;

    restoreLast();
  }

  static void transparentLight() {
    log.fine('transparentLight()');

    _last = _transparent;

    restoreLast();
  }

  static void restoreLast() {
    if (_last == _translucent) {
      log.fine('restoring translucentLight()');
    } else {
      log.fine('restoring transparentLight()');
    }

    SystemChrome.setSystemUIOverlayStyle(_last);
  }
}
