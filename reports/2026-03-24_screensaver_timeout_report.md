# Issue Report: Screensaver Timeout Bug

**App Version:** 1.3.15+225 (gdar_tv)
**Component:** `InactivityService` / `InactivityDetector` / `GdarTvApp`

## Description of the Problem
The user reports: "Screensaver timeout is not making screensaver start, it can be started manually".
This indicates that `ScreensaverScreen` itself is fully functional and does not crash when launched. The issue is uniquely isolated to the autonomous `_handleInactivityTimeout` mechanism in `GdarTvApp` failing to fire or failing to route successfully when idle.

## Architectural Deep Dive
To determine the root cause, I performed a line-by-line trace of the following components:
1.  **`InactivityService`**: The pure Dart timer mechanism that counts down 1, 5, or 15 minutes.
2.  **`InactivityDetector`**: The Flutter UI wrapper that catches `PointerDown` and `KeyDownEvent`s to reset the timer.
3.  **`GdarTvApp`**: The top-level state machine defining `_syncInactivityService`, `_handleInactivityTimeout`, and routing rules via `_TvNavigationObserver`.

### Verified Working Logic (What is NOT broken)
*   **Startup & Eligibility:** The `SplashScreen` cleanly uses `Navigator.pushReplacement` with `RouteSettings(name: ShakedownRouteNames.tvHome)`. This correctly triggers `didReplace` on the `_TvNavigationObserver`. `_currentRouteName` correctly evaluates to `/tv_home` which makes `_isInactivityRouteEligible` return `true`.
*   **Timer Instantiation:** When `_isInactivityRouteEligible` evaluates to `true`, `_syncInactivityService` cleanly calls `_inactivityService.start()`. `_isEnabled` flips to `true`, and `Timer(Duration(minutes: 1))` is successfully allocated.
*   **Settings Pipeline:** `SettingsProvider.oilScreensaverInactivityMinutes` natively defaults to `1` (via `TvDefaults` inheriting from `DefaultSettings.oilScreensaverInactivityMinutes`). Rebuild loops over `Consumer2` safely short-circuit `_inactivityService.start()` if `_isEnabled == true`, so the timer is NOT maliciously reset by generic UI repaints.
*   **Manual Operation Lifecycle:** Since manual invocation skips `_showScreensaver`, `_isScreensaverActive` remains `false` but the route effectively becomes `/screensaver`. `_syncInactivityService` responds by stopping the timer. Exiting the screensaver returns the route to `/tv_home` and restores the timer precisely. 

## Identified Probable Root Causes
Given that the deterministic state machine code in `_syncInactivityService` is architecturally bulletproof on paper, the failure natively falls into environmental input or silent Navigator disruption.

### 1. Phantom/Sustained Input Spamming `InactivityDetector`
`InactivityDetector._handleKeyEvent` blindly listens to `HardwareKeyboard.instance.addHandler`. 
*   **The Flaw:** If a connected Android TV Bluetooth remote, an HDMI-CEC polling adapter, or a paired gamepad constantly transmits a baseline input signal (e.g., a "keepalive" `KeyDownEvent` that does not technically flag as a `KeyRepeatEvent`), `widget.inactivityService?.onUserActivity()` will reset the underlying `Timer` back to 1 minute ad-infinitum. The screensaver will never have the opportunity to fire.

### 2. Route Name Scrubbing by Hidden System Dialogs
*   **The Flaw:** `_isInactivityRouteEligible` strictly demands an explicit named route. If Android TV overlays a system-level volume UI, pairing dialog, or silent `PopupRoute`, `_TvNavigationObserver.didPush` will trigger with `route.settings.name == null`. When `_handleRouteChanged` executes, `_currentRouteName` will become `null`. `shouldRun` will instantly evaluate to `false`, implicitly calling `_inactivityService.stop()`. The timer dies and never reboots until the user explicitly bounces back to a named route.

## Recommended Fixes
1.  **Harden `_handleKeyEvent` Noise Rejection**: 
    Augment the `InactivityDetector` to strictly allowlist standard D-Pad / Navigation / Playback keys rather than capturing *every* `KeyDownEvent`. Filter out system-level pings and unmapped sensor inputs.
2.  **Soften Route Nullification Rules**:
    In `GdarTvApp._handleRouteChanged`, ignore `null` named routes (like anonymous popups or tooltips) rather than letting them blindside `_currentRouteName` to `null`. If `route?.settings.name` is null, preserve the last explicit named route (i.e. `/tv_home`) to keep the timer ticking underneath transparent modals.
3.  **Debug Output Ticking**:
    Bind `debugPrint` output in `_inactivityService.onUserActivity()` to log specifically *which* `source` is keeping the device awake, enabling physical Android TV testing to conclusively identify if an HDMI-CEC issue is at play.
