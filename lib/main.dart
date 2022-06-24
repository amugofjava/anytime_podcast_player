// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/ui/anytime_podcast_app.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

void main() async {
  List<int> certificateAuthorityBytes = [];
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));

  Logger.root.level = Level.FINE;

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: - ${record.time}: ${record.loggerName}: ${record.message}');
  });

  var mobileSettingsService = await MobileSettingsService.instance();
  certificateAuthorityBytes = await setupCertificateAuthority();

  runApp(AnytimePodcastApp(
    mobileSettingsService,
    certificateAuthorityBytes: certificateAuthorityBytes,
  ));
}

/// The Let's Encrypt CA expired on at the end of September 2021. This causes problems when trying to
/// fetch feeds secured with the CA. Older Android devices, 7.0 and before, cannot be updated with the
/// latest CA so this routine manually sets up the updated LE CA when running on Android v7.0 or earlier.
Future<List<int>> setupCertificateAuthority() async {
  List<int> ca = [];

  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    var major = androidInfo.version.release.split('.');

    if ((int.tryParse(major[0]) ?? 100.0) < 8.0) {
      ByteData data = await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
      ca = data.buffer.asUint8List();
    }
  }

  return ca;
}
