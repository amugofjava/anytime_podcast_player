// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:podcast_search/podcast_search.dart' as pcast;
import 'package:rxdart/rxdart.dart';

/// A BLoC to interact with the Discovery UI page and the [PodcastService] to
/// fetch the iTunes charts. As charts will not change very frequently the
/// results are cached for [cacheMinutes].
class DiscoveryBloc extends Bloc {
  static const cacheMinutes = 30;
  final log = Logger('DiscoveryBloc');
  final PodcastService podcastService;

  final BehaviorSubject<DiscoveryEvent> _discoveryInput = BehaviorSubject<DiscoveryEvent>();
  final PublishSubject<List<String>> _genres = PublishSubject<List<String>>();

  Stream<DiscoveryState> _discoveryResults;
  pcast.SearchResult _resultsCache;
  String _lastGenre = '';

  DiscoveryBloc({@required this.podcastService}) {
    _init();
  }

  void _init() {
    _discoveryResults = _discoveryInput.switchMap<DiscoveryState>((DiscoveryEvent event) => _charts(event));
    _genres.onListen = loadGenres;
  }

  void loadGenres() {
    _genres.sink.add(podcastService.genres());
  }

  Stream<DiscoveryState> _charts(DiscoveryEvent event) async* {
    yield DiscoveryLoadingState();

    if (event is DiscoveryChartEvent) {
      if (_resultsCache == null ||
          event.genre != _lastGenre ||
          DateTime.now().difference(_resultsCache.processedTime).inMinutes > cacheMinutes) {
        _lastGenre = event.genre;
        _resultsCache = await podcastService.charts(size: event.count, genre: event.genre);
      }

      yield DiscoveryPopulatedState<pcast.SearchResult>(_resultsCache);
    }
  }

  @override
  void dispose() {
    _discoveryInput.close();
  }

  void Function(DiscoveryEvent) get discover => _discoveryInput.add;

  Stream<DiscoveryState> get results => _discoveryResults;
  Stream<List<String>> get genres => _genres.stream;
}
