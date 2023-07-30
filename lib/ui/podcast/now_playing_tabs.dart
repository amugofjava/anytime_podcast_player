import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/ui/podcast/chapter_selector.dart';
import 'package:anytime/ui/podcast/dot_decoration.dart';
import 'package:anytime/ui/podcast/now_playing.dart';
import 'package:anytime/ui/podcast/now_playing_options.dart';
import 'package:anytime/ui/podcast/playback_error_listener.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NowPlayingTabs extends StatelessWidget {
  const NowPlayingTabs({
    super.key,
    required this.transportBuilder,
    required this.episode,
  });

  final WidgetBuilder? transportBuilder;
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: episode.hasChapters ? 3 : 2,
        initialIndex: episode.hasChapters ? 1 : 0,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context)
              .appBarTheme
              .systemOverlayStyle!
              .copyWith(systemNavigationBarColor: Theme.of(context).secondaryHeaderColor),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0.0,
              leading: IconButton(
                tooltip: L.of(context)!.minimise_player_window_button_label,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryIconTheme.color,
                ),
                onPressed: () => {
                  Navigator.pop(context),
                },
              ),
              flexibleSpace: PlaybackErrorListener(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    EpisodeTabBar(
                      chapters: episode.hasChapters,
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: EpisodeTabBarView(
                    episode: episode,
                    chapters: episode.hasChapters,
                  ),
                ),
                transportBuilder != null
                    ? transportBuilder!(context)
                    : const SizedBox(
                  height: 148.0,
                  child: NowPlayingTransport(),
                ),
                if (MediaQuery.of(context).orientation == Orientation.portrait)
                const Expanded(
                  flex: 1,
                  child: NowPlayingOptionsScaffold(),
                ),
              ],
            ),
          ),
        ));
  }
}

/// This class is responsible for rendering the tab selection at the top of the screen.
///
/// It displays two or three tabs depending upon whether the current episode supports
/// (and contains) chapters.
class EpisodeTabBar extends StatelessWidget {
  final bool chapters;

  const EpisodeTabBar({
    Key? key,
    this.chapters = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: DotDecoration(colour: Theme.of(context).primaryColor),
      tabs: [
        if (chapters)
          Tab(
            child: Align(
              alignment: Alignment.center,
              child: Text(L.of(context)!.chapters_label),
            ),
          ),
        Tab(
          child: Align(
            alignment: Alignment.center,
            child: Text(L.of(context)!.episode_label),
          ),
        ),
        Tab(
          child: Align(
            alignment: Alignment.center,
            child: Text(L.of(context)!.notes_label),
          ),
        ),
      ],
    );
  }
}

/// This class is responsible for rendering the tab body containing the chapter selection view (if
/// the episode supports chapters), the episode details (image and description) and the show
/// notes view.
class EpisodeTabBarView extends StatelessWidget {
  final Episode? episode;
  final AutoSizeGroup? textGroup;
  final bool chapters;

  const EpisodeTabBarView({
    Key? key,
    this.episode,
    this.textGroup,
    this.chapters = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context);

    return TabBarView(
      children: [
        if (chapters)
          ChapterSelector(
            episode: episode!,
          ),
        StreamBuilder<Episode?>(
            stream: audioBloc.nowPlaying,
            builder: (context, snapshot) {
              final e = snapshot.hasData ? snapshot.data! : episode!;

              return NowPlayingEpisode(
                episode: e,
                imageUrl: e.positionalImageUrl,
                textGroup: textGroup,
              );
            }),
        NowPlayingShowNotes(episode: episode),
      ],
    );
  }
}

