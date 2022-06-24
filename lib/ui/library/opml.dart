// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/library/opml_import.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OPMLSelect extends StatefulWidget {
  const OPMLSelect({Key key}) : super(key: key);

  @override
  State<OPMLSelect> createState() => _OPMLSelectState();
}

class _OPMLSelectState extends State<OPMLSelect> {
  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAndroid(context);
      case TargetPlatform.iOS:
        return _buildIos(context);
      default:
        assert(false, 'Unexpected platform $defaultTargetPlatform');
        return null;
    }
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          L.of(context).opml_import_export_label,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                var result = await FilePicker.platform.pickFiles();

                if (result.count > 0) {
                  var file = result.files.first;

                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      settings: RouteSettings(name: 'opmlimport'),
                      builder: (context) => OPMLImport(file: file.path),
                      fullscreenDialog: true,
                    ),
                  );

                  Navigator.pop(context);
                }
              },
              child: Text(L.of(context).opml_import_button_label),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text(L.of(context).opml_export_button_label),
            ),
          ],
        ),
      ],
    );
  }
}
