## Anytime Podcast Player

This is the official repository for the Anytime Podcast Player - the simple Podcast playing app for Android & iOS, built with Dart & Flutter.
***

![screenshot1.png](docs/screenshot1b.png)&nbsp;
![screenshot2.png](docs/screenshot2b.png)&nbsp;
![screenshot3.png](docs/screenshot3b.png)&nbsp;
![screenshot3.png](docs/screenshot4b.png)&nbsp;

## Getting Started

Anytime is currently at v1.1 and is built against Flutter 2.8+. View the [project](https://github.com/amugofjava/anytime_podcast_player/projects/1) to
see what is currently being worked on.

#### Testers

If you would like to help test Anytime please click the image below to head over to the Play Store, or Amazon App Store.
You can download the current stable release or sign up to the Beta channel and help test
current developments.

<a href='https://play.google.com/store/apps/details?id=uk.me.amugofjava.anytime&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt="Get it on Google Play" height="61" src="docs/google-play-badge.png"/></a>&nbsp;
<a href="https://www.amazon.com/gp/product/B09C4J7NL5"><img src="docs/amazon-appstore-badge-english-black.png" height="61" alt="Anytime Play Store Link" target="_blank"></a>
<a href="https://apps.apple.com/us/app/anytime-podcast-player/id1582300839#?platform=iphone"><img src="docs/apple.png" height="61" style="padding-left: 8px;" alt="Anytime App Store Link" target="_blank"></a>


I would really appreciate all feedback - positive and negative - as it both helps improve Anytime and prioritise new features. You can reach me at [hello@anytimeplayer.app](mailto:hello@anytimeplayer.app).

#### Building from source

If you do not already have the Flutter SDK installed, follow the instructions from the
Flutter site [here](https://flutter.dev/docs/get-started/install).

Fetch the latest from master:

```
git clone https://github.com/amugofjava/anytime_podcast_player.git
```

From the anytime_podcast_player directory fetch the dependencies:

```
flutter packages get
```

Then either run:

```
flutter run
```

Or build:

```
flutter build apk
```

#### Search Engines

Anytime can search for podcasts via iTunes and PodcastIndex. To use PodcastIndex, first create
an account at [https://podcastindex.org](https://podcastindex.org). This will generate the required key
and secret. To enable searching with PodcastIndex in AnyTime, pass the key and secret as runtime arguments:

```
flutter run --dart-define=PINDEX_KEY=mykey --dart-define=PINDEX_SECRET=mysecret
```

If running from Android Studio, add the following to the command line arguments section:

```
-t lib/main.dart --dart-define=PINDEX_KEY=mykey --dart-define=PINDEX_SECRET=mysecret
```

Ensure there are is only a single space between each argument. I have found that an additional space between any
of the arguments will prevent them from being passed into Flutter correctly.

## Built With

Anytime makes use of several amazing packages available on [pub.dev](https://pub.dev). Below is a list of the packages that
are heavily used within the application.

* [Flutter](https://flutter.dev/) - SDK.
* [Sembast](https://pub.dev/packages/sembast) - NoSQL persistent store.
* [RxDart](https://pub.dev/packages/rxdart) - adds additional capabilities to Dart Streams and StreamControllers.
* [Audio Service](https://pub.dev/packages/audio_service) - Provides background support for supporting audio libraries.
* [Podcast Search](https://pub.dev/packages/podcast_search) - Provides podcast search and parsing.

## Architecture

![architecture.png](docs/architecture_small.png)

Anytime takes a layered approach:

* UI - The UI presented to the users. Currently this is mobile, but could be extended to web and/or desktop in the future.
* BLoC - Handles the state for the UI. Communication between the UI and BLoC is entirely via Sinks and Streams.
* Services - Interacts with the API and Repository to provide data handling routines to the BLoCs and other services.
* API - Interacts with the iTunes API (via a package) to fetch and parse podcast data.
* Repository - Provides persistent storage.

## Contributing

If you have an issue or discover a bug, please raise a GitHub issue. Pull requests are also welcome. Full details can be found in [CONTRIBUTING.md](CONTRIBUTING.md).

## Have a question?

If you wish to reach out to me directly you can find me at [hello@anytimeplayer.app](mailto:hello@anytimeplayer.app).

## License

Anytime is released under a BSD-Style License. See the LICENSE file for further details.