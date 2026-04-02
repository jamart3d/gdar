# TV Screensaver Preview Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `_ToggleRow` switch below the Audio Graph mode selector in TV screensaver settings that switches the preview panel between Logo focus (graph hidden) and Audio Graph focus (logo hidden, graph scaled to preview).

**Architecture:** New bool pref `oilPreviewShowGraph` in `SettingsProvider` bridges the toggle (in the settings right-pane) with `TvScreensaverPreviewPanel` (in the left-pane sidebar). The preview panel overrides two `StealConfig` fields — `logoScale` and `audioGraphMode` — based on the pref. No changes to the full-screen screensaver.

**Tech Stack:** Flutter/Dart, Provider (`ChangeNotifier`), SharedPreferences

---

## File Map

| File | Change |
|---|---|
| `packages/shakedown_core/lib/config/default_settings.dart` | Add `oilPreviewShowGraph = false` |
| `packages/shakedown_core/lib/providers/settings_provider_screensaver.dart` | Add key const, field, getter, toggle method |
| `packages/shakedown_core/lib/providers/settings_provider_initialization.dart` | Add `_oilPreviewShowGraph` load |
| `packages/shakedown_core/test/helpers/fake_settings_provider.dart` | Add `oilPreviewShowGraph` getter + `toggleOilPreviewShowGraph` |
| `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart` | Add `_ToggleRow` at end of `_buildAudioGraphSection` |
| `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart` | Override `logoScale`/`audioGraphMode` in `StealConfig` |
| `packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart` | Add toggle visibility tests |

---

## Task 1: Add default and pref infrastructure

**Files:**
- Modify: `packages/shakedown_core/lib/config/default_settings.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_screensaver.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

- [ ] **Step 1: Add default value to `DefaultSettings`**

In `packages/shakedown_core/lib/config/default_settings.dart`, after the `oilAudioGraphMode` constant (line ~145), add:

```dart
  /// Preview panel focus mode: false = show logo, true = show audio graph.
  static const bool oilPreviewShowGraph = false;
```

- [ ] **Step 2: Add key constant to `settings_provider_screensaver.dart`**

After line 76 (`const String _showScreensaverCountdownKey = 'show_screensaver_countdown';`):

```dart
const String _oilPreviewShowGraphKey = 'oil_preview_show_graph';
```

- [ ] **Step 3: Add field to the mixin in `settings_provider_screensaver.dart`**

In `mixin _SettingsProviderScreensaverFields`, after `late bool _oilLogoAntiAlias;` (line ~126), add:

```dart
  late bool _oilPreviewShowGraph;
```

- [ ] **Step 4: Add getter to `settings_provider_screensaver.dart`**

After `bool get oilLogoAntiAlias => _oilLogoAntiAlias;` (line ~209), add:

```dart
  bool get oilPreviewShowGraph => _oilPreviewShowGraph;
```

- [ ] **Step 5: Add toggle method to `settings_provider_screensaver.dart`**

After `toggleOilLogoAntiAlias()` (line ~285), add:

```dart
  Future<void> toggleOilPreviewShowGraph() => _updatePreference(
    _oilPreviewShowGraphKey,
    _oilPreviewShowGraph = !_oilPreviewShowGraph,
  );
```

- [ ] **Step 6: Add load in `settings_provider_initialization.dart`**

After the `_oilLogoAntiAlias` load block (lines 727-729):

```dart
    _oilPreviewShowGraph =
        _prefs.getBool(_oilPreviewShowGraphKey) ??
        DefaultSettings.oilPreviewShowGraph;
```

- [ ] **Step 7: Run analyze to confirm no errors**

```bash
cd C:/Users/jeff/StudioProjects/gdar && melos run analyze
```

Expected: no new errors.

- [ ] **Step 8: Commit**

```bash
git add packages/shakedown_core/lib/config/default_settings.dart \
        packages/shakedown_core/lib/providers/settings_provider_screensaver.dart \
        packages/shakedown_core/lib/providers/settings_provider_initialization.dart
git commit -m "feat: add oilPreviewShowGraph pref for screensaver preview toggle"
```

---

## Task 2: Update FakeSettingsProvider and write tests

**Files:**
- Modify: `packages/shakedown_core/test/helpers/fake_settings_provider.dart`
- Modify: `packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart`

- [ ] **Step 1: Add `oilPreviewShowGraph` to `FakeSettingsProvider`**

In `packages/shakedown_core/test/helpers/fake_settings_provider.dart`, after any existing bool getter (e.g. near `bool get oilWoodstockEveryHour => false;`), add:

```dart
  @override
  bool get oilPreviewShowGraph => false;
  @override
  Future<void> toggleOilPreviewShowGraph() async {}
