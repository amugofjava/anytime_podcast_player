// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

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
import 'package:anytime/services/notifications/mobile_notification_service.dart';
import 'package:anytime/services/notifications/notification_service.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/openai_episode_analysis_service.dart';
import 'package:anytime/services/podcast/mobile_opml_service.dart';
import 'package:anytime/services/podcast/mobile_podcast_service.dart';
import 'package:anytime/services/podcast/opml_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/secrets/mobile_secure_secrets_service.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/services/transcription/openai_episode_transcription_service.dart';
import 'package:anytime/services/transcription/whisper_episode_transcription_service.dart';
import 'package:anytime/state/library_state.dart';
import 'package:anytime/ui/library/discovery.dart';
import 'package:anytime/ui/library/downloads.dart';
import 'package:anytime/ui/library/library.dart';
import 'package:anytime/ui/app_scaffold_messenger.dart';
import 'package:anytime/ui/podcast/mini_player.dart';
import 'package:anytime/ui/podcast/podcast_details.dart';
import 'package:anytime/ui/podcast/up_next_view.dart';
import 'package:anytime/ui/search/search.dart';
import 'package:anytime/ui/settings/settings.dart';
import 'package:anytime/ui/themes.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/layout_selector.dart';
import 'package:anytime/ui/widgets/search_slide_route.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings/settings_service.dart';

/// Anytime is a Podcast player. You can search and subscribe to podcasts,
/// download and stream episodes and view the latest podcast charts.
// ignore: must_be_immutable
class AnytimePodcastApp extends StatefulWidget {
  final Repository repository;
  late PodcastApi podcastApi;
  late DownloadService downloadService;
  late NotificationService notificationService;
  late AudioPlayerService audioPlayerService;
  late EpisodeAnalysisService episodeAnalysisService;
  late EpisodeTranscriptionService episodeTranscriptionService;
  late OPMLService opmlService;
  late SecureSecretsService secureSecretsService;
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
    notificationService = MobileNotificationService();
    secureSecretsService = MobileSecureSecretsService();
    episodeAnalysisService = ConfigurableEpisodeAnalysisService(
      settingsService: mobileSettingsService,
      secureSecretsService: secureSecretsService,
      backendService: Environment.hasAnalysisBackend ? BackendEpisodeAnalysisService() : null,
    );
    final localTranscriptionService = !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
        ? WhisperEpisodeTranscriptionService()
        : DisabledEpisodeTranscriptionService();
    episodeTranscriptionService = ConfigurableEpisodeTranscriptionService(
      settingsService: mobileSettingsService,
      secureSecretsService: secureSecretsService,
      localService: localTranscriptionService,
    );

