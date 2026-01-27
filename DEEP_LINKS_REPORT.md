# Deep Link Intent Audit Report

This report documents all identified deep link intents and URI schemes supported by the Shakedown (GDAR) application, separated by their primary purpose.

## Production Intents
These intents are integrated with Android System features such as Google Assistant, Gemini, and App Shortcuts for end-user functionality.

| Intent Action / URI | Definition Source | Purpose / Description |
| :--- | :--- | :--- |
| `android.intent.action.MAIN` | `AndroidManifest.xml` | Standard launcher entry point for the application. |
| `shakedown://play-random` | `main.dart`, `shortcuts.xml` | Triggers a random show selection and immediate playback. |
| `gdar://play-random` | `main.dart` | Alternative scheme for triggering a random show. |
| `shakedown://open?feature={feature}` | `main.dart`, `shortcuts.xml` | Opens specific app features via voice or shortcut (e.g., "play", "random"). |
| `actions.intent.PLAY_MUSIC` | `shortcuts.xml` | App Action binding for Assistant "Play Grateful Dead" commands. |
| `actions.intent.OPEN_APP_FEATURE` | `shortcuts.xml` | App Action binding for Assistant "Open [feature]" commands. |
| `android.media.action.MEDIA_PLAY_FROM_SEARCH` | `AndroidManifest.xml` | Support for standard Android media playback search intents. |
| `android.intent.action.SEARCH` | `AndroidManifest.xml` | Support for generic Android search intents. |

## Testing & Developer Intents
These intents are primarily used during development and testing to quickly verify layout configurations or theme changes without manually navigating the settings menu.

| URI Scheme & Parameters | Definition Source | Purpose / Description |
| :--- | :--- | :--- |
| `shakedown://ui-scale?enabled=true` | `main.dart`, `MainActivity.kt` | Toggles the 1.2x Global UI Scaling mode for layout testing. |
| `shakedown://font?name={font_name}` | `main.dart` | Switches the active app font. Valid names: `default`, `caveat`, `permanent_marker`, `rock_salt`. |

---
> [!NOTE]
> Testing intents can be triggered via ADB for rapid iteration:
> `adb shell am start -W -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true"`
