// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/draggable_episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

class NowPlayingOptionsSelector extends StatefulWidget {
  final double scrollPos;

  NowPlayingOptionsSelector({Key key, this.scrollPos}) : super(key: key);

  @override
  _NowPlayingOptionsSelectorState createState() => _NowPlayingOptionsSelectorState();
}

class _NowPlayingOptionsSelectorState extends State<NowPlayingOptionsSelector> {
  bool showContainer = false;
  double o = 0.0;

  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    const baseSize = 48;
    final topMargin = baseSize + MediaQuery.of(context).viewPadding.top;
    final theme = Theme.of(context);
    final windowHeight = MediaQuery.of(context).size.height;
    final minSize = baseSize / (windowHeight - baseSize);
    final maxSize = (windowHeight - topMargin - 16) / windowHeight;

    return DraggableScrollableSheet(
      initialChildSize: minSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      // snap: true,
      // snapSizes: [minSize, maxSize],
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Material(
            color: theme.secondaryHeaderColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.0),
                topRight: Radius.circular(18.0),
              ),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 64 - MediaQuery.of(context).viewPadding.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 36,
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
                      L.of(context).up_next_queue_label.toUpperCase(),
                      style: Theme.of(context).textTheme.button,
                    ),
                  ),
                  Divider(),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 24.0, 8.0),
                        child: Text(
                          L.of(context).now_playing_queue_label,
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
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                        child: DraggableEpisodeTile(
                          key: Key('detileplaying'),
                          episode: snapshot.data.playing,
                          draggable: false,
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 24.0, 8.0),
                        child: Text(
                          L.of(context).up_next_queue_label,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 24.0, 8.0),
                        child: TextButton(
                          onPressed: () {
                            showPlatformDialog<void>(
                              context: context,
                              useRootNavigator: false,
                              builder: (_) => BasicDialogAlert(
                                title: Text(
                                  L.of(context).queue_clear_label_title,
                                ),
                                content: Text(L.of(context).queue_clear_label),
                                actions: <Widget>[
                                  BasicDialogAction(
                                    title: ActionText(
                                      L.of(context).cancel_button_label,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  BasicDialogAction(
                                    title: ActionText(
                                      Theme.of(context).platform == TargetPlatform.iOS
                                          ? L.of(context).queue_clear_button_label.toUpperCase()
                                          : L.of(context).queue_clear_button_label,
                                    ),
                                    iosIsDefaultAction: true,
                                    iosIsDestructiveAction: true,
                                    onPressed: () {
                                      queueBloc.queueEvent(QueueClearEvent());
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            L.of(context).clear_queue_button_label,
                            style: Theme.of(context).textTheme.subtitle2.copyWith(
                                  fontSize: 12.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<QueueState>(
                      initialData: QueueEmptyState(),
                      stream: queueBloc.queue,
                      builder: (context, snapshot) {
                        return snapshot.hasData && snapshot.data.queue.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).dividerColor,
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      L.of(context).empty_queue_message,
                                      style: Theme.of(context).textTheme.subtitle1,
                                    ),
                                  ),
                                ),
                              )
                            : Expanded(
                                child: ReorderableListView.builder(
                                  /// Temp set to true to get over Flutter 3 drag bug. Downside is that
                                  /// drag start is via a long press. Hopefully this will be fixed soon.
                                  buildDefaultDragHandles: true,
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: snapshot.hasData ? snapshot.data.queue.length : 0,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Dismissible(
                                      key: ValueKey('disqueue${snapshot.data.queue[index].guid}'),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        queueBloc.queueEvent(QueueRemoveEvent(episode: snapshot.data.queue[index]));
                                      },
                                      child: DraggableEpisodeTile(
                                        key: ValueKey('tilequeue${snapshot.data.queue[index].guid}'),
                                        index: index,
                                        episode: snapshot.data.queue[index],
                                      ),
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
                                ),
                              );
                      }),
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
    // const minHeight = kToolbarHeight;
    // final windowHeight = MediaQuery.of(context).size.height - minHeight;
    // final minSize = minHeight / windowHeight;
    // final maxSize = 0.95;

    return SizedBox(
      height: 44.0,
    );
  }
}
