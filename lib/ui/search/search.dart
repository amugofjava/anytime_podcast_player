// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/search/search_bloc.dart';
import 'package:anytime/bloc/search/search_state_event.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/search/search_results.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  final String searchTerm;

  Search({this.searchTerm});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController _searchController;
  FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<SearchBloc>(context, listen: false);

    bloc.search(SearchClearEvent());

    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
    if (widget.searchTerm != null) {
      bloc.search(SearchTermEvent(widget.searchTerm));
      _searchController.text = widget.searchTerm;
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SearchBloc>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            brightness: Theme.of(context).brightness,
            leading: IconButton(
              tooltip: L.of(context).search_back_button_label,
              icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: widget.searchTerm != null ? false : true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: L.of(context).search_for_podcasts_hint,
                  // hintStyle: ,
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.grey, fontSize: 18.0),
                onSubmitted: ((value) {
                  bloc.search(SearchTermEvent(value));
                })),
            floating: false,
            pinned: true,
            snap: false,
            actions: <Widget>[
              IconButton(
                tooltip: L.of(context).clear_search_button_label,
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                },
              ),
            ],
          ),
          Container(
            child: SearchResults(data: bloc.results),
          ),
        ],
      ),
    );
  }
}
