// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/bloc/podcast/queue_event_state.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class QueueBloc extends Bloc {
  final AudioPlayerService audioPlayerService;
  final PublishSubject<QueueEvent> _queueEvent = PublishSubject<QueueEvent>();
  final BehaviorSubject<QueueState> _queueState = BehaviorSubject<QueueState>();

  QueueBloc({@required this.audioPlayerService}) {
    _handleQueueEvents();
  }

  void _handleQueueEvents() {
    _queueEvent.listen((QueueEvent event) async {
      if (event is QueueAddEvent) {
        var e = event.episode;
        await audioPlayerService.addUpNextEpisode(e);
      } else if (event is QueueRemoveEvent) {
        var e = event.episode;
        await audioPlayerService.removeUpNextEpisode(e);
      } else if (event is QueueMoveEvent) {
        var e = event.episode;
        await audioPlayerService.moveUpNextEpisode(e, event.oldIndex, event.newIndex);
      } else if (event is QueueClearEvent) {
        await audioPlayerService.clearUpNext();
      }
    });
  }

  Function(QueueEvent) get queueEvent => _queueEvent.sink.add;

  Stream<QueueListState> get queue => audioPlayerService.queueState;

  @override
  void dispose() {
    _queueEvent.close();

    super.dispose();
  }
}
