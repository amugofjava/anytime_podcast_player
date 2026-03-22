// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/widgets/search_slide_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'search.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: L.of(context)!.search_for_podcasts_hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              tooltip: _searchFocusNode.hasFocus ? L.of(context)!.clear_search_button_label : null,
              icon: Icon(_searchController.text.isEmpty && !_searchFocusNode.hasFocus ? Icons.search : Icons.clear),
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).requestFocus(FocusNode());
                SystemChannels.textInput.invokeMethod<String>('TextInput.show');
              }),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onSubmitted: (value) async {
          await Navigator.push(
              context,
              SlideRightRoute(
                widget: Search(searchTerm: value),
                settings: const RouteSettings(name: 'search'),
              ));
          _searchController.clear();
        },
      ),
    );
  }
}
