## 1.3.14

- Support for Russian language (thank you @yurtpage).
- Support for Vietnamese language (thank you @daoductrung).
- Support for Galicia language (thank you @xmgz).
- Improve RSS checking efficiency by checking modified-date in header where possible.
- Bug fixes.
- Accessibility fixes & improvements.

## 1.3.13

- Add support for Dutch language (thank you Raphael Gout).
- Fix layout issues with edge-to-edge on Android 15+.

## 1.3.12

- Add continuous play option.
- HTML within notes now selectable for copy/pasting.
- Add support for Spanish language (thank you Paco).
- Add support for VTT transcripts.
- Add support for podcast and episode sharing.

## 1.3.11

- Fix double read issue with some buttons when using VoiceOver.
- Add visual indicator to sleep timer control to show if it is currently running.
- Improve semantic labels for sleep timer and speed controls to read out current value.
- Added option to delete downloaded episode once played (@mrkrash).

## 1.3.10

- Episode search

## 1.3.9

- Improved accessibility
- Better support for AirPods and Bluetooth earphones/headphones
- Speed selector max speed now uses 0.1 increments
- Bug Fixes
- Fixed episode sort issue

## 1.3.8

- Added episode sort option.
- Added link to podcast website in episodes page.
- Added manual podcast refresh option in episodes page.
- Translated into Italian (thank you [@mrkrash](https://github.com/mrkrash)).
- Added TRANSLATION.md guide.
- Fixed iOS swipe to go back transition.
- Improved speed of 'mark all episodes played' option.
- Fixed accessibility issues with settings page and layout selector.

## 1.3.7

- Added episode filter.
- Improve transcript responsiveness & speaker matching.

## 1.3.0

- Add support for PC2.0 Transcripts (where available).
- Add support for PC2.0 Person tag.
- Add categories to Discovery tab.
- Update dependencies.
- Bug fixes & UI improvements.

## 1.2.3

- Migrate to Flutter v3.3.7.
- Default to dark theme.

## 1.2.2

- Improve Let's Encrypt fix for Android 7.1.1 and below.
- Podcast description is now fixed to a few lines. Longer descriptions are expandable.
- Update dependencies.
- Bug fixes.

## 1.2.1

- Improve position slider on iOS.
- Update dependencies.
- Bug fixes.

## 1.2.0

- Add queue support.
- Add grid layout view to podcast, discovery and search pages.
- Bug fixes.

## 1.1.0+62

- Re-work the speed selector control to make it easier to use and add additional audio effects (
  Android only).
- Fix Let's Encrypt CA certificate issue on Android versions 7 and below.
- Upgrade Gradle to 7.0.3.

## 0.5.0

- Upgrade dependencies for Flutter 2.
- Re-work the image routines to improve caching, reduce the number of cached images and improve
  performance.
- Add option to manually add RSS feed.
- Refreshing a podcast will now update existing podcast and episode details as appropriate.
- Change pull-to-refresh; now simpler, faster and the 'standard implementation'. Fixed issue with
  pull to refresh where it wasn't possible to 'pull' if the window did not need to scroll.
- Combined episode and chapter events into single event and improved chapter widget.
- Charts are now cached only for 30 mins rather than indefinitely.

## 0.4.2

- State bug fixes

## 0.4.1

- Dynamically size text on NowPlaying screen.

## 0.4.0

- Add support for searching via PodcastIndex (Beta).
- Add support for podcast funding tag.
- Add support for podcast chapters.

## 0.1.4

- Add playback speed control.
- Add show notes page.

## 0.1.3

- Add dark mode support.
- Improve animations.

## 0.1.2

- Improve accuracy of rewind and fast-forward.

## 0.1.1

- Breaking change: New settings page. User can switch between using internal storage or SD card. If
  you have episodes already downloaded to an SD Card, you must go in to setting and switch on SD
  Card storage.
- iTunes season and epiosde tags will be used as part of the filename when available. This fixes an
  issue whereby the episode filename is always the same. By using season and/or episode the filename
  can be made unique.
