// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Events
class DiscoveryEvent {}

class DiscoveryChartEvent extends DiscoveryEvent {
  final int count;
  String genre;

  DiscoveryChartEvent({
    @required this.count,
    this.genre = '',
  });
}

/// States
class DiscoveryState {}

class DiscoveryLoadingState extends DiscoveryState {}

class DiscoveryPopulatedState<T> extends DiscoveryState {
  final T results;

  DiscoveryPopulatedState(this.results);
}
