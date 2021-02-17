## Anytime Podcast Player

This is the official repository for the Anytime Podcast Player - the simple Podcast playing app built with Dart & Flutter.
***
![screenshot1.png](docs/screenshot1.png)
![screenshot2.png](docs/screenshot2.png)
![screenshot3.png](docs/screenshot3.png)

## Getting Started

Anytime is currently in *Beta* - so please expect bugs! Only Android is supported at the moment,
but an iOS version is in the works.

#### Testers

Anytime is in public Beta. Please click the image below to head over to the Play Store.

<a href='https://play.google.com/store/apps/details?id=uk.me.amugofjava.anytime&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Get it on Google Play' width="40%" src='https://play.google.com/intl/en_gb/badges/static/images/badges/en_badge_web_generic.png'/></a>

I would really appreciate all feedback - positive and negative - as it both helps improve Anytime and prioritise new features.

#### Building from source

If you do not already have the Flutter SDK installed, follow the instructions from the
Flutter site [here](https://flutter.dev/docs/get-started/install).

To build from source fetch the latest from master:

```
git clone https://github.com/amugofjava/podcast_search.git
```

From the anytime directory fetch the dependencies:

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

Anytime can search for podcasts via iTunes and has Beta support for PodcastIndex. To use PodcastIndex, first create
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

If you wish to reach out to me directly you can find me at [anytime@amugofjava.me.uk](mailto:anytime@amugofjava.me.uk).

## License

Anytime is released under a BSD-Style License. See the LICENSE file for further details.