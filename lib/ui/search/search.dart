// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/search/search_bloc.dart';
import 'package:anytime/bloc/search/search_state_event.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/search/search_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// This widget renders the search bar and allows the user to search for podcasts.
class Search extends StatefulWidget {
  final String? searchTerm;

  const Search({
    super.key,
    this.searchTerm,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  static const _seedSearches = <String>[
    'Darknet Diaries',
    'Lex Fridman',
    'The Daily',
  ];

  static const _categories = <_SearchCategory>[
    _SearchCategory(
      label: 'Comedy',
      icon: Icons.sentiment_very_satisfied_outlined,
      start: Color(0xffe0e3df),
      end: Color(0xff8f968f),
    ),
    _SearchCategory(
      label: 'Technology',
      icon: Icons.memory_rounded,
      start: Color(0xff3c6558),
      end: Color(0xff577e72),
    ),
    _SearchCategory(
      label: 'True Crime',
      icon: Icons.gavel_rounded,
      start: Color(0xff101614),
      end: Color(0xff24302a),
    ),
    _SearchCategory(
      label: 'History',
      icon: Icons.account_balance_rounded,
      start: Color(0xffd6d0bf),
      end: Color(0xffa8a08c),
    ),
  ];

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final List<String> _recentSearches;
  String _activeQuery = '';

  bool get _showLanding => _activeQuery.trim().isEmpty;

  @override
  void initState() {
    super.initState();

    final bloc = Provider.of<SearchBloc>(context, listen: false);
    bloc.search(SearchClearEvent());

    _recentSearches = List<String>.from(_seedSearches);
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController()
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    final initialTerm = widget.searchTerm?.trim();

    if (initialTerm != null && initialTerm.isNotEmpty) {
      _searchController.text = initialTerm;
      _submitSearch(initialTerm, addToRecent: true, requestFocus: false);
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
    final bloc = Provider.of<SearchBloc>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        tooltip: L.of(context)!.search_back_button_label,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    else
                      Text(
                        'Anytime',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerLow,
                      ),
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      width: 34.0,
                      height: 34.0,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: widget.searchTerm == null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Artists, podcasts, or episodes',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: L.of(context)!.clear_search_button_label,
                              icon: Icon(
                                Icons.close,
                                semanticLabel: L.of(context)!.clear_search_button_label,
                              ),
                              onPressed: () => _clearSearch(bloc),
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999.0),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                    onSubmitted: (value) {
                      SemanticsService.sendAnnouncement(
                        View.of(context),
                        L.of(context)!.semantic_announce_searching,
                        TextDirection.ltr,
                      );
                      _submitSearch(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_showLanding) ...[
            if (_recentSearches.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Searches',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _recentSearches.clear();
                              });
                            },
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _recentSearches
                            .map((term) => _RecentSearchChip(
                                  label: term,
                                  onTap: () {
                                    _searchController.text = term;
                                    _submitSearch(term, addToRecent: false);
                                  },
                                  onRemove: () {
                                    setState(() {
                                      _recentSearches.remove(term);
                                    });
                                  },
                                ))
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 0.0),
                child: Text(
                  'Browse Categories',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 24.0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = _categories[index];
                    return _SearchCategoryCard(
                      category: category,
                      onTap: () {
                        _searchController.text = category.label;
                        _submitSearch(category.label);
                      },
                    );
                  },
                  childCount: _categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  childAspectRatio: 0.9,
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Matching podcasts for "${_activeQuery.trim()}".',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SearchResults(data: bloc.results!),
          ],
        ],
      ),
    );
  }

  void _clearSearch(SearchBloc bloc) {
    setState(() {
      _activeQuery = '';
      _searchController.clear();
    });

    bloc.search(SearchClearEvent());
    FocusScope.of(context).requestFocus(_searchFocusNode);
    SystemChannels.textInput.invokeMethod<String>('TextInput.show');
  }

  void _submitSearch(
    String rawQuery, {
    bool addToRecent = true,
    bool requestFocus = true,
  }) {
    final query = rawQuery.trim();
    final bloc = Provider.of<SearchBloc>(context, listen: false);

    if (query.isEmpty) {
      _clearSearch(bloc);
      return;
    }

    setState(() {
      _activeQuery = query;

      if (addToRecent) {
        _recentSearches
          ..remove(query)
          ..insert(0, query);

        if (_recentSearches.length > 6) {
          _recentSearches.removeRange(6, _recentSearches.length);
        }
      }
    });

    if (requestFocus) {
      _searchFocusNode.unfocus();
    }

    bloc.search(SearchTermEvent(query));
  }
}

class _RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 10.0, 10.0, 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 6.0),
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close,
                    size: 16.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCategoryCard extends StatelessWidget {
  final _SearchCategory category;
  final VoidCallback onTap;

  const _SearchCategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(26.0),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.start,
                category.end,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 18.0,
                right: 18.0,
                child: Icon(
                  category.icon,
                  size: 54.0,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.32),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    category.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCategory {
  final String label;
  final IconData icon;
  final Color start;
  final Color end;

  const _SearchCategory({
    required this.label,
    required this.icon,
    required this.start,
    required this.end,
  });
}
