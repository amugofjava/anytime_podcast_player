// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/bloc/podcast/queue_event_state.dart';
import 'package:anytime/ui/widgets/draggable_episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NowPlayingOptionsSelector extends StatefulWidget {
  const NowPlayingOptionsSelector({Key key}) : super(key: key);

  @override
  _NowPlayingOptionsSelectorState createState() => _NowPlayingOptionsSelectorState();
}

class _NowPlayingOptionsSelectorState extends State<NowPlayingOptionsSelector> {
  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    const baseSize = 48;
    final theme = Theme.of(context);
    const minHeight = baseSize;
    final windowHeight = MediaQuery.of(context).size.height - minHeight;
    final minSize = minHeight / windowHeight;
    final maxSize = 0.95;

    return DraggableScrollableSheet(
      initialChildSize: minSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: [minSize, maxSize],
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Material(
            color: theme.bottomAppBarColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.0),
                topRight: Radius.circular(18.0),
              ),
            ),
            child: SizedBox(
              height: windowHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      "UP NEXT",
                      style: Theme.of(context).textTheme.button,
                    ),
                  ),
                  Divider(),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 24.0, 8.0),
                        child: Text(
                          'Now Playing',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<QueueState>(
                    initialData: QueueEmptyState(),
                    stream: queueBloc.queue,
                    builder: (context, snapshot) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DraggableEpisodeTile(
                          key: Key('detileplaying'),
                          episode: snapshot.data.playing,
                          draggable: false,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 24.0, 8.0),
                        child: Text(
                          'Up Next',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<QueueState>(
                        initialData: QueueEmptyState(),
                        stream: queueBloc.queue,
                        builder: (context, snapshot) {
                          return snapshot.hasData && snapshot.data.queue.isEmpty
                              ? Text('EMPTY')
                              : ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: snapshot.hasData ? snapshot.data.queue.length : 0,
                                  itemBuilder: (BuildContext context, int index) {
                                    return DraggableEpisodeTile(
                                      key: Key('detile$index'),
                                      index: index,
                                      episode: snapshot.data.queue[index],
                                    );
                                  },
                                  onReorder: (int oldIndex, int newIndex) {
                                    /// Seems odd to have to do this, but this -1 was taken from
                                    /// the Flutter docs.
                                    if (oldIndex < newIndex) {
                                      newIndex -= 1;
                                    }

                                    queueBloc.queueEvent(QueueMoveEvent(
                                      episode: snapshot.data.queue[oldIndex],
                                      oldIndex: oldIndex,
                                      newIndex: newIndex,
                                    ));
                                  },
                                );
                        }),
                  ),
                  Divider(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NowPlayingOptionsPadding extends StatelessWidget {
  const NowPlayingOptionsPadding({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const minHeight = kToolbarHeight;
    final windowHeight = MediaQuery.of(context).size.height - minHeight;
    final minSize = minHeight / windowHeight;
    final maxSize = 0.95;

    return SizedBox(
      height: 44.0,
    );
  }
}
