import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The class returns a circular progress indicator that is appropriate
/// for the platform it is running on. This boils down to a [CupertinoActivityIndicator]
/// when running on iOS or MacOS and a [CircularProgressIndicator] for
/// everything else.
class PlatformProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    assert(theme.platform != null);

    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return CircularProgressIndicator();
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoActivityIndicator();
    }

    return CircularProgressIndicator();
  }
}
