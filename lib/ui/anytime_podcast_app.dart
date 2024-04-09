// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/api/podcast/mobile_podcast_api.dart';
import 'package:anytime/api/podcast/podcast_api.dart';
import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/opml_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/bloc/search/search_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/bloc/ui/pager_bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/navigation/navigation_route_observer.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/audio/default_audio_player_service.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:anytime/services/download/mobile_download_manager.dart';
import 'package:anytime/services/download/mobile_download_service.dart';
import 'package:anytime/services/podcast/mobile_opml_service.dart';
import 'package:anytime/services/podcast/mobile_podcast_service.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/ui/library/discovery.dart';
import 'package:anytime/ui/library/downloads.dart';
import 'package:anytime/ui/library/library.dart';
import 'package:anytime/ui/podcast/mini_player.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/search/search.dart';
import 'package:anytime/ui/settings/settings.dart';
import 'package:anytime/ui/themes.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/layout_selector.dart';
import 'package:anytime/ui/widgets/search_slide_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

var theme = Themes.lightTheme().themeData;

/// Anytime is a Podcast player. You can search and subscribe to podcasts,
/// download and stream episodes and view the latest podcast charts.
// ignore: must_be_immutable
class AnytimePodcastApp extends StatefulWidget {
  final Repository repository;
  late PodcastApi podcastApi;
  late DownloadService downloadService;
  late AudioPlayerService audioPlayerService;
  late OPMLService opmlService;
  PodcastService? podcastService;
  SettingsBloc? settingsBloc;
  MobileSettingsService mobileSettingsService;
  List<int> certificateAuthorityBytes;

  AnytimePodcastApp({
    super.key,
    required this.mobileSettingsService,
    required this.certificateAuthorityBytes,
  }) : repository = SembastRepository() {
    podcastApi = MobilePodcastApi();

    podcastService = MobilePodcastService(
      api: podcastApi,
      repository: repository,
      settingsService: mobileSettingsService,
    );

    assert(podcastService != null);

    downloadService = MobileDownloadService(
      repository: repository,
      downloadManager: MobileDownloaderManager(),
      podcastService: podcastService!,
    );

    audioPlayerService = DefaultAudioPlayerService(
      repository: repository,
      settingsService: mobileSettingsService,
      podcastService: podcastService!,
    );

    settingsBloc = SettingsBloc(mobileSettingsService);

    opmlService = MobileOPMLService(
      podcastService: podcastService!,
      repository: repository,
    );

    podcastApi.addClientAuthorityBytes(certificateAuthorityBytes);
  }

  @override
  AnytimePodcastAppState createState() => AnytimePodcastAppState();
}

class AnytimePodcastAppState extends State<AnytimePodcastApp> {
  ThemeData? theme;

