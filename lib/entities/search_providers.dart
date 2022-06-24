// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Anytime can support multiple search providers. This class represents a
/// provider.
class SearchProvider {
  final String key;
  final String name;

  SearchProvider({
    @required this.key,
    @required this.name,
  });
}
