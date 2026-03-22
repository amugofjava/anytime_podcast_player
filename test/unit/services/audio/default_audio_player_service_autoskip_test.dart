// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultAudioPlayerService auto-skip', () {
    test(
      'skips to the end of the active ad range when playback enters a segment boundary',
      () {
        // TODO: Re-enable with concrete assertions once Phase 7 auto-skip playback logic is implemented.
      },
      skip: 'Phase 7 auto-skip playback logic is not implemented in the current branch.',
    );

    test(
      'prevents repeated seek loops when position updates remain inside the same segment',
      () {
        // TODO: Re-enable with concrete assertions once Phase 7 skip cooldown/marker logic is implemented.
      },
      skip: 'Phase 7 auto-skip playback logic is not implemented in the current branch.',
    );
  });
}
