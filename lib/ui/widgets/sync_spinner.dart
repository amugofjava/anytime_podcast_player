// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncSpinner extends StatefulWidget {
  const SyncSpinner({Key? key}) : super(key: key);

  @override
  State<SyncSpinner> createState() => _SyncSpinnerState();
}

class _SyncSpinnerState extends State<SyncSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Widget? _child;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _child = const Icon(Icons.refresh);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

    return StreamBuilder<BlocState<void>>(
        initialData: BlocEmptyState<void>(),
        stream: podcastBloc.backgroundLoading,
        builder: (context, snapshot) {
          final state = snapshot.data;

          return state is BlocLoadingState<void>
              ? RotationTransition(
                  turns: _controller,
                  child: _child,
                )
              : const SizedBox(
                  width: 0.0,
                  height: 0.0,
                );
        });
  }
}
