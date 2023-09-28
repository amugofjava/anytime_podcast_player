// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/ui/anytime_podcast_app.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

// ignore_for_file: avoid_print
void main() async {
  List<int> certificateAuthorityBytes = [];
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

  Logger.root.level = Level.FINE;

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: - ${record.time}: ${record.loggerName}: ${record.message}');
  });

  var mobileSettingsService = (await MobileSettingsService.instance())!;
  certificateAuthorityBytes = await setupCertificateAuthority();

  runApp(AnytimePodcastApp(
    mobileSettingsService: mobileSettingsService,
    certificateAuthorityBytes: certificateAuthorityBytes,
  ));
}

/// The Let's Encrypt certificate authority expired at the end of September 2021. Android devices
/// running v7.1.1 or earlier will no longer trust their root certificate which will cause issues
/// when trying to fetch feeds and images from sites secured with LE. This routine is called to
/// add the new CA to the trusted list at app start.
Future<List<int>> setupCertificateAuthority() async {
  List<int> ca = [];

  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    var major = androidInfo.version.release.split('.');

    if ((int.tryParse(major[0]) ?? 100.0) < 8.0) {
      ByteData data = await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
      ca = data.buffer.asUint8List();
      SecurityContext.defaultContext.setTrustedCertificatesBytes(ca);
    }
  }

  return ca;
}
