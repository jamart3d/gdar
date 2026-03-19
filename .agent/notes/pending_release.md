# Pending Release Notes

### Changed
- **Screensaver (TV)**: Enhanced auto-spacing for track information to better account for long titles. Increased horizontal compression depth and implemented "Squish-to-fit" logic to prevent text from bleeding off-screen in both Ring and Flat modes.
- **TV Settings**: Fixed missing `const` constructor for the settings screen component.
- **Playback UI**: Initial work on overflow-safe header layout in PlaybackPanel for constrained heights.
- **TV Bootstrap + Tests**: Corrected TV startup assumptions so the TV app boots through `SplashScreen` with no TV onboarding flow, and migrated the durable TV startup coverage to `apps/gdar_tv/test/tv_startup_regression_test.dart`.
- **Monorepo Docs**: Added `docs/TEST_PLANNING.md`, updated `docs/MONOREPO_RULES.md`, and added fresh scorecards for 2026-03-18.
- **Release Isolation**: A release-candidate staging set now exists in the git index for the intended ship files.

### Verification Status
- `dart run melos run format`: runs and rewrites files as expected; staged test files needed restaging after formatting.
- `dart run melos run analyze`: passes cleanly across the workspace.
- `dart run melos run test`: passes cleanly across the workspace (`00:17 +180: All tests passed!`).

### Current Gate Status
- Test gate is green.
- Remaining release work is now:
  - finalize changelog entries
  - decide and apply the app version bump
  - build/deploy with the intended staged release set
  - restage renamed test files if the release candidate should include them

### Recent Fixes Already Landed
- `apps/gdar_mobile/test/widget_test.dart` now passes in the full workspace run.
- `packages/shakedown_core/test/widgets/shakedown_title_test.dart` was converted away from fragile mockito behavior to a fake settings provider.
- package-level TV tests now use relative helper imports so `flutter analyze` resolves them correctly.
- skipped TV repro files now attach `@Skip` to a library directive to satisfy the analyzer.
- `apps/gdar_tv/test/tv_startup_regression_test.dart` replaces the narrower onboarding-only TV startup test and now asserts the durable splash/no-onboarding contract.
- `packages/shakedown_core/test/widgets/show_list_item_details_test.dart` was rewritten as a smaller rendering-focused test.
- playback, screensaver, TV focus, and shared fake-provider tests were updated to match the current `SettingsProvider`, `AudioProvider`, and theme contracts.

### Release Candidate List

#### Release
- `CHANGELOG.md`
- `apps/gdar_mobile/lib/main.dart`
- `apps/gdar_mobile/test/widget_test.dart`
- `apps/gdar_tv/lib/main.dart`
- `apps/gdar_tv/test/tv_startup_regression_test.dart`
- `apps/gdar_tv/test/tv_dice_repro_test.dart`
- `apps/gdar_tv/test/tv_focus_recycling_repro_test.dart`
- `apps/gdar_tv/test/tv_focus_wrapper_repro_test.dart`
- `apps/gdar_tv/test/tv_regression_test.dart`
- `apps/gdar_web/lib/main.dart`
- `docs/MONOREPO_RULES.md`
- `docs/TEST_PLANNING.md`
- `docs/monorepo_scorecard_2026-03-18.md`
- `docs/monorepo_scorecard_summary_2026-03-18.md`
- `packages/shakedown_core/lib/audio/web_audio_engine.dart`
- `packages/shakedown_core/lib/providers/settings_provider.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_banner.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_config.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_visualizer.dart`
- `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
- `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- `packages/shakedown_core/lib/ui/screens/tv_settings_screen.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/playback_panel.dart`
- `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section.dart`
- `packages/shakedown_core/test/helpers/fake_settings_provider.dart`
- `packages/shakedown_core/test/ui/widgets/tv/tv_dual_pane_layout_random_test.dart`
- `packages/shakedown_core/test/ui/widgets/tv/tv_focus_wrapper_test.dart`
- `packages/shakedown_core/test/widgets/playback_panel_overflow_test.dart`
- `pubspec.yaml`

#### Still Unstaged / Not In Ship Candidate Yet
- most `.agent/*` churn
- `README.md`
- `docs/web_ui_audio_engines.md`
- `apps/gdar_web/test/*` extras
- remaining shared UI/settings/web files outside the staged candidate
- temp/log/script artifacts

### Resume Here
1. Finalize the `Unreleased` changelog entry for the actual ship set.
2. Decide and apply the next app version/build number from `1.2.4+204`.
3. Restage the intended release-candidate files, especially the TV test rename (`onboarding_tv_skip_test.dart` -> `tv_startup_regression_test.dart`) if that belongs in the ship set.
4. Run release builds/deploy steps.
