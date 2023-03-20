// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:podcast_search/podcast_search.dart' as podcast_search;
import 'package:rxdart/rxdart.dart';

/// A BLoC to interact with the Discovery UI page and the [PodcastService] to
/// fetch the iTunes/PodcastIndex charts. As charts will not change very frequently
/// the results are cached for [cacheMinutes].
class DiscoveryBloc extends Bloc {
  static const cacheMinutes = 30;

  final log = Logger('DiscoveryBloc');
  final PodcastService podcastService;

  /// Takes an event which triggers a loading of chart data from the selected provider.
  final _discoveryInput = BehaviorSubject<DiscoveryEvent>();

  /// A stream of genres from the selected provider.
  final _genres = PublishSubject<List<String>>();

  /// The last genre to be passed in a [DiscoveryEvent].
  final _selectedGenre = BehaviorSubject<SelectedGenre>(sync: true);

  Stream<DiscoveryState> _discoveryResults;
  podcast_search.SearchResult _resultsCache;

  String _lastGenre = '';
  int _lastIndex;

  DiscoveryBloc({@required this.podcastService}) {
    _init();
  }

  void _init() {
    _discoveryResults = _discoveryInput.switchMap<DiscoveryState>((DiscoveryEvent event) => _charts(event));
    _selectedGenre.value = SelectedGenre(index: 0, genre: '<All>');
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
        _lastIndex = podcastService.genres().indexOf(_lastGenre);
        _selectedGenre.add(SelectedGenre(index: _lastIndex, genre: _lastGenre));
        _resultsCache = await podcastService.charts(size: event.count, genre: event.genre);
      }

      yield DiscoveryPopulatedState<podcast_search.SearchResult>(
        genre: event.genre,
        index: podcastService.genres().indexOf(event.genre),
        results: _resultsCache,
      );
    }
  }

  @override
  void dispose() {
    _discoveryInput.close();
  }

  void Function(DiscoveryEvent) get discover => _discoveryInput.add;

  Stream<DiscoveryState> get results => _discoveryResults;

  Stream<List<String>> get genres => _genres.stream;

  SelectedGenre get selectedGenre => _selectedGenre.value;
}

class SelectedGenre {
  final int index;
  final String genre;

  SelectedGenre({
    @required this.index,
    @required this.genre,
  });
}
