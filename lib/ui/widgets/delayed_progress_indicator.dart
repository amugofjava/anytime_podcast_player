// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:flutter/material.dart';

/// This class returns a platform-specific spinning indicator after a
/// time specified in milliseconds. Defaults to 1 second. This can be
/// used as a place holder for cached images. By delaying for several
/// milliseconds it can reduce the occurrences of placeholders flashing
/// on screen as the cached image is loaded. Images that take longer to
/// fetch or process from the cache will result in a progress indicator
/// being displayed.
class DelayedCircularProgressIndicator extends StatelessWidget {
  final int delayInMilliseconds;

  DelayedCircularProgressIndicator({
    this.delayInMilliseconds = 1000,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
        future: Future.delayed(Duration(milliseconds: delayInMilliseconds)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: PlatformProgressIndicator(),
            );
          } else {
            return Container();
          }
        });
  }
}
