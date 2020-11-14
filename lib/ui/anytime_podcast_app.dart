// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/api/podcast/mobile_podcast_api.dart';
import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/search/search_bloc.dart';
import 'package:anytime/bloc/ui/pager_bloc.dart';
import 'package:anytime/core/chrome.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/repository/repository.dart';
import 'package:anytime/repository/sembast/sembast_repository.dart';
import 'package:anytime/services/audio/audio_player_service.dart';
import 'package:anytime/services/audio/mobile_audio_service.dart';
import 'package:anytime/services/download/download_service.dart';
import 'package:anytime/services/download/mobile_download_service.dart';
import 'package:anytime/services/podcast/mobile_podcast_service.dart';
import 'package:anytime/services/podcast/podcast_service.dart';
import 'package:anytime/services/settings/mobile_settings_service.dart';
import 'package:anytime/ui/library/discovery.dart';
import 'package:anytime/ui/library/downloads.dart';
import 'package:anytime/ui/library/library.dart';
import 'package:anytime/ui/search/search.dart';
import 'package:anytime/ui/settings/settings.dart';
import 'package:anytime/ui/themes.dart';
import 'package:anytime/ui/widgets/mini_player_widget.dart';
import 'package:anytime/ui/widgets/search_slide_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

final theme = Themes.lightTheme().themeData;

/// Anytime is a Podcast player. You can search and subscribe to podcasts,
/// download and stream episodes and view the latest podcast charts.
// ignore: must_be_immutable
class AnytimePodcastApp extends StatelessWidget {
  final Repository repository;
  final MobilePodcastApi podcastApi;
  DownloadService downloadService;
  PodcastService podcastService;
  AudioPlayerService audioPlayerService;

  // Initialise all the services our application will need.
  AnytimePodcastApp()
      : repository = SembastRepository(),
        podcastApi = MobilePodcastApi() {
    downloadService = MobileDownloadService(repository: repository);
    podcastService = MobilePodcastService(api: podcastApi, repository: repository);
    audioPlayerService = MobileAudioPlayerService(repository: repository);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SearchBloc>(
          create: (_) => SearchBloc(podcastService: MobilePodcastService(api: podcastApi, repository: repository)),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<DiscoveryBloc>(
          create: (_) => DiscoveryBloc(podcastService: MobilePodcastService(api: podcastApi, repository: repository)),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<EpisodeBloc>(
          create: (_) => EpisodeBloc(
              podcastService: MobilePodcastService(api: podcastApi, repository: repository),
              audioPlayerService: audioPlayerService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<PodcastBloc>(
          create: (_) =>
              PodcastBloc(podcastService: podcastService, audioPlayerService: audioPlayerService, downloadService: downloadService),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<PagerBloc>(
          create: (_) => PagerBloc(),
          dispose: (_, value) => value.dispose(),
        ),
        Provider<AudioBloc>(
          create: (_) => AudioBloc(audioPlayerService: audioPlayerService),
          dispose: (_, value) => value.dispose(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Anytime Podcast Player',
        localizationsDelegates: [
          const LocalisationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''),
          const Locale('de', ''),
        ],
        theme: theme,
        home: AnytimeHomePage(title: 'Anytime Podcast Player'),
      ),
    );
  }
}

class AnytimeHomePage extends StatefulWidget {
  final String title;

  AnytimeHomePage({this.title});

  @override
  _AnytimeHomePageState createState() => _AnytimeHomePageState();
}

class _AnytimeHomePageState extends State<AnytimeHomePage> with WidgetsBindingObserver {
  final log = Logger('_AnytimeHomePageState');
  Widget library;

  @override
  void initState() {
    super.initState();

    final audioBloc = Provider.of<AudioBloc>(context, listen: false);

    Chrome.transparentLight();

    WidgetsBinding.instance.addObserver(this);

    audioBloc.transitionLifecycleState(LifecyleState.resume);
  }

  @override
  void dispose() {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    audioBloc.transitionLifecycleState(LifecyleState.pause);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    switch (state) {
      case AppLifecycleState.resumed:
        audioBloc.transitionLifecycleState(LifecyleState.resume);
        break;
      case AppLifecycleState.paused:
        audioBloc.transitionLifecycleState(LifecyleState.pause);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pager = Provider.of<PagerBloc>(context);
    final searchBloc = Provider.of<EpisodeBloc>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  title: TitleWidget(),
                  brightness: Brightness.light,
                  backgroundColor: Colors.white,
                  floating: false,
                  pinned: true,
                  snap: false,
                  actions: <Widget>[
                    IconButton(
                      tooltip: L.of(context).search_button_label,
                      icon: Icon(Icons.search),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          SlideRightRoute(widget: Search()),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: _menuSelect,
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'settings',
                            child: Text('Settings'), //TODO: FIX
                          ),
                          PopupMenuItem<String>(
                            value: 'about',
                            child: Text(L.of(context).about_label),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                StreamBuilder<int>(
                    stream: pager.currentPage,
                    builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                      return _fragment(snapshot.data, searchBloc);
                    }),
              ],
            ),
          ),
          MiniPlayer(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
          stream: pager.currentPage,
          initialData: 0,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              currentIndex: snapshot.data,
              onTap: pager.changePage,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  label: L.of(context).library,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: L.of(context).discover,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.file_download),
                  label: L.of(context).downloads,
                ),
              ],
            );
          }),
    );
  }

  Widget _fragment(int index, EpisodeBloc searchBloc) {
    if (index == 0) {
      return Library();
    } else if (index == 1) {
      return Discovery();
    } else {
      return Downloads();
    }
  }

  void _menuSelect(String choice) async {
    final packageInfo = await PackageInfo.fromPlatform();

    switch (choice) {
      case 'about':
        showAboutDialog(
            context: context,
            applicationName: 'Anytime Podcast Player',
            applicationVersion: 'v${packageInfo.version} Alpha build ${packageInfo.buildNumber}',
            applicationIcon: Image.asset(
              'assets/images/anytime-logo-s.png',
              width: 52.0,
              height: 52.0,
            ),
            children: <Widget>[
              Text('\u00a9 2020 Ben Hills'),
              GestureDetector(
                  child:
                      Text('anytime@amugofjava.me.uk', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                  onTap: () {
                    _launchEmail();
                  }),
            ]);
        break;
      case 'settings':
        var s = await MobileSettingsService.instance();

        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (context) => Settings(
                    settingsService: s,
                  )),
        );
        break;
    }
  }

  void _launchEmail() async {
    const url = 'mailto:anytime@amugofjava.me.uk';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class TitleWidget extends StatelessWidget {
  final TextStyle _titleTheme1 = theme.textTheme.bodyText2
      .copyWith(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'MontserratRegular', fontSize: 18);

  final TextStyle _titleTheme2 = theme.textTheme.bodyText2
      .copyWith(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'MontserratRegular', fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        children: <Widget>[
          Text(
            'Anytime ',
            style: _titleTheme1,
          ),
          Text(
            'Player',
            style: _titleTheme2,
          ),
        ],
      ),
    );
  }
}
