import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// This class is a simple, common wrapper around the flutter_html Html
/// widget. This wrapper allows us to remove some of the HTML tags which
/// can cause rendering issues when viewing podcast descriptions on a
/// mobile device.
class PodcastHtml extends StatelessWidget {
  final String content;
  final tagList = Html.tags;

  PodcastHtml({
    @required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Html(
      data: content ?? '',
      style: {
        'html': Style(
          fontWeight: textTheme.bodyText1.fontWeight,
        )
      },
      tagsList: tagList,
      onLinkTap: (url, _, __, ___) => canLaunch(url).then((value) => launch(url)),
    );
  }
}
