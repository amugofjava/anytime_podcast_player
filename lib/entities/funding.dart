// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A class that represents and individual funding option that may be
/// part of a [Podcast].
///
/// Part of the [podcast namespace](https://github.com/Podcastindex-org/podcast-namespace)
class Funding {
  final String url;
  final String value;

  const Funding({
    this.url,
    this.value,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'value': value,
    };
  }

  static Funding fromMap(Map<String, dynamic> chapter) {
    return Funding(
      url: chapter['url'] as String,
      value: chapter['value'] as String,
    );
  }
}