  @override
  void initState() {
    super.initState();

    /// Listen to theme change events from settings.
    widget.settingsBloc!.settings.listen((event) {
      setState(() {
        var newTheme = event.theme == 'dark' ? Themes.darkTheme().themeData : Themes.lightTheme().themeData;

        /// Only update the theme if it has changed.
        if (newTheme != theme) {
          theme = newTheme;
        }
      });
    });

    if (widget.mobileSettingsService.themeDarkMode) {
      theme = Themes.darkTheme().themeData;
    } else {
      theme = Themes.lightTheme().themeData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SearchBloc>(
          create: (_) => SearchBloc(
            podcastService: widget.podcastService!,
          ),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<DiscoveryBloc>(
          create: (_) => DiscoveryBloc(
            podcastService: widget.podcastService!,
          ),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<EpisodeBloc>(
          create: (_) =>
              EpisodeBloc(podcastService: widget.podcastService!, audioPlayerService: widget.audioPlayerService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<PodcastBloc>(
          create: (_) => PodcastBloc(
              podcastService: widget.podcastService!,
              audioPlayerService: widget.audioPlayerService,
              downloadService: widget.downloadService,
              settingsService: widget.mobileSettingsService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<PagerBloc>(
          create: (_) => PagerBloc(),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<AudioBloc>(
          create: (_) => AudioBloc(audioPlayerService: widget.audioPlayerService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<SettingsBloc?>(
          create: (_) => widget.settingsBloc,
          dispose: (_, value) => value!.dispose(),
        ),
        Provider<OPMLBloc>(
          create: (_) => OPMLBloc(opmlService: widget.opmlService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<QueueBloc>(
          create: (_) => QueueBloc(
            audioPlayerService: widget.audioPlayerService,
            podcastService: widget.podcastService!,
          ),
          dispose: (_, value) => value.dispose(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false,
        title: 'Anytime Podcast Player',
        navigatorObservers: [NavigationRouteObserver()],
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AnytimeLocalisationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('de', ''),
          Locale('it', ''),
        ],
        theme: theme,
        // Uncomment builder below to enable accessibility checker tool.
        // builder: (context, child) => AccessibilityTools(child: child),
        home: const AnytimeHomePage(title: 'Anytime Podcast Player'),
      ),
    );
  }
}

class AnytimeHomePage extends StatefulWidget {
  final String? title;
  final bool topBarVisible;
  final bool inlineSearch;

  const AnytimeHomePage({
    super.key,
    this.title,
    this.topBarVisible = true,
    this.inlineSearch = false,
  });

  @override
  State<AnytimeHomePage> createState() => _AnytimeHomePageState();
}

class _AnytimeHomePageState extends State<AnytimeHomePage> with WidgetsBindingObserver {
  StreamSubscription? deepLinkSubscription;

  final log = Logger('_AnytimeHomePageState');
  bool handledInitialLink = false;
  Widget? library;

  @override
  void initState() {
    super.initState();

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    WidgetsBinding.instance.addObserver(this);

    audioBloc.transitionLifecycleState(LifecycleState.resume);

    /// Handle deep links
    _setupLinkListener();
  }

  /// We listen to external links from outside the app. For example, someone may navigate
  /// to a web page that supports 'Open with Anytime'.
  void _setupLinkListener() async {
    /// First, setup a handler to listen for links whilst Anytime is running - a warm start
    deepLinkSubscription = uriLinkStream.listen((uri) async {
      _handleLinkEvent(uri!);
    });

    /// Handle initial link
    if (!handledInitialLink) {
      handledInitialLink = true;

      final uri = await getInitialUri();

      if (uri != null) {
        _handleLinkEvent(uri);
      }
    }
  }

  /// This method handles the actual link supplied from [uni_links], either
  /// at app startup or during running.
  void _handleLinkEvent(Uri uri) async {
    if (uri.scheme == 'anytime-subscribe' && uri.query.startsWith('uri=')) {
      var path = uri.query.substring(4);
      var loadPodcastBloc = Provider.of<PodcastBloc>(context, listen: false);
      var routeName = NavigationRouteObserver().top!.settings.name;

      /// If we are currently on the podcast details page, we can simply request (via
      /// the BLoC) that we load this new URL. If not, we pop the stack until we are
      /// back at root and then load the podcast details page.
      if (routeName != null && routeName == 'podcastdetails') {
        loadPodcastBloc.load(Feed(
          podcast: Podcast.fromUrl(url: path),
          backgroundFresh: false,
          silently: false,
        ));
      } else {
        /// Pop back to route.
        Navigator.of(context).popUntil((route) {
          var currentRouteName = NavigationRouteObserver().top!.settings.name;

          return currentRouteName == null || currentRouteName == '' || currentRouteName == '/';
        });

        /// Once we have reached the root route, push podcast details.
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              fullscreenDialog: true,
              settings: const RouteSettings(name: 'podcastdetails'),
              builder: (context) => PodcastDetails(Podcast.fromUrl(url: path), loadPodcastBloc)),
        );
      }
    }
  }

  @override
  void dispose() {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    audioBloc.transitionLifecycleState(LifecycleState.pause);

    deepLinkSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    switch (state) {
      case AppLifecycleState.resumed:
        audioBloc.transitionLifecycleState(LifecycleState.resume);
        break;
      case AppLifecycleState.paused:
        audioBloc.transitionLifecycleState(LifecycleState.pause);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pager = Provider.of<PagerBloc>(context);
    final searchBloc = Provider.of<EpisodeBloc>(context);
    final backgroundColour = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        backgroundColor: backgroundColour,
        body: Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverVisibility(
                    visible: widget.topBarVisible,
                    sliver: SliverAppBar(
                      title: ExcludeSemantics(
                        child: TitleWidget(),
                      ),
                      backgroundColor: backgroundColour,
                      floating: false,
                      pinned: true,
                      snap: false,
                      actions: <Widget>[
                        IconButton(
                          tooltip: L.of(context)!.search_for_podcasts_hint,
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              defaultTargetPlatform == TargetPlatform.iOS
                                  ? MaterialPageRoute<void>(
                                      fullscreenDialog: false,
                                      settings: const RouteSettings(name: 'search'),
                                      builder: (context) => const Search())
                                  : SlideRightRoute(
                                      widget: const Search(),
                                      settings: const RouteSettings(name: 'search'),
                                    ),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: _menuSelect,
                          icon: const Icon(
                            Icons.more_vert,
                          ),
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              if (feedbackUrl.isNotEmpty)
                                PopupMenuItem<String>(
                                  textStyle: Theme.of(context).textTheme.titleMedium,
                                  value: 'feedback',
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.feedback_outlined, size: 18.0),
                                      ),
                                      Text(L.of(context)!.feedback_menu_item_label),
                                    ],
                                  ),
                                ),
                              PopupMenuItem<String>(
                                textStyle: Theme.of(context).textTheme.titleMedium,
                                value: 'layout',
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.dashboard, size: 18.0),
                                    ),
                                    Text(L.of(context)!.layout_label),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                textStyle: Theme.of(context).textTheme.titleMedium,
                                value: 'rss',
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.rss_feed, size: 18.0),
                                    ),
                                    Text(L.of(context)!.add_rss_feed_option),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                textStyle: Theme.of(context).textTheme.titleMedium,
                                value: 'settings',
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.settings, size: 18.0),
                                    ),
                                    Text(L.of(context)!.settings_label),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                textStyle: Theme.of(context).textTheme.titleMedium,
                                value: 'about',
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.info_outline, size: 18.0),
                                    ),
                                    Text(L.of(context)!.about_label),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<int>(
                      stream: pager.currentPage,
                      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                        return _fragment(snapshot.data, searchBloc);
                      }),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: StreamBuilder<int>(
            stream: pager.currentPage,
            initialData: 0,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              int index = snapshot.data ?? 0;

              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).bottomAppBarTheme.color,
                selectedIconTheme: Theme.of(context).iconTheme,
                selectedItemColor: Theme.of(context).iconTheme.color,
                selectedFontSize: 11.0,
                unselectedFontSize: 11.0,
                unselectedItemColor:
                    HSLColor.fromColor(Theme.of(context).bottomAppBarTheme.color!).withLightness(0.8).toColor(),
                currentIndex: index,
                onTap: pager.changePage,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: index == 0 ? const Icon(Icons.library_music) : const Icon(Icons.library_music_outlined),
                    label: L.of(context)!.library,
                  ),
                  // To be fleshed out later.
                  // BottomNavigationBarItem(
                  //   icon: index == 0 ? Icon(Icons.article_rounded) : Icon(Icons.article_outlined),
                  //   label: 'Episodes',
                  // ),
                  BottomNavigationBarItem(
                    icon: index == 1 ? const Icon(Icons.explore) : const Icon(Icons.explore_outlined),
                    label: L.of(context)!.discover,
                  ),
                  BottomNavigationBarItem(
                    icon: index == 2 ? const Icon(Icons.download) : const Icon(Icons.download_outlined),
                    label: L.of(context)!.downloads,
                  ),
                ],
              );
            }),
      ),
    );
  }

  Widget _fragment(int? index, EpisodeBloc searchBloc) {
    if (index == 0) {
      return const Library();
    } else if (index == 1) {
      return Discovery(
        categories: true,
        inlineSearch: widget.inlineSearch,
      );
    } else {
      return const Downloads();
    }
  }

  void _menuSelect(String choice) async {
    var textFieldController = TextEditingController();
    var podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final theme = Theme.of(context);
    var url = '';

    switch (choice) {
      case 'about':
        showAboutDialog(
            context: context,
            applicationName: 'Anytime Podcast Player',
            applicationVersion: 'v${Environment.projectVersion}',
            applicationIcon: Image.asset(
              'assets/images/anytime-logo-s.png',
              width: 52.0,
              height: 52.0,
            ),
            children: <Widget>[
              const Text('\u00a9 2020 Ben Hills'),
              GestureDetector(
                onTap: () {
                  _launchEmail();
                },
                child: Text(
                  'hello@anytimeplayer.app',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Theme.of(context).indicatorColor,
                  ),
                ),
              ),
            ]);
        break;
      case 'settings':
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'settings'),
            builder: (context) => const Settings(),
          ),
        );
        break;
      case 'feedback':
        _launchFeedback();
        break;
      case 'layout':
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.secondaryHeaderColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          builder: (context) => const LayoutSelectorWidget(),
        );
        break;
      case 'rss':
        await showPlatformDialog<void>(
          context: context,
          useRootNavigator: false,
          builder: (_) => BasicDialogAlert(
            title: Text(L.of(context)!.add_rss_feed_option),
            content: Material(
              color: Colors.transparent,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    url = value;
                  });
                },
                controller: textFieldController,
                decoration: const InputDecoration(hintText: 'https://'),
              ),
            ),
            actions: <Widget>[
              BasicDialogAction(
                title: ActionText(
                  L.of(context)!.cancel_button_label,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              BasicDialogAction(
                title: ActionText(
                  L.of(context)!.ok_button_label,
                ),
                iosIsDefaultAction: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        settings: const RouteSettings(name: 'podcastdetails'),
                        builder: (context) => PodcastDetails(Podcast.fromUrl(url: url), podcastBloc)),
                  ).then((value) => Navigator.pop(context));
                },
              ),
            ],
          ),
        );
        break;
    }
  }

  void _launchFeedback() async {
    final uri = Uri.parse(feedbackUrl);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $uri');
    }
  }

  void _launchEmail() async {
    final uri = Uri.parse('mailto:hello@anytimeplayer.app');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }
}

class TitleWidget extends StatelessWidget {
  final TextStyle _titleTheme1 = theme.textTheme.bodyMedium!.copyWith(
    color: const Color.fromARGB(255, 255, 153, 0),
    fontWeight: FontWeight.bold,
    fontFamily: 'MontserratRegular',
    fontSize: 18,
  );

  final TextStyle _titleTheme2Light = theme.textTheme.bodyMedium!.copyWith(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontFamily: 'MontserratRegular',
    fontSize: 18,
  );

  final TextStyle _titleTheme2Dark = theme.textTheme.bodyMedium!.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: 'MontserratRegular',
    fontSize: 18,
  );

  TitleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Row(
        children: <Widget>[
          Text(
            'Anytime ',
            style: _titleTheme1,
          ),
          Text(
            'Player',
            style: Theme.of(context).brightness == Brightness.light ? _titleTheme2Light : _titleTheme2Dark,
          ),
        ],
      ),
    );
  }
}
