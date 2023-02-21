// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_list.dart';
import 'package:anytime/ui/widgets/podcast_list_with_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:podcast_search/podcast_search.dart' as search;
import 'package:provider/provider.dart';

class DiscoveryResults extends StatelessWidget {
  final Stream<DiscoveryState> data;
  final bool inlineSearch;

  DiscoveryResults({@required this.data, this.inlineSearch});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DiscoveryState>(
      stream: data,
      builder: (BuildContext context, AsyncSnapshot<DiscoveryState> snapshot) {
        final state = snapshot.data;

        if (state is DiscoveryPopulatedState) {
          if (inlineSearch) return PodcastListWithSearchBar(results: state.results as search.SearchResult);
          return PodcastList(results: state.results as search.SearchResult);
        } else {
          if (state is DiscoveryLoadingState) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  PlatformProgressIndicator(),
                ],
              ),
            );
          } else if (state is BlocErrorState) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.search,
                      size: 75,
                      color: Theme.of(context).primaryColor,
                    ),
                    Text(
                      L.of(context).no_search_results_message,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: Container(),
          );
        }
      },
    );
  }
}

class DiscoveryHeader extends StatefulWidget {
  final search.SearchResult results;

  DiscoveryHeader({
    Key key,
    this.results,
  }) : super(key: key);

  @override
  State<DiscoveryHeader> createState() => _DiscoveryHeaderState();
}

class _DiscoveryHeaderState extends State<DiscoveryHeader> {
  @override
  Widget build(BuildContext context) {
    final discoveryBloc = Provider.of<DiscoveryBloc>(context);

    return SliverToBoxAdapter(
      child: ShrinkWrappingViewport(
        offset: ViewportOffset.zero(),
        slivers: [
          SliverToBoxAdapter(
              child: StreamBuilder<List<String>>(
                  stream: discoveryBloc.genres,
                  initialData: <String>[],
                  builder: (context, snapshot) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                      child: DropdownButton<String>(
                        value: 'All',
                        // icon: const Icon(Icons.arrow_downward),
                        // iconSize: 16,
                        // elevation: 16,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(
                          height: 2,
                          color: Colors.white,
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            // dropdownValue = newValue!;
                          });
                        },
                        items: snapshot.data.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    );
                  })),
          PodcastList(results: widget.results),
        ],
      ),
    );
  }
}
