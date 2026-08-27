# 0003 - Active Downloads Queue Management, Task Controls, and Multi-Select Batch Operations

## Context
Previously, the Anytime Podcast Player's "Downloads" screen only listed already downloaded episodes. Users had no visual overview of currently active downloads (`downloading`), transcoding tasks (`converting`), pending items (`queued`), paused tasks (`paused`), or failed tasks (`failed`). Users could not interactively pause, resume, retry, or cancel ongoing or stalled tasks. Additionally, managing downloaded files required deleting them one by one, with no multi-select mechanism for batch deletion, queueing, or marking as played.

## Decision
1. **Dual-Tab Downloads Screen**: Refactor `Downloads` (`lib/ui/library/downloads.dart`) to use a `DefaultTabController` presenting two views:
   - **`Downloaded Library` (已下载)**: The list of completed offline episodes.
   - **`Active Downloads Queue` (下载中)**: The real-time queue of active and interrupted download/transcode operations, accompanied by a dynamic numeric badge when active tasks exist.
2. **Active Downloads Stream**:
   - In `Repository` and `SembastRepository`, implement `findActiveDownloads()` which queries all episodes with `downloadState` in `[queued, downloading, converting, paused, failed]`.
   - In `DownloadService` and `MobileDownloadService`, listen to task state transitions and FFmpeg transcoding progress, emitting an updated stream of active episodes.
   - In `EpisodeBloc`, expose `Stream<List<Episode>> activeDownloads` and input sink `fetchActiveDownloads()`.
3. **Interactive Task Controls**:
   - Expose explicit operational methods in `DownloadService` and `EpisodeBloc`:
     - `pauseDownload(Episode)`: Pauses active download via `FlutterDownloader.pause` and persists `paused` state.
     - `resumeDownload(Episode)`: Resumes paused download via `FlutterDownloader.resume` or reenqueues.
     - `retryDownload(Episode)`: Intelligently retries failed operations (if raw audio exists, resumes transcoding; otherwise re-downloads from original URL).
     - `cancelDownload(Episode)`: Stops network download or kills FFmpeg worker process, removes temporary files, and resets episode download state to `none`.
4. **Multi-Select Batch Mode in Downloaded Library**:
   - Long-pressing any downloaded episode tile activates `Multi-Select Batch Mode`.
   - The top AppBar transitions into contextual selection actions displaying selected count, "Select All", and "Cancel".
   - A contextual action bar offers:
     - **Batch Delete**: Prompts a confirmation dialog, safely pauses playback if the currently playing episode is included, deletes local audio files, and resets database state.
     - **Batch Add to Queue**: Appends selected episodes to the playback queue sequentially.
     - **Batch Toggle Played**: Toggles the played/unplayed status for all selected episodes.
