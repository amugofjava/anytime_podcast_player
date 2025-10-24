// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/messages_all_locales.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/settings/settings_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Globals
String? _currentLocale;

/// Returns the storage directory for the current platform.
///
/// On iOS, the directory that the app has available to it for storing episodes may
/// change between updates, whereas on Android we are able to save the full path. To
/// ensure we can handle the directory name change on iOS without breaking existing
/// Android installations we have created the following three functions to help with
/// resolving the various paths correctly depending upon platform.
Future<String> resolvePath(Episode episode) async {
  if (Platform.isIOS) {
    return Future.value(join(await getStorageDirectory(), episode.filepath, episode.filename));
  }

  return Future.value(join(episode.filepath!, episode.filename));
}

Future<String> resolveDirectory({required Episode episode, bool full = false}) async {
  if (full || Platform.isAndroid) {
    return Future.value(join(await getStorageDirectory(), safePath(episode.podcast!)));
  }

  return Future.value(safePath(episode.podcast!));
}

Future<void> createDownloadDirectory(Episode episode) async {
  var path = join(await getStorageDirectory(), safePath(episode.podcast!));

  Directory(path).createSync(recursive: true);
}

Future<bool> hasStoragePermission() async {
  SettingsService? settings = await MobileSettingsService.instance();

  if (Platform.isIOS || !settings!.storeDownloadsSDCard) {
    return Future.value(true);
  } else {
    final permissionStatus = await Permission.storage.request();

    return Future.value(permissionStatus.isGranted);
  }
}

Future<String> getStorageDirectory() async {
  SettingsService? settings = await MobileSettingsService.instance();
  Directory directory;

  if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else if (settings!.storeDownloadsSDCard) {
    directory = await _getSDCard();
  } else {
    directory = await getApplicationSupportDirectory();
  }

  return join(directory.path, 'AnyTime');
}

Future<bool> hasExternalStorage() async {
  try {
    await _getSDCard();

    return Future.value(true);
  } catch (e) {
    return Future.value(false);
  }
}

Future<Directory> _getSDCard() async {
  final appDocumentDir = (await getExternalStorageDirectories(type: StorageDirectory.podcasts))!;

  Directory? path;

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
String? safePath(String? s) {
  return s?.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
}

String? safeFile(String? s) {
  return s?.replaceAll(RegExp(r'[^\w\s\.]+'), '').trim();
}

Future<String> resolveUrl(String url, {bool forceHttps = false}) async {
  final client = HttpClient();
  var uri = Uri.parse(url);
  var request = await client.getUrl(uri);

  request.followRedirects = false;

  var response = await request.close();

  while (response.isRedirect) {
    response.drain(0);
    final location = response.headers.value(HttpHeaders.locationHeader);
    if (location != null) {
      uri = uri.resolve(location);
      request = await client.getUrl(uri);
      // Set the body or headers as desired.
      request.followRedirects = false;
      response = await request.close();
    }
  }

  if (uri.scheme == 'http') {
    uri = uri.replace(scheme: 'https');
  }

  return uri.toString();
}

Future<void> sharePodcast({required Podcast podcast}) async {
  var url = base64UrlEncode(utf8.encode(podcast.url));

  /// Manually remove padding. Required to work with episodes.fm
  url = url.replaceAll('=', '');

  final link = '${podcast.title}\n\nhttps://episodes.fm/$url';

  await SharePlus.instance.share(
    ShareParams(text: link),
  );
}

Future<void> shareEpisode({required Episode episode}) async {
  var podcastId = base64UrlEncode(utf8.encode(episode.pguid ?? ''));
  var episodeId = base64UrlEncode(utf8.encode(episode.guid));

  /// Manually remove padding. Required to work with episodes.fm
  podcastId = podcastId.replaceAll('=', '');
  episodeId = episodeId.replaceAll('=', '');

  final link = '${episode.title}\n\nhttps://episodes.fm/$podcastId/episode/$episodeId';

  await SharePlus.instance.share(
    ShareParams(text: link),
  );
}

Future<String> currentLocale({bool forceReload = false}) async {
  var currentLocale = Platform.localeName;

  if (_currentLocale == null || forceReload) {
    final List<Locale> systemLocales = PlatformDispatcher.instance.locales;

    // Attempt to get current locale
    var supportedLocale = await initializeMessages(Platform.localeName);

    // If we do not support the default, try all supported locales
    if (!supportedLocale) {
      for (var l in systemLocales) {
        supportedLocale = await initializeMessages('${l.languageCode}_${l.countryCode}');
        if (supportedLocale) {
          currentLocale = '${l.languageCode}_${l.countryCode}';
          break;
        }
      }

      if (!supportedLocale) {
        // We give up! Default to English
        currentLocale = 'en';
        supportedLocale = await initializeMessages(currentLocale);
      }
    }
  }

  return currentLocale;
}
