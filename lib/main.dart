// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/ui/anytime_podcast_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));

  Logger.root.level = Level.FINE;

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: - ${record.time}: ${record.loggerName}: ${record.message}');
  });

  var _mobileSettingsService = await MobileSettingsService.instance();

  runApp(AnytimePodcastApp(_mobileSettingsService));
}
