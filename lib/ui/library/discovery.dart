// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/ui/library/discovery_results.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// This class is the root class for rendering the Discover tab. This UI can optionally show
/// a list of genres provided by iTunes/PodcastIndex.
class Discovery extends StatefulWidget {
  final bool categories;
  final bool inlineSearch;

  Discovery({
    this.categories = false,
    this.inlineSearch = false,
  });

  @override
  State<StatefulWidget> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<DiscoveryBloc>(context, listen: false);

    bloc.discover(DiscoveryChartEvent(
      count: 10,
      genre: bloc.selectedGenre.genre,
      countryCode: WidgetsBinding.instance.window.locale.countryCode.toLowerCase(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<DiscoveryBloc>(context);

    return widget.categories
        ? MultiSliver(
            children: [
              SliverPersistentHeader(
                delegate: MyHeaderDelegate(bloc),
                pinned: true,
                floating: false,
              ),
              DiscoveryResults(data: bloc.results, inlineSearch: widget.inlineSearch),
            ],
          )
        : DiscoveryResults(data: bloc.results, inlineSearch: widget.inlineSearch);
  }
}

/// This delegate is responsible for rendering the horizontal scrolling list of categories
/// that can optionally be displayed at the top of the Discovery results page.
class MyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DiscoveryBloc discoveryBloc;

  MyHeaderDelegate(this.discoveryBloc);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CategorySelectorWidget(discoveryBloc: discoveryBloc);
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class CategorySelectorWidget extends StatefulWidget {
  final ItemScrollController itemScrollController = ItemScrollController();

  CategorySelectorWidget({
    Key key,
    @required this.discoveryBloc,
  }) : super(key: key);

  final DiscoveryBloc discoveryBloc;

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  @override
  Widget build(BuildContext context) {
    String selectedCategory = widget.discoveryBloc.selectedGenre.genre;

    return Container(
      width: double.infinity,
      color: Theme.of(context).canvasColor,
      child: StreamBuilder<List<String>>(
          stream: widget.discoveryBloc.genres,
          initialData: [],
          builder: (context, snapshot) {
            var i = widget.discoveryBloc.selectedGenre.index ?? 0;

            return snapshot.hasData && snapshot.data.isNotEmpty
                ? ScrollablePositionedList.builder(
                    initialScrollIndex: (i > 0) ? i : 0,
                    itemScrollController: widget.itemScrollController,
                    itemCount: snapshot.data.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final item = snapshot.data[i];

                      return Card(
                        color: item == selectedCategory || (selectedCategory.isEmpty && i == 0)
                            ? Theme.of(context).cardTheme.shadowColor
                            : Theme.of(context).cardTheme.color,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xffffffff),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedCategory = item;
                            });

                            widget.discoveryBloc.discover(DiscoveryChartEvent(
                              count: 10,
                              genre: item,
                              countryCode: WidgetsBinding.instance.window.locale.countryCode.toLowerCase(),
                            ));
                          },
                          child: Text(item),
                        ),
                      );
                    })
                : Container();
          }),
    );
  }
}
