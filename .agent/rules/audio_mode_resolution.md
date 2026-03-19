---
trigger: audio, engine, hybrid, mode, settings
policy_domain: Audio Engine Mode
---
# Audio Engine Mode — Resolved vs Stored

### The Problem
`sp.audioEngineMode` (stored in `SettingsProvider`) may be `AudioEngineMode.auto`. On a capable desktop, `auto` resolves to `hybrid` at runtime. UI that gates on the stored value will incorrectly hide controls for the most common desktop user.

### Rule
Always use the **resolved** active mode for UI gating:

```dart
final resolvedMode = sp.audioEngineMode == AudioEngineMode.auto
    ? context.read<AudioProvider>().audioPlayer.activeMode
    : sp.audioEngineMode;
```

Then gate on `resolvedMode`, not `sp.audioEngineMode`:

```dart
// WRONG — hides controls for default desktop (auto → hybrid)
if (sp.audioEngineMode == AudioEngineMode.hybrid) ...

// CORRECT
if (resolvedMode == AudioEngineMode.hybrid) ...
```

### Where This Applies
- Hybrid Handoff Mode selector visibility
- Background Survival Strategy selector visibility
- Any conditional UI that depends on which engine is actually running

### Engine Selector selectedValue
The engine selector chip already uses this pattern correctly:
```dart
selectedValue: sp.audioEngineMode == AudioEngineMode.auto
    ? context.read<AudioProvider>().audioPlayer.activeMode
    : sp.audioEngineMode,
```
All dependent controls must follow the same pattern.
