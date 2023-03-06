// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:anytime/entities/episode.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// On iOS, the directory that the app has available to it for storing episodes may
/// change between updates, whereas on Android we are able to save the full path. To
/// ensure we can handle the directory name change on iOS without breaking existing
/// Android installations we have created the following three functions to help with
/// resolving the various paths correctly depending upon platform.
Future<String> resolvePath(Episode episode) async {
  if (Platform.isIOS) {
    return Future.value(join(await getStorageDirectory(), episode.filepath, episode.filename));
  }

  return Future.value(join(episode.filepath, episode.filename));
}

Future<String> resolveDirectory({@required Episode episode, bool full = false}) async {
  if (full || Platform.isAndroid) {
    return Future.value(join(await getStorageDirectory(), safePath(episode.podcast)));
  }

  return Future.value(safePath(episode.podcast));
}

Future<void> createDownloadDirectory(Episode episode) async {
  var path = join(await getStorageDirectory(), safePath(episode.podcast));

  Directory(path).createSync(recursive: true);
}

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
  return s?.replaceAll(RegExp(r'[^\w\s]+'), '')?.trim();
}

String safeFile(String s) {
  return s?.replaceAll(RegExp(r'[^\w\s\.]+'), '')?.trim();
}

extension ExtString on String {
  String get forceHttps {
    final incomingUrl = Uri.parse(this);
    if (!incomingUrl.isScheme('http')) return this;

    return Uri.https(
      incomingUrl.authority,
      incomingUrl.path,
      incomingUrl.queryParameters,
    ).toString();
  }
}
