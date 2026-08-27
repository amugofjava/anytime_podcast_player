# Anytime Podcast Player

A Flutter-based mobile podcast player that supports OPML import, audio streaming, background playback, and offline downloads.

## Language

**Podcast**:
A syndicated audio show subscription defined by an RSS feed, containing metadata and a sequence of episodes.
_Avoid_: Show, channel, series, album

**Episode**:
A single playable audio release belonging to a Podcast.
_Avoid_: Track, song, audio, item

**Download Root Directory**:
The base filesystem location selected by the user to store offline episode files.
_Avoid_: Save folder, storage path, download path

**Podcast Directory**:
A subdirectory directly under the Download Root Directory, titled after the Podcast's title, grouping all downloaded episodes of that podcast together.
_Avoid_: Artist folder, series folder, category directory

**Episode Audio File**:
The offline audio file (typically MP3) representing an Episode, saved within its respective Podcast Directory.
_Avoid_: Downloaded track, sound file, media file

**Audio Transcoding**:
The process of re-encoding a non-MP3 downloaded Episode Audio File (such as M4A or AAC) into the standard MP3 format using the native FFmpeg engine.
_Avoid_: Audio conversion, re-encoding, format change

**Transcoding State (`converting`)**:
A distinct operational download state representing that an Episode's raw file has finished downloading and is actively being transcoded into MP3 by FFmpeg.
_Avoid_: Finishing, finalizing, converting state

**Auto-Download Subscription**:
A user-configured selection allowing specific subscribed Podcasts to automatically download newly released episodes into their respective Podcast Directory upon app startup or background feed refresh.
_Avoid_: Auto fetch, auto sync, auto pull

**Audio Metadata Tags (ID3)**:
Embedded title, artist, album, and date tags inside the Episode Audio File, ensuring external media players display the human-readable episode title and podcast name rather than raw CDN or hash filenames.
_Avoid_: File info, mp3 properties, track info

**Active Downloads Queue**:
The live queue showing all currently active episode download and transcoding operations (`queued`, `downloading`, `converting`, `paused`, `failed`).
_Avoid_: Download manager, tasks list, in-progress files

**Downloaded Library**:
The persistent collection of completely downloaded and ready-to-play episodes stored on the device.
_Avoid_: Downloaded files, offline tracks, completed folder

**Download Task Controls**:
Interactive actions on individual downloading or converting items, specifically Pause, Resume, Retry, and Cancel.
_Avoid_: Task buttons, download commands, operation toggles

**Multi-Select Batch Mode**:
A temporary selection state entered via long-press in the Downloaded Library, allowing users to select multiple episodes for batch deletion, batch queueing, or batch played status toggling.
_Avoid_: Mass edit, multi edit, bulk manager