    podcastService = MobilePodcastService(
      api: podcastApi,
      repository: repository,
      notificationService: notificationService,
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

    settingsBloc = SettingsBloc(
      settingsService: mobileSettingsService,
      notificationService: notificationService,
    );

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
        var newTheme = Themes.darkTheme().themeData;

        /// As we add new themes, we will move this selection into its own theme module.
        switch (event.theme) {
          case 'system':
            var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
            newTheme = brightness == Brightness.dark ? Themes.darkTheme().themeData : Themes.lightTheme().themeData;
            break;
          case 'light':
            newTheme = Themes.lightTheme().themeData;
            break;
          case 'dark':
            newTheme = Themes.darkTheme().themeData;
            break;
        }

        /// Only update the theme if it has changed.
        if (newTheme != theme) {
          theme = newTheme;
        }
      });
    });
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
          create: (_) => EpisodeBloc(
            podcastService: widget.podcastService!,
            audioPlayerService: widget.audioPlayerService,
            analysisService: widget.episodeAnalysisService,
            settingsService: widget.mobileSettingsService,
            transcriptionService: widget.episodeTranscriptionService,
          ),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<PodcastBloc>(
          create: (_) => PodcastBloc(
              podcastService: widget.podcastService!,
              audioPlayerService: widget.audioPlayerService,
              downloadService: widget.downloadService,
              notificationService: widget.notificationService,
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
        Provider<SecureSecretsService>.value(
          value: widget.secureSecretsService,
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
        scaffoldMessengerKey: appScaffoldMessengerKey,
        navigatorObservers: [NavigationRouteObserver()],
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AnytimeLocalisationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('es', ''),
          Locale('de', ''),
          Locale('gl', ''),
          Locale('it', ''),
          Locale('nl', ''),
          Locale('ru', ''),
          Locale('tr', ''),
          Locale('vi', ''),
          Locale('zh_Hans', ''),
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

  const AnytimeHomePage({
    super.key,
    this.title,
    this.topBarVisible = true,
  });

  @override
  State<AnytimeHomePage> createState() => _AnytimeHomePageState();
}

class _AnytimeHomePageState extends State<AnytimeHomePage> with WidgetsBindingObserver {
  StreamSubscription<Uri>? deepLinkSubscription;

  final log = Logger('_AnytimeHomePageState');
  bool handledInitialLink = false;
  bool libraryRefreshing = false;
  Widget? library;

  @override
  void initState() {
    super.initState();

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

    WidgetsBinding.instance.addObserver(this);

    /// TODO: These should auto register and trigger.
    audioBloc.transitionLifecycleState(LifecycleState.resume);
    podcastBloc.transitionLifecycleState(LifecycleState.resume);

    /// Handle deep links
    _setupLinkListener();

    /// Handle library updates and enable/disable the manual refresh menu item as appropriate.
    Provider.of<PodcastBloc>(context, listen: false).libraryListener.listen((d) {
      setState(() {
        libraryRefreshing = (d is LibraryRefreshingState);
      });
    });
  }

  /// We listen to external links from outside the app. For example, someone may navigate
  /// to a web page that supports 'Open with Anytime'.
  void _setupLinkListener() async {
    final appLinks = AppLinks(); // AppLinks is singleton

    // Subscribe to all events (initial link and further)
    deepLinkSubscription = appLinks.uriLinkStream.listen((uri) {
      // Do something (navigation, ...)
      _handleLinkEvent(uri);
    });
  }

  /// This method handles the actual link supplied from [uni_links], either
  /// at app startup or during running.
  void _handleLinkEvent(Uri uri) async {
    if ((uri.scheme == 'anytime-subscribe' || uri.scheme == 'https') &&
        (uri.query.startsWith('uri=') || uri.query.startsWith('url='))) {
      var path = uri.query.substring(4);
      var loadPodcastBloc = Provider.of<PodcastBloc>(context, listen: false);
      var routeName = NavigationRouteObserver().top!.settings.name;

      /// If we are currently on the podcast details page, we can simply request (via
      /// the BLoC) that we load this new URL. If not, we pop the stack until we are
      /// back at root and then load the podcast details page.
      if (routeName != null && routeName == 'podcastdetails') {
        loadPodcastBloc.load(Feed(
          podcast: Podcast.fromUrl(url: path),
          backgroundFetch: false,
          errorSilently: false,
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
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

    audioBloc.transitionLifecycleState(LifecycleState.detach);
    podcastBloc.transitionLifecycleState(LifecycleState.detach);

    deepLinkSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    var settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    switch (state) {
      case AppLifecycleState.resumed:
        audioBloc.transitionLifecycleState(LifecycleState.resume);
        podcastBloc.transitionLifecycleState(LifecycleState.resume);
        if (context.mounted) {
          SettingsService? settings = await MobileSettingsService.instance();
          settingsBloc.theme(settings!.theme);
        }
        break;
      case AppLifecycleState.paused:
        audioBloc.transitionLifecycleState(LifecycleState.pause);
        podcastBloc.transitionLifecycleState(LifecycleState.pause);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pager = Provider.of<PagerBloc>(context);
    final searchBloc = Provider.of<EpisodeBloc>(context);
    final colorScheme = theme.colorScheme;
    final backgroundColour = colorScheme.surface;
    final homeTheme = theme.copyWith(
      snackBarTheme: theme.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.fixed,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.appBarTheme.systemOverlayStyle!,
      child: Theme(
        data: homeTheme,
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
                        title: const ExcludeSemantics(
                          child: TitleWidget(),
                        ),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        surfaceTintColor: Colors.transparent,
                        toolbarHeight: 74.0,
                        floating: false,
                        pinned: true,
                        snap: false,
                        actions: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.search,
                              semanticLabel: L.of(context)!.search_for_podcasts_hint,
                            ),
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
                          IconButton(
                            icon: Icon(
                              Icons.format_list_numbered_rounded,
                              semanticLabel: L.of(context)!.open_up_next_hint,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  fullscreenDialog: false,
                                  settings: const RouteSettings(name: 'queue'),
                                  builder: (context) => const UpNextPage(),
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
                                    textStyle: theme.textTheme.titleMedium,
                                    value: 'feedback',
                                    child: Focus(
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
                                  ),
                                PopupMenuItem<String>(
                                  textStyle: theme.textTheme.titleMedium,
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
                                  textStyle: theme.textTheme.titleMedium,
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
                                  textStyle: theme.textTheme.titleMedium,
                                  value: 'library',
                                  enabled: !libraryRefreshing,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.refresh, size: 18.0),
                                      ),
                                      Text(L.of(context)!.update_library_option),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  textStyle: theme.textTheme.titleMedium,
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
                                  textStyle: theme.textTheme.titleMedium,
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

                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.0),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: NavigationBar(
                          selectedIndex: index,
                          onDestinationSelected: pager.changePage,
                          destinations: <NavigationDestination>[
                            NavigationDestination(
                              selectedIcon: const Icon(Icons.library_music),
                              icon: const Icon(Icons.library_music_outlined),
                              label: L.of(context)!.library,
                            ),
                            NavigationDestination(
                              selectedIcon: const Icon(Icons.explore),
                              icon: const Icon(Icons.explore_outlined),
                              label: L.of(context)!.discover,
                            ),
                            NavigationDestination(
                              selectedIcon: const Icon(Icons.download),
                              icon: const Icon(Icons.download_outlined),
                              label: L.of(context)!.downloads,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget _fragment(int? index, EpisodeBloc searchBloc) {
    if (index == 0) {
      return const Library();
    } else if (index == 1) {
      return const Discovery(
        categories: true,
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
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ]);
        break;
      case 'settings':
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            fullscreenDialog: true,
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
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          barrierLabel: L.of(context)!.scrim_layout_selector,
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
                  ).then((value) {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            ],
          ),
        );
        break;
      case 'library':
        _updateLibrary();
        break;
    }
  }

  void _updateLibrary() async {
    var podcastBloc = Provider.of<PodcastBloc>(context, listen: false);

    podcastBloc.podcastEvent(PodcastEvent.refreshSubscriptions);
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
  const TitleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 2.0, right: 8.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 18.0,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            'Anytime',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