```

- [ ] **Step 2: Write failing test — toggle hidden when graph mode is `'off'`**

In `packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart`, inside `main()`, add a new group after the existing `audio graph mode — control visibility` group:

```dart
group('TvScreensaverSection preview toggle visibility', () {
  testWidgets(
    'toggle is hidden when audio graph mode is off',
    (tester) async {
      await tester.pumpWidget(_buildSection('off'));
      expect(find.text('Preview: Audio Graph'), findsNothing);
    },
  );

  testWidgets(
    'toggle is visible when audio graph mode is corner',
    (tester) async {
      await tester.pumpWidget(_buildSection('corner'));
      expect(find.text('Preview: Audio Graph'), findsOneWidget);
    },
  );

  testWidgets(
    'toggle is visible when audio graph mode is circular',
    (tester) async {
      await tester.pumpWidget(_buildSection('circular'));
      expect(find.text('Preview: Audio Graph'), findsOneWidget);
    },
  );

  testWidgets(
    'toggle is visible when audio graph mode is ekg',
    (tester) async {
      await tester.pumpWidget(_buildSection('ekg'));
      expect(find.text('Preview: Audio Graph'), findsOneWidget);
    },
  );
});
```

- [ ] **Step 3: Run tests to verify they FAIL**

```bash
flutter test packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart -v
```

Expected: the new `preview toggle visibility` tests fail (widget not found / found unexpectedly).

- [ ] **Step 4: Implement the `_ToggleRow` in `_buildAudioGraphSection`**

In `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart`, inside `_buildAudioGraphSection`, after the closing `]` of the `if (settings.oilAudioGraphMode == 'circular' || ...)` block (i.e. just before the final `],` that closes the `Column`'s children list), add:

```dart
          if (settings.oilAudioGraphMode != 'off') ...[
            const SizedBox(height: 16),
            _ToggleRow(
              label: 'Preview: Audio Graph',
              subtitle:
                  'Show scaled audio graph in preview instead of logo',
              value: settings.oilPreviewShowGraph,
              onChanged: (_) => settings.toggleOilPreviewShowGraph(),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
```

- [ ] **Step 5: Run tests to verify they PASS**

```bash
flutter test packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart -v
```

Expected: all tests pass including the new `preview toggle visibility` group.

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/test/helpers/fake_settings_provider.dart \
        packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart \
        packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart
git commit -m "feat: add preview toggle UI below audio graph mode selector"
```

---

## Task 3: Wire preview panel to the pref

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart`

- [ ] **Step 1: Locate the `StealConfig` construction in `TvScreensaverPreviewPanel.build`**

Open `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart`.

The `StealConfig(...)` call starts at line ~102. It currently reads:

```dart
    final config = StealConfig(
      ...
      logoScale: settings.oilLogoScale,
      ...
      audioGraphMode: settings.oilAudioGraphMode,
      ...
    );
```

- [ ] **Step 2: Override `logoScale` and `audioGraphMode` based on `oilPreviewShowGraph`**

Replace the two relevant named arguments in the `StealConfig(...)` call:

```dart
      logoScale: settings.oilPreviewShowGraph ? 0.0 : settings.oilLogoScale,
```

```dart
      audioGraphMode: settings.oilPreviewShowGraph
          ? settings.oilAudioGraphMode
          : 'off',
```

All other `StealConfig` fields remain unchanged.

- [ ] **Step 3: Run analyze**

```bash
cd C:/Users/jeff/StudioProjects/gdar && melos run analyze
```

Expected: no errors.

- [ ] **Step 4: Run full test suite**

```bash
flutter test packages/shakedown_core/ --reporter=compact
```

Expected: all tests pass. (The `verify_data_integrity_test.dart` failure is a known pre-existing CI-only issue — ignore it if it appears.)

- [ ] **Step 5: Manual smoke test on device**

1. Open TV settings → Screensaver → enable Shakedown Screen Saver
2. Enable Audio Reactivity
3. Set Audio Graph to `Corner`
4. Verify preview panel shows the logo bouncing, no corner graph
5. Toggle `Preview: Audio Graph` ON
6. Verify preview panel shows the corner audio graph, logo hidden
7. Set Audio Graph to `Off`
8. Verify the `Preview: Audio Graph` toggle disappears
9. Toggle Audio Reactivity OFF → verify preview panel hides entirely (existing behavior)

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart
git commit -m "feat: wire preview panel to oilPreviewShowGraph — logo/graph toggle"
```

---

## Post-Implementation Note

If the audio graph does not scale correctly within the preview box (e.g. `corner` renders at a fixed pixel offset that looks right on a TV but oversized in the preview), add a `previewScaleFactor` field to `StealConfig` and pass it from the preview panel. That is a follow-up and **not part of this plan**.
