// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/chapter.dart';
import 'package:anytime/entities/episode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A [Widget] for displaying a list of Podcast chapters for those
/// podcasts that support that chapter tag.
// ignore: must_be_immutable
class ChapterSelector extends StatefulWidget {
  final Episode episode;
  final ItemScrollController itemScrollController = ItemScrollController();
  StreamSubscription positionSubscription;
  Chapter chapter;

  ChapterSelector({
    @required this.episode,
    @required this.chapter,
  });

  @override
  _ChapterSelectorState createState() => _ChapterSelectorState();
}

class _ChapterSelectorState extends State<ChapterSelector> {
  @override
  void initState() {
    super.initState();

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    Chapter lastChapter;
    var firstRender = true;

    // List for changes in position. If the change in position results in
    // a change in chapter we scroll to it. This ensures that the current
    // chapter is always visible.
    // TODO: Calculate which items are currently visible. Only jump/scroll
    // if the current chapter is not visible.
    widget.positionSubscription = audioBloc.playPosition.listen((event) {
      if (lastChapter == null || lastChapter != event.episode.currentChapter) {
        lastChapter = event.episode.currentChapter;

        var index = widget.episode.chapters.indexWhere((element) => element == lastChapter);

        if (index >= 0) {
          setState(() {
            widget.chapter = lastChapter;
          });

          if (firstRender) {
            widget.itemScrollController.jumpTo(index: index);
            firstRender = false;
          } else {
            widget.itemScrollController.scrollTo(index: index, duration: Duration(milliseconds: 250));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    final chapters = widget.episode.chapters;

    return ScrollablePositionedList.builder(
      itemScrollController: widget.itemScrollController,
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final chapterSelected = widget.chapter == chapter;

        return Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
          child: ListTile(
            onTap: () {
              audioBloc.transitionPosition(chapter.startTime.toDouble());
            },
            selected: chapterSelected,
            selectedTileColor: Theme.of(context).brightness == Brightness.light ? Colors.orange : Colors.grey[800],
            leading: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${index + 1}.',
                style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ),
            title: Text(
              '${chapters[index].title?.trim()}',
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            trailing: Text(
              _formatStartTime(chapters[index].startTime),
              style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.positionSubscription?.cancel();
    super.dispose();
  }

  String _formatStartTime(double startTime) {
    var time = Duration(seconds: startTime.ceil());
    var result = '';

    if (time.inHours > 0) {
      result =
          '${time.inHours}:${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${time.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } else {
      result = '${time.inMinutes}:${time.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }

    return result;
  }
}
