// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:get_version/get_version.dart';

const podcastIndexKey = String.fromEnvironment('PINDEX_KEY', defaultValue: '');
const podcastIndexSecret = String.fromEnvironment('PINDEX_SECRET', defaultValue: '');
const userAgentAppString = String.fromEnvironment('USER_AGENT', defaultValue: '');

class Environment {
  static const _applicationName = 'Anytime';
  static const _applicationUrl = 'https://github.com/amugofjava/anytime_podcast_player';

  static var _agentString = userAgentAppString;
  static var projectVersion = '';
  static var platformVersion = '';

  static Future<void> loadEnvironment() async {
    projectVersion = await GetVersion.projectVersion;
    platformVersion = await GetVersion.platformVersion;
  }

  static String userAgent() {
    if (_agentString.isEmpty) {
      _agentString = '$_applicationName/$projectVersion (phone;$platformVersion) $_applicationUrl';
    }

    return _agentString;
  }
}
