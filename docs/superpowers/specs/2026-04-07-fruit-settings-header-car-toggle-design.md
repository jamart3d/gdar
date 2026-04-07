# Fruit Settings Header Car Toggle Design

## Goal

Add a Fruit-style car toggle button to the web/PWA Fruit settings screen top
bar, positioned immediately left of the existing dark/light theme toggle.

## Scope

- Fruit settings screen header only
- No changes to show list, playback, or other app bars
- No Material widgets or interaction patterns

## Behavior

- When the header car button is pressed while car mode is off:
  - enable `carMode`
  - enable `preventSleep`
  - enable `fruitFloatingSpheres`
  - enable `fruitEnableLiquidGlass`
- When the header car button is pressed while car mode is on:
  - disable `carMode`
  - disable `preventSleep`
  - leave `fruitFloatingSpheres` unchanged
  - leave `fruitEnableLiquidGlass` unchanged

## UI Contract

- Use the existing Fruit header action button style so the new control matches
  the back button and theme toggle.
- Use a car icon.
- Keep the header layout otherwise unchanged.
- Reflect the active `carMode` state in the button icon color so the toggle is
  readable at a glance without adding new text.

## Architecture

- Keep the shortcut logic local to `SettingsScreen`.
- Compose existing `SettingsProvider` toggle methods instead of adding a new
  provider API unless local composition becomes error-prone.
- Add focused widget coverage for the Fruit settings header path and the toggle
  side effects.

## Testing

- Add a widget regression test for the Fruit settings screen header button.
- Verify the button exists in the header and toggles the expected settings.
- Verify disabling via the header leaves spheres and liquid glass unchanged.
