## 1.2.0

- Add queue support.
- Add grid layout view to podcast, discovery and search pages.
- Bug fixes.

## 1.1.0+62

- Re-work the speed selector control to make it easier to use and add additional audio effects (Android only).
- Fix Let's Encrypt CA certificate issue on Android versions 7 and below.
- Upgrade Gradle to 7.0.3.

## 0.5.0

- Upgrade dependencies for Flutter 2.
- Re-work the image routines to improve caching, reduce the number of cached images and improve performance.
- Add option to manually add RSS feed.
- Refreshing a podcast will now update existing podcast and episode details as appropriate.
- Change pull-to-refresh; now simpler, faster and the 'standard implementation'. Fixed issue with pull to refresh where it wasn't possible to 'pull' if the window did not need to scroll.
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

- Breaking change: New settings page. User can switch between using internal storage or SD card. If you have episodes already downloaded to an SD Card, you must go in to setting and switch on SD Card storage.
- iTunes season and epiosde tags will be used as part of the filename when available. This fixes an issue whereby the episode filename is always the same. By using season and/or episode the filename can be made unique.
