// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:anytime/entities/persistable.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PersistentState {
  static Future<void> persistState(Persistable persistable) async {
    final d = await getApplicationSupportDirectory();

    final file = File(join(d.path, 'state.json'));
    final sink = file.openWrite();
    final json = jsonEncode(persistable.toMap());

    sink.write(json);
    await sink.flush();
    await sink.close();
  }

  static Future<Persistable> fetchState() async {
    final d = await getApplicationSupportDirectory();

    final file = File(join(d.path, 'state.json'));
    var p = Persistable.empty();

    if (file.existsSync()) {
      final result = file.readAsStringSync();

      if (result.isNotEmpty) {
        final data = jsonDecode(result) as Map<String, dynamic>;

        p = Persistable.fromMap(data);
      }
    }

    return Future.value(p);
  }

  static Future<void> clearState() async {
    final file = await _getFile();

    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  static Future<void> writeInt(String name, int value) async {
    return _writeValue(name, value.toString());
  }

  static Future<int> readInt(String name) async {
    final result = await _readValue(name);

    return result.isEmpty ? 0 : int.parse(result);
  }

  static Future<void> writeString(String name, String value) async {
    return _writeValue(name, value);
  }

  static Future<String> readString(String name) async {
    return _readValue(name);
  }

  static Future<String> _readValue(String name) async {
    final d = await getApplicationSupportDirectory();

    final file = File(join(d.path, name));
    final result = file.readAsStringSync();

    return result;
  }

  static Future<void> _writeValue(String name, String value) async {
    final d = await getApplicationSupportDirectory();

    final file = File(join(d.path, name));
    final sink = file.openWrite();

    sink.write(value);
    await sink.flush();
    await sink.close();
  }

  static Future<File> _getFile() async {
    final d = await getApplicationSupportDirectory();

    return File(join(d.path, 'state.json'));
  }
}
