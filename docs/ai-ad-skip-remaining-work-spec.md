# AI Transcript / Ad Skip Remaining Work Spec

## Purpose

This spec captures the remaining gaps after the current implementation pass for:

- local AI transcription
- transcript-driven ad analysis
- prompt/auto ad skip

Use this as the handoff document for the next LLM. Do not rebuild the feature from scratch. Continue from the existing implementation and close the remaining validation, hardening, and platform gaps.

## Current Implemented State

The following is already present in the codebase:

- Transcript provenance is persisted and legacy-safe.
- Episode analysis metadata and ad segments are persisted on `Episode`.
- Secure secret storage exists and is wired into the app via `SecureSecretsService`.
- Local transcription is implemented with a Whisper-backed service using `whisper_ggml`.
- Episode-level UI exists for:
  - generating a local transcript
  - explicit transcript upload confirmation
  - analysis status display
- Direct OpenAI transcript analysis exists behind the existing `EpisodeAnalysisService` flow.
- AI settings UI exists for:
  - analysis provider selection
  - OpenAI API key storage
  - ad skip mode
- Playback ad-skip logic already exists and is gated to local AI transcripts plus detected ad segments.
- Focused unit tests and targeted `flutter analyze` are currently green.

## Files To Start From

- `lib/services/transcription/whisper_episode_transcription_service.dart`
- `lib/services/analysis/openai_episode_analysis_service.dart`
- `lib/ui/podcast/episode_details.dart`
- `lib/ui/settings/settings.dart`
- `lib/services/audio/default_audio_player_service.dart`
- `lib/bloc/podcast/episode_bloc.dart`

## Remaining Gaps

### 1. Real Runtime Validation Is Still Missing

The code compiles, analyzes, and passes focused unit tests, but the following have not been validated on actual devices:

- first-run Whisper model download
- end-to-end local transcription on a downloaded MP3/M4A episode
- transcript rendering in the existing transcript UI using a real generated transcript
- ad analysis against a real OpenAI API key
- playback prompt/skip behavior against real detected segments

#### Required work

- Run the app on at least one real Android device or emulator and one macOS desktop build if available.
- Verify:
  - local transcript generation succeeds
  - repeated transcript generation replaces the stored local transcript cleanly
  - ad analysis succeeds with a real OpenAI key
  - prompt mode shows exactly once per ad segment
  - auto mode skips correctly without loops
  - disabled mode leaves playback untouched

#### Acceptance criteria

- A human-tested checklist is recorded in the repo or PR notes.
- Any runtime-only defects found during the checklist are fixed.

### 2. iOS Build / Deployment Risk Is Unresolved

`whisper_ggml` may require a higher iOS deployment target than the project currently declares. This has not been validated.

#### Required work

- Attempt an iOS build or `pod install` path and confirm whether the current dependency set is buildable.
- If iOS fails due to deployment target:
  - either raise the minimum supported iOS version intentionally and document it
  - or replace the transcription dependency with one that satisfies the project’s intended iOS floor

#### Acceptance criteria

- iOS support status is explicit:
  - supported and buildable
  - or intentionally unsupported/documented for this feature

### 3. OpenAI Analysis Needs Production-Facing Hardening

The OpenAI provider currently works as an in-app job runner using the existing submit/poll contract, but it still needs operational hardening.

#### Required work

- Validate the chosen model with a real API key and real transcript sizes.
- Decide whether to keep the current Chat Completions + JSON schema approach or switch to the current recommended OpenAI API path if runtime validation reveals issues.
- Harden error handling for:
  - `401`
  - `429`
  - network timeouts
  - malformed model output
  - oversized transcript windows
- Confirm chunking/window sizing on long transcripts and adjust if the current window size is too large or too small in practice.

#### Acceptance criteria

- Real OpenAI analysis succeeds on:
  - one short episode transcript
  - one long episode transcript
- Common API failures surface readable user-facing errors.
- Invalid provider output cannot corrupt persisted ad segment data.

### 4. Integration / Widget Coverage Is Still Thin

Current coverage is mostly unit-level. The feature still needs higher-level tests.

#### Required work

- Add widget or integration coverage for:
  - transcript generation confirmation flow
  - upload confirmation flow
  - AI settings interactions
  - ad skip prompt UI behavior
- Add additional tests for:
  - transcript window chunking with long inputs
  - OpenAI provider error mapping
  - repeat transcript replacement preserving episode linkage
  - edge cases around short ad segments and boundary transitions

#### Acceptance criteria

- There is at least one higher-level automated test path for each of:
  - transcription
  - analysis
  - prompted skip

### 5. Final Product Decisions Still Need To Be Locked

There are still release-level decisions that should be made explicit.

#### Required work

- Decide whether `analysisBackend` remains a supported provider or should be treated as legacy/private-only.
- Decide whether the OpenAI model stays hard-coded or becomes configurable.
- Decide whether the current consent copy is final or needs legal/privacy review adjustments.
- Decide whether ad skip mode should remain under AI settings or move elsewhere in Settings.

#### Acceptance criteria

- These decisions are reflected in code comments, docs, or release notes.

## Non-Goals For The Next LLM

Do not add these unless explicitly requested:

- background transcription
- streaming-episode transcription
- multiple new LLM providers
- transcript switching UI
- manual ad segment editing
- analytics/telemetry

## Recommended Execution Order

1. Validate Android/macOS runtime behavior end to end.
2. Resolve iOS build viability.
3. Validate OpenAI analysis with a real key and long transcripts.
4. Add higher-level test coverage around the confirmed runtime flows.
5. Document product decisions and any intentional platform limitations.

## Suggested Verification Commands

Use these as the baseline before and after changes:

```bash
flutter test test/unit/services/transcription/whisper_episode_transcription_service_test.dart \
  test/unit/services/analysis/episode_analysis_service_test.dart \
  test/unit/services/analysis/openai_episode_analysis_service_test.dart \
  test/unit/services/audio/default_audio_player_service_autoskip_test.dart \
  test/unit/services/settings_test.dart \
  test/unit/bloc/episode_bloc_test.dart
```

```bash
flutter analyze \
  lib/ui/anytime_podcast_app.dart \
  lib/ui/settings/settings.dart \
  lib/ui/podcast/episode_details.dart \
  lib/services/transcription/whisper_episode_transcription_service.dart \
  lib/services/analysis/openai_episode_analysis_service.dart \
  lib/bloc/podcast/episode_bloc.dart
```

## Handoff Note

The biggest remaining uncertainty is no longer architecture. It is runtime validation and release hardening. The next LLM should treat this as a stabilization pass on an already-implemented feature set, not a greenfield design exercise.
