// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/podcast/episode_details.dart';
import 'package:anytime/ui/podcast/transcript_view.dart';
import 'package:anytime/ui/podcast/up_next_view.dart';
import 'package:anytime/ui/widgets/slider_handle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This class gives us options that can be dragged up from the bottom of the main player
/// window.
///
/// Currently these options are Up Next & Transcript.
///
/// This class is an initial version and should by much simpler than it is; however,
/// a [NestedScrollView] is the widget we need to implement this UI, there is a current
/// issue whereby the scroll view and [DraggableScrollableSheet] clash and therefore cannot
/// be used together.
///
/// See issues [64157](https://github.com/flutter/flutter/issues/64157)
///            [67219](https://github.com/flutter/flutter/issues/67219)
///
/// If anyone can come up with a more elegant solution (and one that does not throw
/// an overflow error in debug) please raise and issue/submit a PR.
///
class NowPlayingOptionsSelector extends StatefulWidget {
  final double? scrollPos;
  static const baseSize = 96.0;

  const NowPlayingOptionsSelector({super.key, this.scrollPos});

  @override
  State<NowPlayingOptionsSelector> createState() => _NowPlayingOptionsSelectorState();
}

class _NowPlayingOptionsSelectorState extends State<NowPlayingOptionsSelector> {
  DraggableScrollableController? draggableController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 0.0 ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        final minSize = (NowPlayingOptionsSelector.baseSize / availableHeight).clamp(0.0, 1.0).toDouble();

        return DraggableScrollableSheet(
          initialChildSize: minSize,
          minChildSize: minSize,
          maxChildSize: 1.0,
          controller: draggableController,
          // Snap doesn't work as the sheet and scroll controller just don't get along
          // snap: true,
          // snapSizes: [minSize, maxSize],
          builder: (BuildContext context, ScrollController scrollController) {
            return DefaultTabController(
              animationDuration: !draggableController!.isAttached || draggableController!.size <= minSize
                  ? const Duration(seconds: 0)
                  : kTabScrollDuration,
              length: 3,
              child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints.expand(
                      height: constraints.maxHeight,
                    ),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                          width: 0.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18.0),
                          topRight: Radius.circular(18.0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SliderHandle(
                            label: optionsSliderOpen()
                                ? L.of(context)!.semantic_playing_options_collapse_label
                                : L.of(context)!.semantic_playing_options_expand_label,
                            onTap: () {
                              if (draggableController != null) {
                                if (draggableController!.size < 1.0) {
                                  draggableController!.animateTo(
                                    1.0,
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  draggableController!.animateTo(
                                    0.0,
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              }
                            },
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.0),
                              border: Border(
                                bottom: draggableController != null &&
                                        (!draggableController!.isAttached || draggableController!.size <= minSize)
                                    ? BorderSide.none
                                    : BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                              ),
                            ),
                            child: TabBar(
                              onTap: (index) {
                                DefaultTabController.of(ctx).animateTo(index);

                                if (draggableController != null && draggableController!.size < 1.0) {
                                  draggableController!.animateTo(
                                    1.0,
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              automaticIndicatorColorAdjustment: false,
                              indicatorPadding: EdgeInsets.zero,

                              /// Little hack to hide the indicator when closed
                              indicatorColor: draggableController != null &&
                                      (!draggableController!.isAttached || draggableController!.size <= minSize)
                                  ? theme.colorScheme.surfaceContainerLow
                                  : null,
                              tabs: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Text(
                                    'AI',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Text(
                                    L.of(context)!.transcript_label.toUpperCase(),
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Text(
                                    L.of(context)!.up_next_queue_label.toUpperCase(),
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(bottom: 12.0)),
                          const Expanded(
                            child: TabBarView(
                              children: [
                                _NowPlayingAiTab(),
                                TranscriptView(),
                                UpNextView(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  bool optionsSliderOpen() {
    return (draggableController != null && draggableController!.isAttached && draggableController!.size == 1.0);
  }

  @override
  void initState() {
    draggableController = DraggableScrollableController();
    super.initState();
  }
}

class NowPlayingOptionsScaffold extends StatelessWidget {
  const NowPlayingOptionsScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: NowPlayingOptionsSelector.baseSize - 8.0,
    );
  }
}

/// This implementation displays the additional options in a tab set outside of a
/// draggable sheet.
///
/// Currently these options are Up Next & Transcript.
class NowPlayingOptionsSelectorWide extends StatefulWidget {
  final double? scrollPos;
  static const baseSize = 70.0;

  const NowPlayingOptionsSelectorWide({super.key, this.scrollPos});

  @override
  State<NowPlayingOptionsSelectorWide> createState() => _NowPlayingOptionsSelectorWideState();
}

class _NowPlayingOptionsSelectorWideState extends State<NowPlayingOptionsSelectorWide> {
  DraggableScrollableController? draggableController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollController = ScrollController();

    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(
              height: constraints.maxHeight,
            ),
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.0),
                      border: Border(
                        bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: TabBar(
                      automaticIndicatorColorAdjustment: false,
                      tabs: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: Text(
                            'AI',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: Text(
                            L.of(context)!.transcript_label.toUpperCase(),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: Text(
                            L.of(context)!.up_next_queue_label.toUpperCase(),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _NowPlayingAiTab(),
                        TranscriptView(),
                        UpNextView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NowPlayingAiTab extends StatelessWidget {
  const _NowPlayingAiTab();

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    return StreamBuilder<Episode?>(
      stream: audioBloc.nowPlaying,
      builder: (context, snapshot) {
        final episode = snapshot.data;

        if (episode == null) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: Text(
                  'Transcript, ad analysis, and detected skip blocks are available here while you listen.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              EpisodeAnalysisPanel(episode: episode),
            ],
          ),
        );
      },
    );
  }
}
