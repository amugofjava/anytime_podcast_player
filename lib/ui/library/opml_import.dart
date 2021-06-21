// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/opml_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OPMLImport extends StatefulWidget {
  final String file;

  const OPMLImport({
    Key key,
    @required this.file,
  }) : super(key: key);

  @override
  _OPMLImportState createState() => _OPMLImportState();
}

class _OPMLImportState extends State<OPMLImport> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<OPMLBloc>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
          brightness: Theme.of(context).brightness,
          elevation: 0.0,
          title: Text(
            L.of(context).label_opml_importing,
          ),
        ),
        body: StreamBuilder<OPMLImportEvent>(
            initialData: OPMLImportEvent(state: OPMLImportState.none),
            stream: bloc.importEvent,
            builder: (context, snapshot) {
              var v = 0.0;

              if (snapshot.data.state == OPMLImportState.load) {
                v = snapshot.data.current / snapshot.data.total;
              }

              return Container(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      L.of(context).label_opml_importing,
                      style: TextStyle(fontSize: 24.0),
                    ),
                    Padding(
                      paddinlig: const EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(
                        minHeight: 16.0,
                        value: v,
                      ),
                    ),
                    Text(snapshot.data.podcast ?? ''),
                  ],
                ),
              ));
            }));
  }

  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<OPMLBloc>(context, listen: false);

    bloc.importFile(widget.file);
  }
}
