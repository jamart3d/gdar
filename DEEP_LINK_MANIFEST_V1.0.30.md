# Shakedown Deep Link Manifest

**Date**: 2026-02-10
**AI Assistant**: Antigravity (Google DeepMind)
**AI Model**: Gemini 2.0
**App Version**: 1.0.30+30
**Project**: Shakedown (GDAR)

---

## 🚀 Release Mode Links
These links are fully functional in the production environment.

### 1. Music & Playback
- **Play Random Show**: `shakedown://play-random`
  - `?animation_only=true` (Optional: UI only, no audio trigger)
- **Player Interface**: `shakedown://player`
  - `?action=pause | resume | play | stop` (Direct transport control)

### 2. App Features (Open)
- **Open Feature**: `shakedown://open?feature=<name>`
  - *Note*: If the feature name contains `play` or `random`, it will trigger a random show. Supports `?animation_only=true`.

---

## 🛠️ Debug Mode Only
*Disabled in release builds for security.*

- **Application Navigation**: `shakedown://navigate?screen=<name>`
  - `screen=settings` (Optional: `?highlight=<key>` to pulse a setting)
  - `screen=home` (Optional: `?action=search` to open search filter)
  - `screen=player` (Optional: `?panel=open` to expand drawer)
  - `screen=track_list` (Required: `?index=<n>` for list selection)
  - `screen=onboarding` / `screen=splash`
- **Dynamic Configuration**: `shakedown://settings?key=<key>&value=true|false`
  - Supported keys: `show_playback_messages`, `show_splash_screen`
- **Layout Scaling**: `shakedown://ui-scale?enabled=true`
- **Typography Testing**: `shakedown://font?name=<font_family>`
- **System Reset**: `shakedown://debug?action=reset_prefs`
- **State Manipulation**: `shakedown://debug?action=complete_onboarding | simulate_update`

---

## 🤖 Intent Mappings (shortcuts.xml)
- **Assistant/Gemini**: `actions.intent.PLAY_MUSIC` triggers `shakedown://play-random`
- **Feature Discovery**: `actions.intent.OPEN_APP_FEATURE` triggers `shakedown://open`
