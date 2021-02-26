import 'package:anytime/ui/search/search_bar.dart';
import 'package:anytime/ui/widgets/podcast_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:podcast_search/podcast_search.dart' as search;

class PodcastListWithSearchBar extends StatelessWidget {
  final search.SearchResult results;

  const PodcastListWithSearchBar({Key key, @required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ShrinkWrappingViewport(
        offset: ViewportOffset.zero(),
        slivers: [
          SliverToBoxAdapter(child: SearchBar()),
          PodcastList(results: results),
        ],
      ),
    );
  }
}
