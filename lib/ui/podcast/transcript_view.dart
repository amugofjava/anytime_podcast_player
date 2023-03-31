// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/transcript.dart';
import 'package:flutter/material.dart';

/// This class handles the rendering of the podcast transcript (where available).
class TranscriptView extends StatefulWidget {
  final Transcript transcript;

  const TranscriptView({
    Key key,
    @required this.transcript,
  }) : super(key: key);

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  @override
  Widget build(BuildContext context) {
    final items = widget.transcript.subtitles;

    return Column(
      children: [
        /// Transcript controls will go here
        Placeholder(
          fallbackHeight: 96.0,
        ),
        Expanded(
          child: ListView.builder(itemBuilder: (BuildContext context, int index) {
            return Wrap(
              children: [
                SubtitleWidget(
                  subtitle: items[index],
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Each transcript is made up of one or more subtitles. Each [Subtitle] represents one
/// line of the transcript. This widget handles rendering the passed line.
class SubtitleWidget extends StatelessWidget {
  final Subtitle subtitle;

  const SubtitleWidget({
    Key key,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDuration(subtitle.start),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          subtitle.data,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Padding(padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0))
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hh = (duration.inHours).toString().padLeft(2, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }
}
