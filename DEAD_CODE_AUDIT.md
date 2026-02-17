# Dead Code Audit Report - Shakedown

This report documents dead code, orphaned assets, and legacy references identified during the screensaver simplification and general cleanup.

## 1. Diagnostic & Temporary Files [ACTION: DELETE]

The following files in the project root are temporary outputs from analysis or testing and are no longer needed:

- `analysis_output.txt`
- `analysis_output_utf8.txt`
- `final_analysis.txt`
- `final_analysis_utf8.txt`
- `flutter_01.log`, `flutter_02.log`, `flutter_03.log`
- `test_debug.log`
- `test_output.txt`

## 2. Legacy Code References (Naming & Comments) [ACTION: CLEANUP]

Several comments and property names still refer to the legacy "Oil Slide" screensaver. While the logic now powers the "Steal Your Face" visualizer, the naming should be clarified or removed.

| File | Context | Recommendation |
|------|---------|----------------|
| `pubspec.yaml` | `# For oil_slide visualizer game loop` | Update to "For screensaver visualizer" |
| `lib/visualizer/audio_reactor.dart` | `/// oil_slide visualizer for reactive animations.` | Update to "Screensaver visualizer" |
| `lib/ui/widgets/settings/playback_section.dart` | `// Screensaver (oil_slide) - Show on TV ONLY` | Update to "Screensaver (Steal)" |
| `lib/providers/settings_provider.dart` | Various comments referring to `oil_slide` | Update to `screensaver` or `visualizer` |
| `VisualizerPlugin.kt` | `* Android Visualizer API plugin for oil_slide screensaver.` | Update to "screensaver visualizer" |

## 3. Orphaned Assets

A sweep of the `assets/` and `shaders/` directories confirms that all "Oil Slide" specific assets have already been removed:

- [x] `lib/oil_slide/` (Deleted)
- [x] `shaders/oil_slide.frag` (Deleted)
- [x] `assets/images/` (Verified: Only app icons and Steal logos remain)

## 4. Setting Property Naming [NOTE]

Properties in `SettingsProvider` and `FakeSettingsProvider` still use `oil` prefixes (e.g., `useOilScreensaver`, `oilFlowSpeed`). 
- **Status**: Functional but legacy naming. 
- **Recommendation**: Plan a migration to generic `screensaver` prefix in a future refactor to avoid breaking existing user preferences.

---
*Audit performed on 2026-02-17*
