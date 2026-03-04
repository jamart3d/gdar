# Android 15 Migration & PiP Plan

Addresses the **3 actions recommended** by Google Play Console for Release 100 (1.1.0).
Based on a full audit of `lib/main.dart`, `AndroidManifest.xml`, `MainActivity.kt`, and
`mapping.txt` (Flutter 3.41.1 stable, SDK 35, build-tools 36.1.0).

> **TV gate:** The `isTv` platform channel (`com.jamart3d.shakedown/device`) is already
> implemented in `MainActivity.kt`. No new native code is needed for the TV guard.

---

## Audit Summary

| File | Finding | Action |
|------|---------|--------|
| `lib/main.dart:628` | `systemNavigationBarColor: Colors.black` — True Black AMOLED mode | Replace with `Colors.transparent` + contrast enforcement |
| `MainActivity.kt` | No deprecated window APIs. Missing `WindowCompat` edge-to-edge call. | Add one line to `onCreate` |
| `AndroidManifest.xml` | Missing `android:supportsPictureInPicture="true"` | Add one attribute |
| `mapping.txt` | `I.d.s` / `X.h.j` → `PlatformChannel$SystemChromeStyle` (Flutter engine internal) | No action — Flutter engine issue, monitor for fix |

---

## Why the Deprecated API Warning Exists (Issue #2 — Explained)

Android 15 (SDK 35) enforces edge-to-edge by design. All three flagged APIs are now no-ops:

- `window.setNavigationBarColor` → ignored
- `window.setStatusBarColor` → ignored  
- `window.setNavigationBarDividerColor` → ignored

Play Console flagged obfuscated classes `I.d.s` and `X.h.j`. Decoding via `mapping.txt` traces
these to **Flutter's own `PlatformChannel$SystemChromeStyle`** — the internal class Flutter uses
to apply `SystemUiOverlayStyle`. This is a Flutter engine issue, not app code.

**You are on Flutter 3.41.1 (latest stable as of 2026-02-12).** The engine has not yet been
updated to use the Android 15 `WindowInsets` approach internally. Monitor
[flutter/flutter#issues](https://github.com/flutter/flutter/issues) — search
`SystemChromeStyle Android 15 deprecated navigation bar` and subscribe to the relevant issue.
Play Console Issue #2 will clear automatically on your next build after Flutter patches the engine.

**The correct Android 15 solution** (and what the plan below implements for your own code) is:
- Stop setting nav bar colors entirely
- Use `WindowCompat.setDecorFitsSystemWindows(window, false)` to opt into edge-to-edge
- Use `WindowInsets` / `MediaQuery.padding` in Flutter to pad content away from system bars
- Use `systemNavigationBarContrastEnforced: true` to let the OS handle nav bar legibility

---

## Phase 1: Edge-to-Edge (Addresses Issues #1 and #2 in your code)

### 1a. `MainActivity.kt` — Add Edge-to-Edge Opt-In

Add one import and one line to `onCreate`. Everything else in `MainActivity.kt` is unchanged:

```kotlin
// Add to imports
import androidx.core.view.WindowCompat

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Opt into edge-to-edge — required for Android 15 / SDK 35
    // Replaces the deprecated setNavigationBarColor / setStatusBarColor approach
    WindowCompat.setDecorFitsSystemWindows(window, false)
    handleDeepLink(intent)
}
```

### 1b. `lib/main.dart:624` — Fix True Black AMOLED Mode

The current block sets `systemNavigationBarColor: Colors.black` for True Black mode. On Android 15
this has no effect — the OS ignores it. The replacement uses `Colors.transparent` on all versions
and relies on `systemNavigationBarContrastEnforced: true` to keep nav bar icons legible.

**True Black AMOLED savings are preserved** — the app background and status bar are unaffected.
Only the nav bar itself can no longer be forced black on Android 15 (OS constraint, not fixable).

```dart
// AFTER
builder: (context, child) {
  final isTrueBlack = themeProvider.isDarkMode &&
      settingsProvider.useTrueBlack;
  final iconBrightness = themeProvider.isDarkMode
      ? Brightness.light
      : Brightness.dark;

  // Android 15 enforces transparent nav bars — setNavigationBarColor is ignored.
  // We use transparent + contrastEnforced on all versions for consistency.
  // True Black AMOLED mode still applies to the app background and status bar.
  child = AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true,
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarIconBrightness: isTrueBlack
          ? Brightness.light   // preserve explicit light icons for true black theme
          : iconBrightness,
    ),
    child: child!,
  );

  return InactivityDetector(
```

### 1c. Content Inset Guard

With edge-to-edge enabled, content extends behind the nav bar. Use `MediaQuery.padding` to
keep content above the gesture handle. Apply to your main player scaffold:

```dart
@override
Widget build(BuildContext context) {
  final padding = MediaQuery.of(context).padding;

  return Scaffold(
    extendBody: false,
    extendBodyBehindAppBar: false,
    body: Padding(
      // Prevents player controls from sliding under the gesture navigation handle
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: MyAudioPlayerContent(),
    ),
  );
}
```

---

## Phase 2: Picture-in-Picture (Addresses Issue #3)

Play Console reports **69.60% peer MAU adoption**. PiP is opt-in via a user settings toggle.
The existing `isTv` channel handles the TV gate — no new native code needed.

### 2a. `AndroidManifest.xml` — One Attribute Change

Your existing `configChanges` already covers all required PiP values. Only add
`android:supportsPictureInPicture="true"`:

```xml
<!-- AFTER — add supportsPictureInPicture only -->
<activity android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:alwaysRetainTaskState="true"
    android:theme="@style/LaunchTheme"
    android:supportsPictureInPicture="true"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
```

### 2b. Dependency

```yaml
# pubspec.yaml
dependencies:
  simple_pip_mode: ^1.1.0   # verify latest on pub.dev before adding
```

### 2c. PiP Trigger

Use the existing `com.jamart3d.shakedown/device` channel — no new platform code needed.

### 2d. PiP-Aware Widget

```dart
PipWidget(
  onPipLayout: (context) => MiniPlayerView(),   // Compact controls in PiP window
  onFullLayout: (context) => FullPlayerView(),  // Normal full-screen player
)
```

---

## Verification Checklist

| # | Test | Issue | Expected Outcome |
|---|------|-------|-----------------|
| 1 | Run on Android 15 emulator (API 35) | #1 | Content does not draw under gesture handle |
| 2 | Enable True Black → Android 15 | #1 | Nav bar transparent; app background still black |
| 3 | Enable True Black → Android 14 physical device | #1 | No regression in appearance |
| 4 | Toggle light/dark mode while app is open | #1 | Icon brightness updates immediately |
| 5 | Build release APK → check merged manifest | #3 | `supportsPictureInPicture="true"` present |
| 6 | Enable PiP toggle → minimize app | #3 | Mini-player appears in PiP window |
| 7 | Restore app from PiP | #3 | Full-screen player resumes correctly |
| 8 | Disable PiP toggle → minimize app | #3 | Normal minimize, no PiP window |
| 9 | Run on Android TV | All | Layout unchanged; no PiP or inset changes applied |
| 10 | `flutter upgrade` in future → rebuild | #2 | Play Console Issue #2 clears after Flutter engine patch |
| 11 | Resubmit to Play Console | #1 #3 | Issues #1 and #3 resolved; #2 pending Flutter fix |
