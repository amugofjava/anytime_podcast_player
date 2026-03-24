// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/state/ad_skip_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdSkipListener extends StatefulWidget {
  final Widget child;

  const AdSkipListener({
    super.key,
    required this.child,
  });

  @override
  State<AdSkipListener> createState() => _AdSkipListenerState();
}

class _AdSkipListenerState extends State<AdSkipListener> {
  StreamSubscription<AdSkipState>? _subscription;

  @override
  void initState() {
    super.initState();
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    _subscription = audioBloc.adSkipEvents?.listen((event) {
      if (!mounted) {
        return;
      }

      if (event is AdSkipClearedState) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Ad detected'),
            action: SnackBarAction(
              label: 'Skip',
              onPressed: () {
                audioBloc.skipActiveAd();
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
