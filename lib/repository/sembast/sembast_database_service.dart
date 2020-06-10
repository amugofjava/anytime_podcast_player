// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

/// Provides a database instance to other services and handles the opening
/// of the Sembast DB.
class DatabaseService {
  Completer<Database> _databaseCompleter;

  Future<Database> get database async {
    if (_databaseCompleter == null) {
      _databaseCompleter = Completer();
      await _openDatabase();
    }

    return _databaseCompleter.future;
  }

  Future _openDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, 'anytime.db');
    final database = await databaseFactoryIo.openDatabase(dbPath);

    _databaseCompleter.complete(database);
  }
}
