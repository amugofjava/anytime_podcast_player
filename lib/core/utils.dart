// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> hasStoragePermission() async {
  final permissionStatus = await Permission.storage.request();

  return Future.value(permissionStatus.isGranted);
}

Future<String> getStorageDirectory() async {
  if (await hasStoragePermission()) {
    final appDocumentDir = await getExternalStorageDirectories(type: StorageDirectory.podcasts);

    String path;

    // If the directory contains emulated this may well be mapped to
    // internal storage. We really want external storage. This is VERY
    // simplistic but will be OK for the first alpha. Later on we will
    // prompt the user to select the storage directory.
    if (appDocumentDir.length == 1) {
      path = appDocumentDir[0].path;
    } else {
      // See if we can find the last card without emulated
      for (var d in appDocumentDir) {
        if (!d.path.contains('emulated')) {
          path = d.absolute.path;
        }

        // If we didn't find one, just set it to the last card we found;
        path = path ?? appDocumentDir[appDocumentDir.length - 1].path;
      }
    }

    return join(path, 'AnyTime');
  }

  return '';
}

/// Strips characters that are invalid for file and directory names.
String safePath(String s) {
  return s == null ? null : s.replaceAll(RegExp(r'[^\w\s\.]+'), '');
}
