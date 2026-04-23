---
title: Two-Pronged Ad Analysis Architecture (Background Whisper+Gemma 4 and On-Demand Gemini)
version: 1.0
date_created: 2026-04-21
last_updated: 2026-04-21
owner: John Fewell
tags: [architecture, ai, android, feature]
---

# Introduction

This specification defines a two-pronged ad-segment analysis architecture for the Anytime Podcast Player. Ad analysis today is a single-provider, mutually-exclusive choice (OpenAI, Grok, Gemini, or a private backend). This spec replaces that model with two independent, co-existing analysis paths:

1. A **background path** — on-device Whisper transcription followed by on-device Gemma 4 ad-segment detection, scheduled to run overnight via Android `WorkManager`.
2. An **on-demand path** — the existing Gemini audio-direct analyzer, available as a one-tap action for immediate results.

The feature is explicitly scoped to **Android**. iOS background scheduling is out of scope for this revision.

## 1. Purpose & Scope

**Purpose.** Deliver accurate, privacy-preserving, and free ad-segment detection for downloaded episodes, while retaining a fast paid-LLM path for users who want immediate results.

**Scope.**
- In scope: Android background scheduling, Whisper transcription, Gemma 4 ad detection via `flutter_gemma`, persistence schema supporting multiple analyses per episode, settings UX rework, on-demand Gemini path (unchanged behavior, relocated in settings), supersession rules.
- Out of scope: iOS background scheduling, desktop/web analysis paths, changes to the existing OpenAI/Grok transcript-upload paths (they remain as configurable providers but are demoted from defaults), local LLM for the on-demand path, bundled model shipping.

**Audience.** Engineering agents and contributors implementing the feature, reviewers assessing acceptance, and QA validating behavior.

**Assumptions.**
- Target devices are Android 8.0 (API 26) or newer with ≥ 6 GB RAM; lower-spec devices may be excluded at runtime.
- Episodes subject to background analysis have already been downloaded by the existing download pipeline.
- The app has network access for the one-time model downloads but does not require network for per-episode analysis once models are present.
- The Whisper pipeline already exists in `lib/services/transcription/whisper_episode_transcription_service.dart`. The Gemini audio-direct pipeline already exists in `lib/services/analysis/gemini_episode_analysis_service.dart`.

## 2. Definitions

| Term | Definition |
| --- | --- |
| **Ad segment** | A contiguous time range within an episode identified as advertising content, described by `startMs`, `endMs`, optional `reason`, optional `confidence`, and optional `flags` (see `lib/entities/ad_segment.dart`). |
| **Background path** | The sequence: downloaded episode → Whisper transcription → Gemma 4 ad detection → persisted analysis. Runs unattended via `WorkManager`. |
| **On-demand path** | A user-triggered, single-request Gemini audio-direct analysis, producing ad segments immediately without a transcription step. |
| **Analysis record** | A persisted result of one ad-analysis run for one episode, tagged with a provider identifier and completion timestamp. |
| **Active analysis** | The analysis record currently used by the player for ad-skip behavior. |
| **Supersession** | The rule by which a newer or higher-quality analysis replaces the active analysis while the previous record is retained. |
| **Gemma 4** | On-device LLM supported by `flutter_gemma`. Two size variants used here: **E2B** (~2.4 GB) and **E4B** (~4.3 GB). Both support function-calling and thinking mode. |
| **`flutter_gemma`** | Flutter plugin `DenisovAV/flutter_gemma` providing on-device inference via MediaPipe / LiteRT-LM. |
| **Function calling** | `flutter_gemma` capability that forces model output to conform to a declared JSON schema. Used here to enforce the ad-segment JSON shape. |
| **`WorkManager`** | AndroidX library (`androidx.work:work-runtime`) for deferrable, constraint-aware background work. |
| **Charging-and-idle constraints** | `WorkManager` constraints `setRequiresCharging(true)`, `setRequiresDeviceIdle(true)`, `setRequiresBatteryNotLow(true)`. |
| **Stage** | A single resumable step in the background pipeline (`transcribe` or `analyze`). |
| **Provider identifier** | A stable string identifying which code path produced an analysis record. Values: `whisper+gemma4`, `gemini-audio`, `openai`, `grok`, `backend`. |

