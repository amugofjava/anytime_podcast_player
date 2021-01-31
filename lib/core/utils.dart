// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> hasStoragePermission() async {
  SettingsService settings = await MobileSettingsService.instance();

  if (Platform.isIOS || !settings.storeDownloadsSDCard) {
    return Future.value(true);
  } else {
    final permissionStatus = await Permission.storage.request();

    return Future.value(permissionStatus.isGranted);
  }
}

Future<String> getStorageDirectory() async {
  SettingsService settings = await MobileSettingsService.instance();
  Directory directory;

  if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else if (settings.storeDownloadsSDCard) {
    directory = await _getSDCard();
  } else {
    directory = await getApplicationSupportDirectory();
  }

  return join(directory.path, 'AnyTime');
}

Future<bool> hasExternalStorage() async {
  try {
    var result = await _getSDCard();

    return result != null;
  } catch (e) {
    return Future.value(false);
  }
}

Future<Directory> _getSDCard() async {
  final appDocumentDir = await getExternalStorageDirectories(type: StorageDirectory.podcasts);

  Directory path;

  // If the directory contains the word 'emulated' we are
  // probably looking at a mapped user partition rather than
  // an actual SD card - so skip those and find the first
  // non-emulated directory.
  if (appDocumentDir.isNotEmpty) {
    // See if we can find the last card without emulated
    for (var d in appDocumentDir) {
      if (!d.path.contains('emulated')) {
        path = d.absolute;
      }
    }
  }

  if (path == null) {
    throw ('No SD card found');
  }

  return path;
}

/// Strips characters that are invalid for file and directory names.
String safePath(String s) {
  return s == null ? null : s.replaceAll(RegExp(r'[^\w\s\.]+'), '');
}
