// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/core/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Environment', () {
    test('userAgent returns a non-empty string', () {
      expect(Environment.userAgent(), isNotEmpty);
    });

    test('userAgent contains application name and version', () {
      final userAgent = Environment.userAgent();
      expect(userAgent, contains('Anytime/${Environment.projectVersion}'));
    });
  });
}
