// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/transcript_view.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/draggable_episode_tile.dart';
import 'package:anytime/ui/widgets/slider_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';

/// This class gives us options that can be dragged up from the bottom of the main player
/// window. Currently these options are Up Next & Transcript. This class is an initial version
/// and should by much simpler than it is; however, a [NestedScrollView] is the widget we
/// need to implement this UI, there is a current issue whereby the scroll view and
/// [DraggableScrollableSheet] clash and therefore cannot be used together.
///
/// See issues (64157)[https://github.com/flutter/flutter/issues/64157]
///            (67219)[https://github.com/flutter/flutter/issues/67219]
///
/// If anyone can come up with a more elegant solution (and one that does not throw
/// an overflow error in debug) please raise and issue/submit a PR.
///
/// TODO: Extract contents of Up Next UI into separate widgets.
/// TODO: Extract contents of Transcript UI into separate widgets.
class NowPlayingOptionsSelector extends StatefulWidget {
  final double scrollPos;
  static const baseSize = 68.0;

  NowPlayingOptionsSelector({Key key, this.scrollPos}) : super(key: key);

  @override
  State<NowPlayingOptionsSelector> createState() => _NowPlayingOptionsSelectorState();
}

class _NowPlayingOptionsSelectorState extends State<NowPlayingOptionsSelector> {
  DraggableScrollableController draggableController;

  @override
  Widget build(BuildContext context) {
    final queueBloc = Provider.of<QueueBloc>(context, listen: false);
    final theme = Theme.of(context);
    final windowHeight = MediaQuery.of(context).size.height;
    final minSize = NowPlayingOptionsSelector.baseSize / (windowHeight - NowPlayingOptionsSelector.baseSize);
    final orientation = MediaQuery.of(context).orientation;

    return orientation == Orientation.portrait
        ? DraggableScrollableSheet(
            initialChildSize: minSize,
            minChildSize: minSize,
            maxChildSize: 1.0,
            controller: draggableController,
            // Snap doesn't work as the sheet and scroll controller just don't get along
            // snap: true,
            // snapSizes: [minSize, maxSize],
            builder: (BuildContext context, ScrollController scrollController) {
              return DefaultTabController(
                animationDuration: !draggableController.isAttached || draggableController.size <= minSize
                    ? const Duration(seconds: 0)
                    : kTabScrollDuration,
                length: 2,
                child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                        height: constraints.maxHeight,
                      ),
                      child: Material(
                        color: theme.secondaryHeaderColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Theme.of(context).highlightColor,
                            width: 0.0,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.0),
                            topRight: Radius.circular(18.0),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SliderHandle(),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.0),
                                border: Border(
                                  bottom: !draggableController.isAttached || draggableController.size <= minSize
                                      ? BorderSide.none
                                      : BorderSide(color: Colors.grey[800], width: 1.0),
                                ),
                              ),
                              child: TabBar(
                                automaticIndicatorColorAdjustment: false,
                                indicatorPadding: EdgeInsets.zero,

                                /// Little hack to hide the indicator when closed
                                indicatorColor: !draggableController.isAttached || draggableController.size <= minSize
                                    ? Theme.of(context).secondaryHeaderColor
                                    : null,
                                tabs: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      DefaultTabController.of(ctx).animateTo(0);

                                      if (draggableController.size <= 1.0) {
                                        draggableController.animateTo(
                                          1.0,
                                          duration: Duration(milliseconds: 150),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                      child: Text(
                                        L.of(context).up_next_queue_label.toUpperCase(),
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      DefaultTabController.of(ctx).animateTo(1);

                                      if (draggableController.size <= 1.0) {
                                        draggableController.animateTo(
                                          1.0,
                                          duration: Duration(milliseconds: 150),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                      child: Text(
                                        L.of(context).transcript_label.toUpperCase(),
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(padding: EdgeInsets.only(bottom: 12.0)),
                            Expanded(
                              child: StreamBuilder<QueueState>(
                                  initialData: QueueEmptyState(),
                                  stream: queueBloc.queue,
                                  builder: (context, snapshot) {
                                    return TabBarView(
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 24.0, 8.0),
                                                  child: Text(
                                                    L.of(context).now_playing_queue_label,
                                                    style: Theme.of(context).textTheme.titleLarge,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                                              child: DraggableEpisodeTile(
                                                key: Key('detileplaying'),
                                                episode: snapshot.data.playing,
                                                draggable: false,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 24.0, 8.0),
                                                  child: Text(
                                                    L.of(context).up_next_queue_label,
                                                    style: Theme.of(context).textTheme.titleLarge,
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
                                                                    ? L
                                                                        .of(context)
                                                                        .queue_clear_button_label
                                                                        .toUpperCase()
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
                                                      style: Theme.of(context).textTheme.titleSmall.copyWith(
                                                            fontSize: 12.0,
                                                            color: Theme.of(context).primaryColor,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            snapshot.hasData && snapshot.data.queue.isEmpty
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
                                                          style: Theme.of(context).textTheme.titleMedium,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Expanded(
                                                    child: ReorderableListView.builder(
                                                      buildDefaultDragHandles: false,
                                                      shrinkWrap: true,
                                                      padding: const EdgeInsets.all(8),
                                                      itemCount: snapshot.hasData ? snapshot.data.queue.length : 0,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        return Dismissible(
                                                          key: ValueKey('disqueue${snapshot.data.queue[index].guid}'),
                                                          direction: DismissDirection.endToStart,
                                                          onDismissed: (direction) {
                                                            queueBloc.queueEvent(
                                                                QueueRemoveEvent(episode: snapshot.data.queue[index]));
                                                          },
                                                          child: DraggableEpisodeTile(
                                                            key:
                                                                ValueKey('tilequeue${snapshot.data.queue[index].guid}'),
                                                            index: index,
                                                            episode: snapshot.data.queue[index],
                                                            playable: true,
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
                                                  ),
                                          ],
                                        ),
                                        TranscriptView(episode: snapshot.data.playing),
                                      ],
                                    );
                                  }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          )
        : SizedBox(
            height: 0.0,
            width: 0.0,
          );
  }

  @override
  void initState() {
    draggableController = DraggableScrollableController();
    super.initState();
  }
}

class NowPlayingOptionsScaffold extends StatelessWidget {
  const NowPlayingOptionsScaffold({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NowPlayingOptionsSelector.baseSize - 8.0,
    );
  }
}
