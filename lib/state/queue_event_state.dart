// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/episode.dart';
import 'package:flutter/foundation.dart';

abstract class QueueEvent {
  final Episode episode;
  int position;

  QueueEvent({
    @required this.episode,
    this.position,
  });
}

class QueueAddEvent extends QueueEvent {
  QueueAddEvent({@required Episode episode, int position}) : super(episode: episode, position: position);
}

class QueueRemoveEvent extends QueueEvent {
  QueueRemoveEvent({@required Episode episode}) : super(episode: episode);
}

class QueueMoveEvent extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  QueueMoveEvent({
    @required Episode episode,
    @required this.oldIndex,
    @required this.newIndex,
  }) : super(episode: episode);
}

class QueueClearEvent extends QueueEvent {}

abstract class QueueState {
  final Episode playing;
  final List<Episode> queue;

  QueueState({
    @required this.playing,
    @required this.queue,
  });
}

class QueueListState extends QueueState {
  QueueListState({
    @required Episode playing,
    @required List<Episode> queue,
  }) : super(playing: playing, queue: queue);
}

class QueueEmptyState extends QueueState {
  QueueEmptyState()
      : super(playing: Episode(guid: '', pguid: '', podcast: '', title: '', description: ''), queue: <Episode>[]);
}