## 3. Requirements, Constraints & Guidelines

### Functional requirements

- **REQ-001**: The app SHALL provide a single global user setting, "Analyze downloaded episodes in background," which, when enabled, enrolls every newly downloaded episode into the background analysis queue.
- **REQ-002**: The app SHALL provide an "Analyze now" user action on each episode that is downloaded but has no active analysis. The action SHALL invoke the on-demand Gemini audio-direct path.
- **REQ-003**: The background path SHALL execute only when all of the following Android `WorkManager` constraints are satisfied: charging, device idle, battery-not-low.
- **REQ-004**: The background path SHALL be resumable at the stage boundary. If work is interrupted after Whisper transcription completes but before Gemma 4 analysis completes, the next run SHALL start at the Gemma 4 analysis stage using the persisted transcript.
- **REQ-005**: The background path SHALL process queued episodes serially (one at a time) to bound memory and battery usage.
- **REQ-006**: The default Gemma 4 variant SHALL be **E2B** (~2.4 GB). The user SHALL be able to select **E4B** (~4.3 GB) in settings.
- **REQ-007**: The first time background analysis is enabled, the app SHALL show a one-time confirmation surfacing the total estimated disk cost of the Whisper model plus the selected Gemma 4 variant, and the cost SHALL NOT be incurred until the user confirms.
- **REQ-008**: Model downloads SHALL use the `flutter_gemma` Android foreground-service download mechanism for files larger than 500 MB.
- **REQ-009**: The Gemma 4 ad-detection call SHALL use `flutter_gemma` function calling to force the output to conform to the ad-segment JSON schema defined in §4.
- **REQ-010**: When the background path produces an analysis record for an episode that already has an active `gemini-audio` analysis record, the app SHALL silently mark the new `whisper+gemma4` record as active. It SHALL NOT delete the prior `gemini-audio` record.
- **REQ-011**: The app SHALL retain all prior analysis records for an episode indefinitely until the episode itself is deleted.
- **REQ-012**: The app SHALL expose a developer-only "Analysis history" view per episode that lists every retained analysis record and permits diffing between any two (intended for the user's accuracy evaluation).
- **REQ-013**: The on-demand Gemini audio-direct path SHALL remain functionally unchanged from the current implementation in `lib/services/analysis/gemini_episode_analysis_service.dart`, other than:
  - persisting its output into the new multi-record schema (§4) rather than overwriting `episode.adSegments`;
  - being reachable from the new settings surface (§4) rather than from the old single-provider dropdown.
- **REQ-014**: The settings UI SHALL be restructured so that "Background analysis" and "On-demand analysis" are independent sections, each with its own toggles, model selection, and API-key fields where applicable. The current single "Ad analysis provider" dropdown SHALL be removed.
- **REQ-015**: The "Transcription provider" setting SHALL remain and SHALL continue to control `TranscriptionProvider.localAi` vs `TranscriptionProvider.openAi` selection for any user-initiated transcript surfacing (transcript view, external LLM transcript upload). The background path SHALL always use `TranscriptionProvider.localAi` regardless of this setting.
- **REQ-016**: The background pipeline SHALL NOT start if the required model files (Whisper model and Gemma 4 variant) are missing. It SHALL, at most once per queued episode, attempt to download any missing model using the same charging/idle constraints.

### Non-functional requirements

- **NFR-001**: The background worker SHALL hold no wake lock outside the `WorkManager`-granted execution window.
- **NFR-002**: The Gemma 4 analysis call SHALL bound memory by processing transcripts in at most 30-minute audio-equivalent chunks and merging ad segments across chunk boundaries (see §4).
- **NFR-003**: The background worker SHALL log stage transitions and durations to the existing `logging` package at `Logger('BackgroundAnalysisWorker')`. It SHALL NOT log transcript text at levels below `FINE`.
- **NFR-004**: Combined disk use for all AI models SHALL NOT exceed 5 GB in the default (E2B) configuration.

### Security requirements

- **SEC-001**: User-supplied API keys (Gemini, OpenAI, Grok) SHALL continue to be stored exclusively via `SecureSecretsService`. This spec introduces no new secret-storage surface.
- **SEC-002**: Transcripts and analysis records SHALL be stored only in the existing app-private Sembast store. They SHALL NOT be written to shared storage, logs at default level, or external services.
- **SEC-003**: The background path SHALL NOT make network calls after model files are present, excluding the existing episode-download path for audio.

### Constraints

- **CON-001**: Android only. iOS is out of scope for this revision. iOS-specific code paths MUST remain functionally unchanged, and all new Android-only code SHALL compile cleanly on iOS (e.g., via stubs that raise an unsupported-platform error).
- **CON-002**: Minimum Android API: 26. Devices below this threshold SHALL see the background-analysis toggle disabled with an explanatory subtitle.
- **CON-003**: `flutter_gemma` requires `.litertlm` format for Gemma 4 on Android. Model download URLs and expected formats MUST be kept in a single constants file.
- **CON-004**: `WorkManager` unique-work name: `anytime.background_analysis`. Exactly one instance of the worker SHALL be enqueued at a time; subsequent enqueues SHALL use `ExistingWorkPolicy.KEEP`.
- **CON-005**: The `Episode` entity's existing `adSegments` field SHALL remain populated with the active analysis's segments for backward compatibility with the audio player service and UI. The new multi-record store is additive, not a replacement for this field.

### Guidelines

- **GUD-001**: Prefer adding new classes to `lib/services/analysis/background/` rather than extending the existing `GeminiEpisodeAnalysisService` or `BackendEpisodeAnalysisService`.
- **GUD-002**: The background worker SHOULD publish progress events over the existing `Logger` plus a lightweight `ValueNotifier` exposed by the analysis bloc, so the UI can show per-episode progress without tight coupling.
- **GUD-003**: When adding UI strings, SHOULD use the existing `L.of(context)!` localization surface and add English entries; other locales can lag.

### Patterns to follow

- **PAT-001**: Service interfaces live in `lib/services/**/*_service.dart`; concrete implementations live alongside them. The new `BackgroundAnalysisService` SHALL follow this convention.
- **PAT-002**: Persistence goes through the existing `Repository` abstraction in `lib/repository/`. Add new methods to `Repository` and implement them in `SembastRepository`.
- **PAT-003**: Wire new services via the existing `Provider` tree in `lib/ui/anytime_podcast_app.dart`.

## 4. Interfaces & Data Contracts

### 4.1 New enums and settings keys

```dart
// lib/entities/app_settings.dart — additions

enum BackgroundAnalysisLocalModel {
  gemma4E2B,  // default, ~2.4 GB
  gemma4E4B,  // ~4.3 GB
}

// Added fields on AppSettings:
final bool backgroundAnalysisEnabled;                 // default false
final BackgroundAnalysisLocalModel backgroundLocalModel; // default gemma4E2B
final bool onDemandAnalysisEnabled;                   // default true

// Retained fields:
//   transcriptionProvider      — unchanged semantics (transcript surfacing only)
//   adSkipMode                 — unchanged
// Deprecated (kept for migration, no longer settable in UI):
//   transcriptUploadProvider   — maps to legacy path selection
```

### 4.2 New `Episode` analysis history schema

The current single-analysis fields on `Episode` (`adSegments`, `analysisStatus`, `analysisJobId`) SHALL be retained and continue to reflect the **active** analysis. A new parallel collection records the full history.

```dart
// lib/entities/episode_analysis_record.dart (new file)

class EpisodeAnalysisRecord {
  /// Stable identifier for the analysis provider that produced this record.
  /// One of: 'whisper+gemma4', 'gemini-audio', 'openai', 'grok', 'backend'.
  final String provider;

  /// Model variant or identifier the provider used (e.g., 'gemma-4-e2b',
  /// 'gemini-3.1-flash-lite-preview'). Free-form but stable per provider.
  final String modelId;

  /// Epoch milliseconds when the record was completed.
  final int completedAtMs;

  /// The ad segments produced by this analysis.
  final List<AdSegment> adSegments;

  /// True iff this record is the active analysis for the episode.
  final bool active;

  /// Optional free-form status notes, e.g. 'partial', 'degraded', 'ok'.
  final String? status;
}
```

`Episode` gains one new field:

```dart
List<EpisodeAnalysisRecord> analysisHistory; // default: []
```

Invariants:
- At most one record in `analysisHistory` has `active == true`.
- If any record has `active == true`, `Episode.adSegments` is equal to that record's `adSegments`.
- If no record has `active == true`, `Episode.adSegments` is empty.
- Record order is insertion order. No record is ever deleted except during episode deletion.

### 4.3 Supersession precedence

When a newly completed record is persisted, the following precedence determines whether it becomes active:

| Existing active provider | New record provider | New record becomes active? |
| --- | --- | --- |
| *(none)* | any | yes |
| `gemini-audio` | `whisper+gemma4` | yes |
| `whisper+gemma4` | `gemini-audio` | **no** (keep existing active) |
| `whisper+gemma4` | `whisper+gemma4` | yes (reruns replace) |
| `gemini-audio` | `gemini-audio` | yes (reruns replace) |
| `openai` / `grok` / `backend` | any | yes (legacy is always replaceable) |

### 4.4 Background worker interface

```dart
// lib/services/analysis/background/background_analysis_service.dart (new)

abstract class BackgroundAnalysisService {
  /// Enqueue an episode for background analysis. Idempotent per episodeId.
  Future<void> enqueue(String episodeId);

  /// Remove an episode from the queue if present. No-op if not queued.
  Future<void> dequeue(String episodeId);

  /// Current queue snapshot, ordered by enqueue time.
  Future<List<String>> listQueued();

  /// Stream of per-episode progress updates.
  Stream<BackgroundAnalysisProgress> progress();
}

class BackgroundAnalysisProgress {
  final String episodeId;
  final BackgroundAnalysisStage stage;
  final double? fraction; // 0..1 when known
  final String? message;
}

enum BackgroundAnalysisStage {
  queued,
  downloadingModel,
  transcribing,
  analyzing,
  completed,
  failed,
}
```

### 4.5 Gemma 4 function-call schema

The ad-detection call MUST declare the following function schema and bind the response to it.

```json
{
  "name": "report_ad_segments",
  "description": "Report every advertising segment detected in the transcript.",
  "parameters": {
    "type": "object",
    "properties": {
      "segments": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "start_ms": { "type": "integer", "minimum": 0 },
            "end_ms":   { "type": "integer", "minimum": 0 },
            "reason":   { "type": "string" },
            "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
          },
          "required": ["start_ms", "end_ms"]
        }
      }
    },
    "required": ["segments"]
  }
}
```

### 4.6 Chunking and merging rules

- Each transcript chunk passed to Gemma 4 covers at most **30 minutes** of audio-equivalent.
- Chunk boundaries overlap by **30 seconds** on each side to avoid bisecting an ad read.
- After per-chunk results are returned, segments whose `[start_ms, end_ms]` ranges overlap or lie within **5 000 ms** of each other are merged (single union segment). Merged `confidence` is the maximum of inputs; merged `reason` is the longer input.
- Merged segments shorter than **10 000 ms** are discarded as false positives.

### 4.7 `WorkManager` configuration

```kotlin
// android/app/src/main/kotlin — conceptual

val request = PeriodicWorkRequestBuilder<BackgroundAnalysisWorker>(
    repeatInterval = 6, TimeUnit.HOURS
)
  .setConstraints(
    Constraints.Builder()
      .setRequiresCharging(true)
      .setRequiresDeviceIdle(true)
      .setRequiresBatteryNotLow(true)
      .build()
  )
  .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
  "anytime.background_analysis",
  ExistingPeriodicWorkPolicy.KEEP,
  request,
)
```

## 5. Acceptance Criteria

- **AC-001**: *Given* the user has not enabled background analysis, *When* an episode finishes downloading, *Then* it SHALL NOT be enqueued for background analysis and its `adSegments` SHALL remain empty.
- **AC-002**: *Given* background analysis is enabled, *When* an episode finishes downloading, *Then* the app SHALL call `BackgroundAnalysisService.enqueue(episodeId)` exactly once.
- **AC-003**: *Given* a queued episode and the device satisfies charging-and-idle constraints, *When* `WorkManager` runs the worker, *Then* Whisper transcription SHALL run to completion before Gemma 4 analysis begins.
- **AC-004**: *Given* the worker is killed mid-analysis (OS resource kill), *When* constraints are next satisfied, *Then* the worker SHALL resume the same episode at the `analyze` stage using the persisted transcript, without re-running Whisper.
- **AC-005**: *Given* an episode already has an active `gemini-audio` analysis record, *When* the background path completes for the same episode, *Then* a new `whisper+gemma4` record SHALL be persisted with `active = true`, the prior `gemini-audio` record SHALL have `active = false`, and both records SHALL remain in `Episode.analysisHistory`.
- **AC-006**: *Given* an episode already has an active `whisper+gemma4` record, *When* the user taps "Analyze now," *Then* a new `gemini-audio` record SHALL be persisted with `active = false`, the active record SHALL be unchanged, and the user SHALL be able to view both from the Analysis history surface.
- **AC-007**: *Given* the Gemma 4 E2B model file is absent and the user enables background analysis for the first time, *When* the user confirms the disk-cost dialog, *Then* the model file SHALL be downloaded using `flutter_gemma`'s foreground-service download path, and the download SHALL be cancellable from the notification.
- **AC-008**: *Given* the Gemma 4 model is present, *When* a transcript longer than 30 minutes audio-equivalent is analyzed, *Then* the model SHALL be invoked on overlapping 30-minute chunks and the returned segments SHALL be merged per §4.6.
- **AC-009**: *Given* Gemma 4 returns an output that does not conform to the function-call schema, *When* the worker attempts to persist the result, *Then* the attempt SHALL fail fast with `BackgroundAnalysisStage.failed`, no partial `adSegments` SHALL be written, and the episode SHALL remain queued for one retry.
- **AC-010**: *Given* the device is not charging, *When* the user triggers the worker manually via developer tools, *Then* `WorkManager` SHALL refuse to run the worker until the constraint is met (demonstrating constraint enforcement).
- **AC-011**: *Given* the user opens the redesigned Settings > AI section, *When* the page renders, *Then* the old "Ad analysis provider" dropdown SHALL be absent, a "Background analysis" section SHALL show the enable toggle and model selection, and an "On-demand analysis" section SHALL show the Gemini toggle and API-key field.
- **AC-012**: *Given* the user is on Android API < 26, *When* Settings > AI renders, *Then* the background-analysis toggle SHALL be disabled with the subtitle "Requires Android 8 or newer."
- **AC-013**: *Given* no API key is configured for Gemini, *When* the user taps "Analyze now," *Then* a dialog SHALL prompt the user to supply one rather than starting a failed request.
- **AC-014**: *Given* an episode is deleted, *When* deletion completes, *Then* all of its `analysisHistory` records SHALL be removed from the Sembast store.

## 6. Test Automation Strategy

- **Test levels**: Unit tests for services and pure logic; widget tests for settings UX; Android instrumented test for the `WorkManager` wiring.
- **Frameworks**: `flutter_test`, `mockito` / hand-written fakes (match existing style under `test/unit/mocks/`), `integration_test` for the AC-003/AC-004 resumption scenario. Android-native verification uses the JVM unit tests already present under `android/app/src/test` (if absent, add under `android/app/src/test/kotlin/…`).
- **Test data management**: Synthetic transcripts live in `test/fixtures/transcripts/`. Do not check in real Whisper or Gemma model binaries; mock the Whisper and Gemma services with fakes returning fixture data.
- **CI/CD integration**: Add test targets to the existing `flutter test` invocation in `.github/workflows/` (extend whatever workflow runs on PR; `test.yml` if present). Do not introduce new workflow files unless no suitable one exists.
- **Coverage requirements**: New Dart code in `lib/services/analysis/background/**` and the new persistence code in `lib/repository/**` SHALL have ≥ 80 % line coverage. Settings UI coverage is not gated.
- **Performance testing**: Record Whisper and Gemma 4 inference wall-clock per 10 minutes of input audio on a Pixel 7 reference device. Document in `docs/performance-ad-analysis.md`. No automated perf gate.

## 7. Rationale & Context

### Why two prongs and not one

The background path is accurate (Whisper + full-quality transcript-based LLM reasoning) and free once models are downloaded, but it is slow and only runs when the device is idle and charging. Without the on-demand path, users would experience long latency between downloading an episode and getting usable ad-skip data. The on-demand path keeps the fast-experience UX the existing Gemini service already provides.

### Why retain superseded analyses

The user wants to compare Gemini-audio accuracy against Whisper+Gemma-4 accuracy empirically after enough episodes have been analyzed by both paths. Silently deleting the Gemini record when Whisper lands would make this comparison impossible. Disk cost per retained record is tiny (tens of KB), so retention is effectively free.

### Why Gemma 4 and `flutter_gemma`

`flutter_gemma` supports Gemma 4 E2B and E4B with function-calling, which removes the parsing fragility seen with free-form JSON output from smaller LLMs. Gemma 4 has thinking mode, which we expect to improve ad-boundary reasoning. The plugin also ships Android foreground-service downloads for large models, solving the 9-minute background-download timeout on Android.

### Why global (not per-podcast) enrollment

The user explicitly selected a global opt-in in the design discussion (2026-04-21). Per-podcast enrollment is deferred until background-analysis behavior has proven itself in real use.

### Why charging-and-idle and not "always"

Whisper and Gemma 4 each consume significant CPU/GPU and battery. Running either during active use would degrade the playback experience. The charging-and-idle constraint matches the user's "overnight" mental model and is cheap to enforce on Android.

### Why Android-only

The user confirmed on 2026-04-21 that Android is the target. iOS background-execution policy would require a meaningfully different implementation (BGProcessingTask, stricter time budgets), and mixing the two in one change would delay Android shipping.

## 8. Dependencies & External Integrations

### External systems

- **EXT-001**: Hugging Face (`huggingface.co`) — source of Gemma 4 model files (`.litertlm` format). Integration: HTTPS model download via `flutter_gemma`. No runtime account required; optional user token for rate-limited paths.
- **EXT-002**: Google GenAI API (`generativelanguage.googleapis.com`) — used by the retained on-demand Gemini audio-direct path. Integration: HTTPS JSON + inline audio. Requires user-supplied API key.

### Third-party services

- **SVC-001**: Hugging Face model hosting — availability assumed best-effort; the worker SHALL retry a failed model download on the next charging-and-idle window rather than blocking.
- **SVC-002**: Google GenAI — the on-demand path inherits the current service's timeout (120 s) and retry policy. No change.

### Infrastructure dependencies

- **INF-001**: Android `WorkManager` — provides the scheduling guarantee. Requires the app to depend on `androidx.work:work-runtime`.
- **INF-002**: Android foreground-service permission — `flutter_gemma` declares this internally for downloads > 500 MB; verify at integration time that its manifest contribution is sufficient.

### Data dependencies

- **DAT-001**: Whisper model (`ggml-base.bin` or variant per existing `WhisperEpisodeTranscriptionService`) — ~150 MB. Download on first use. Storage location unchanged from today.
- **DAT-002**: Gemma 4 E2B (`.litertlm`) — ~2.4 GB. Downloaded to the `flutter_gemma`-managed cache directory.
- **DAT-003**: Gemma 4 E4B (`.litertlm`) — ~4.3 GB. Only downloaded if user selects it.

### Technology platform dependencies

- **PLT-001**: Flutter SDK — version floor is whatever the repo already targets. This spec introduces no new Flutter-version requirement.
- **PLT-002**: Android API 26+ at runtime for the background path. The app's existing `minSdkVersion` SHALL be honored; the feature gates itself at runtime.
- **PLT-003**: Dart package `flutter_gemma` — required. Pin version at integration time; keep `.litertlm` compatibility in mind.

### Compliance dependencies

- **COM-001**: None beyond existing app privacy posture. Transcripts never leave the device for the background path. The on-demand path continues to upload audio to Google only when the user explicitly triggers it.

## 9. Examples & Edge Cases

### 9.1 Example — happy-path background run

```text
1. User downloads "Episode 42" (30 min audio).
2. "Analyze downloaded episodes in background" is ON.
3. Download handler calls BackgroundAnalysisService.enqueue("ep42").
4. Overnight: device charges + goes idle. WorkManager fires the worker.
5. Worker loads queue → picks "ep42".
6. Stage = transcribing. WhisperEpisodeTranscriptionService runs → transcript persisted.
7. Stage = analyzing. Transcript fed to Gemma 4 E2B via flutter_gemma function-call.
8. Three ad segments returned. Merged + filtered per §4.6 → two segments retained.
9. New EpisodeAnalysisRecord(provider='whisper+gemma4', active=true) written.
10. Episode.adSegments updated to match.
11. Worker moves to next queued episode or returns.
```

### 9.2 Example — supersession keeping prior record

```dart
// Before background path completes for episodeX:
episodeX.analysisHistory == [
  EpisodeAnalysisRecord(provider: 'gemini-audio', completedAtMs: 1_713_..., active: true, adSegments: [...]),
];

// After background path completes:
episodeX.analysisHistory == [
  EpisodeAnalysisRecord(provider: 'gemini-audio',   completedAtMs: 1_713_..., active: false, adSegments: [/* original */]),
  EpisodeAnalysisRecord(provider: 'whisper+gemma4', completedAtMs: 1_714_..., active: true,  adSegments: [/* new */]),
];
// episodeX.adSegments == the new whisper+gemma4 segments.
```

### 9.3 Edge case — chunk-boundary ad read

A 40-minute episode contains an ad read spanning 29:45–30:20 (straddling the first/second 30-minute chunk boundary).

```text
Chunk A: 00:00–30:00 (plus 30 s tail overlap → effectively 00:00–30:30)
Chunk B: 29:30–40:00 (plus 30 s head overlap)
Model returns segment 29:45–30:30 from chunk A and 29:45–30:20 from chunk B.
Merger sees overlapping ranges → single segment 29:45–30:30.
Filter: 45 s > 10 s minimum → retained.
```

### 9.4 Edge case — Gemma 4 produces malformed output

```text
Model returns function-call args that fail schema validation
  (e.g., end_ms < start_ms).
Worker logs the failure at FINE level (not the raw transcript).
No partial segments written.
Stage = failed; episode re-enqueued once (max one retry per day).
If retry also fails, episode remains in queue but is marked for manual review.
```

### 9.5 Edge case — user disables background analysis mid-run

```text
1. Worker is transcribing episodeY.
2. User toggles "Analyze downloaded episodes in background" OFF.
3. Toggle handler calls WorkManager.cancelUniqueWork("anytime.background_analysis").
4. Worker receives cancellation signal at next stage boundary.
5. Transcript-in-progress is discarded; no partial record is persisted.
6. Queue is preserved so re-enabling resumes where it left off.
```

### 9.6 Edge case — episode deleted while queued

```text
1. episodeZ is in the background queue.
2. User deletes the download.
3. Deletion hook calls BackgroundAnalysisService.dequeue("episodeZ").
4. Episode's analysisHistory records are removed with the episode row (DAT, §4.2).
```

## 10. Validation Criteria

- All acceptance criteria in §5 pass on a physical Pixel-class Android device running the minimum supported API level and the latest stable API level.
- `flutter analyze` and `flutter test` pass with zero new warnings introduced by this change.
- Settings UI widget tests cover AC-011 and AC-012 on both theme variants.
- The Sembast schema migration from `episode.adSegments`-only to `episode.adSegments + episode.analysisHistory` is backward-compatible: existing installs with prior `adSegments` data SHALL have that data migrated into a synthetic `EpisodeAnalysisRecord(provider=legacy-unknown, active=true)` on first launch.
- Manual verification: plug device in, turn off screen, wait for `WorkManager` to schedule; confirm a previously-downloaded episode is analyzed and its active provider becomes `whisper+gemma4`.
- Manual verification of AC-006: run Gemini "Analyze now," then run background Whisper+Gemma-4, confirm both records are present and diffable.

## 11. Related Specifications / Further Reading

- Existing source files this spec depends on or modifies:
  - `lib/entities/app_settings.dart`
  - `lib/entities/episode.dart`
  - `lib/entities/ad_segment.dart`
  - `lib/services/analysis/episode_analysis_service.dart`
  - `lib/services/analysis/gemini_episode_analysis_service.dart`
  - `lib/services/transcription/whisper_episode_transcription_service.dart`
  - `lib/repository/sembast/sembast_repository.dart`
  - `lib/ui/settings/settings.dart`
- External documentation:
  - `flutter_gemma` — https://github.com/DenisovAV/flutter_gemma
  - Gemma 4 E2B model card — https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
  - Android `WorkManager` constraints — https://developer.android.com/reference/androidx/work/Constraints
