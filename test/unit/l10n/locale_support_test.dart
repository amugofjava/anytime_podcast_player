// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/l10n/L.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the app's localizations setup so a grey screen (which happened when
/// the Chinese locale was not supported) is caught by a widget test.
const _delegates = <LocalizationsDelegate<Object>>[
  AnytimeLocalisationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Chinese locale (zh, Hans) is supported by Flutter material localizations', () {
    // This is the locale the app must use to avoid a grey screen. Its
    // languageCode ('zh') must be recognised by the built-in material
    // localizations, otherwise the whole UI renders blank.
    expect(GlobalMaterialLocalizations.delegate.isSupported(const Locale('zh', 'Hans')), isTrue);
  });

  test('Chinese locale (zh, Hans) is supported by the app localizations delegate', () {
    expect(const AnytimeLocalisationsDelegate().isSupported(const Locale('zh', 'Hans')), isTrue);
  });

  test('Chinese locale loads Simplified Chinese messages', () async {
    final l = await L.load(const Locale('zh', 'Hans'), const {});
    // 'Settings' in Simplified Chinese is '设置'.
    expect(l.settings_label, '设置');
  });

  testWidgets('MaterialApp with Chinese locale renders without a grey screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'Hans'),
      supportedLocales: const [Locale('zh', 'Hans'), Locale('en')],
      localizationsDelegates: _delegates,
      home: const Scaffold(body: Text('测试')),
    ));

    // Let the async localization delegates finish loading.
    await tester.pumpAndSettle();

    // No localization exception raised (the grey-screen failure mode).
    expect(tester.takeException(), isNull);
    expect(find.text('测试'), findsOneWidget);
  });
}
