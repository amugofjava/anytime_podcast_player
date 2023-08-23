// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockPathProvder extends PathProviderPlatform {
  Future<Directory> getApplicationDocumentsDirectory() {
    return Future.value(Directory.systemTemp);
  }

  @override
  Future<String> getApplicationDocumentsPath() {
    return Future.value(Directory.systemTemp.path);
  }
}
