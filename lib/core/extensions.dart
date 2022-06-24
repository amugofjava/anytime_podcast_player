// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension IterableExtensions<E> on Iterable<E> {
  Iterable<List<E>> chunk(int size) sync* {
    if (length <= 0) {
      yield [];
      return;
    }

    var skip = 0;

    while (skip < length) {
      final chunk = this.skip(skip).take(size);

      yield chunk.toList(growable: false);

      skip += size;

      if (chunk.length < size) {
        return;
      }
    }
  }
}
