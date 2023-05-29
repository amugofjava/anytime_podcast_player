

import 'dart:io';

import 'package:flutter/widgets.dart';

/// This is a simple wrapper for the [Text] widget that is intended to
/// be used with action dialogs. It should be supplied with a text value
/// in sentence case. If running on Android this will be shifted to all
/// upper case to meet the Material Design guidelines; otherwise it will
/// be displayed as is to fit in the with iOS developer guidelines.
class ActionText extends StatelessWidget {
  /// The text to display which will be shifted to all upper-case on Android.
  final String text;

  const ActionText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid ? Text(text.toUpperCase()) : Text(text);
  }
}
