// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Queue {
  List<String> guids = <String>[];

  Queue({
    @required this.guids,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'q': guids,
    };
  }

  static Queue fromMap(int key, Map<String, dynamic> guids) {
    var g = guids['q'] as List<dynamic>;
    var result = <String>[];

    if (g != null) {
      result = g.map((dynamic e) => e.toString()).toList();
    }

    return Queue(
      guids: result ?? <String>[],
    );
  }
}
