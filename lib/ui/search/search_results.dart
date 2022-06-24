// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_list.dart';
import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart' as search;

class SearchResults extends StatelessWidget {
  final Stream<BlocState> data;

  SearchResults({@required this.data});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BlocState>(
      stream: data,
      builder: (BuildContext context, AsyncSnapshot<BlocState> snapshot) {
        final state = snapshot.data;

        if (state is BlocPopulatedState) {
          return PodcastList(results: state.results as search.SearchResult);
        } else {
          if (state is BlocLoadingState) {
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
                      style: Theme.of(context).textTheme.headline6,
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
