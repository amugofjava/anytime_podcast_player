# AI Ad Skip Release Hardening Notes

## Current Status

- Automated verification is available in this branch for transcript generation, OpenAI analysis, and prompted ad skip flows.
- Human runtime validation is still pending. The checklist below should be completed on real hardware or emulators before release.
- OpenAI analysis remains on the existing Chat Completions plus `json_schema` path for this stabilization pass. The implementation now fails closed on malformed structured output and maps common API failures to readable user-facing errors.

## iOS Support Status

- `whisper_ggml` 1.7.0 declares an iOS deployment target of `15.6` in its podspec.
- The app iOS deployment target has been raised to `15.6` to match the plugin requirement and remove the known CocoaPods deployment mismatch.
- `pod install` could not be executed in this environment because CocoaPods is not installed, so a local Xcode or CI build is still required to confirm the full iOS path end to end.

## Product Decisions For This Branch

- `analysisBackend` remains a private or legacy provider. It is still only surfaced when `EPISODE_ANALYSIS_BACKEND_BASE_URL` is configured.
- The OpenAI analysis model remains hard-coded in code for now. It is intentionally not user-configurable until runtime validation confirms the final model and sizing tradeoffs.
- Ad skip mode stays under `Settings > AI` in this release.
- The current transcript upload consent copy should be treated as requiring final privacy or legal review before a public release.

## Manual Validation Checklist

- [ ] Android or emulator: first-run Whisper model download succeeds.
- [ ] Android or emulator: local transcript generation succeeds on a downloaded MP3 episode.
- [ ] Android or emulator: local transcript generation succeeds on a downloaded M4A episode.
- [ ] Android or emulator: regenerating a transcript replaces the stored local transcript cleanly.
- [ ] Android or emulator: generated transcript renders correctly in the transcript UI.
- [ ] Android or emulator: OpenAI analysis succeeds with a real API key on a short transcript.
- [ ] Android or emulator: OpenAI analysis succeeds with a real API key on a long transcript.
- [ ] Android or emulator: prompt mode shows once per detected segment.
- [ ] Android or emulator: auto mode skips each segment without loops.
- [ ] Android or emulator: disabled mode leaves playback untouched.
- [ ] macOS desktop: local transcription and playback ad-skip flows work end to end.
- [ ] iOS build: `flutter build ios` or Xcode build succeeds with the raised `15.6` deployment target.

## Suggested Verification Commands

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
