# Default Settings Configuration

The application's default settings are centralized in a single configuration file. This makes it easy to adjust the initial state for new users or when resetting preferences.

**Configuration File**: [`lib/config/default_settings.dart`](lib/config/default_settings.dart)

To change a default, simply edit the value in that file and re-run the app.

## Available Settings

| Setting | Variable Name | Default Value | Description |
| :--- | :--- | :--- | :--- |
| **Appearance** | | | |
| Dynamic Color | `useDynamicColor` | `true` | Uses wallpaper-based Material 3 colors. |
| True Black | `useTrueBlack` | `false` | Deep black background for OLED screens. |
| App Font | `appFont` | `'default'` | Main typeface. Options: `'default'`, `'caveat'`, `'permanent_marker'`, `'rock_salt'` |
| Glow Mode | `glowMode` | `0` (Off) | Border glow effect intensity (0-100). |
| **Show Card** | | | |
| Track Numbers | `showTrackNumbers` | `false` | Show indexes in track lists. |
| Hide Duration | `hideTrackDuration` | `true` | Hide minutes/seconds for cleaner look. |
| Date First | `dateFirstInShowCard` | `true` | Show date above artist in lists. |
| **Playback** | | | |
| Play on Tap | `playOnTap` | `false` | Play immediately when tapping a show/track. |
| Auto-Play Startup | `playRandomOnStartup` | `false` | Start a random show on app launch. |
| Random on End | `playRandomOnCompletion` | `false` | Auto-play next random show when finished. |
| **Data** | | | |
| Single SHNID | `showSingleShnid` | `false` | If true, hides other sources if one is selected. |
| Sort Order | `sortOldestFirst` | `true` | Default sort chronological by date. |
| Strict Categories | `useStrictSrcCategorization` | `true` | Use strict rules for SBD/Matrix identification. |
| **Source Filters** | `sourceCategoryFilters` | `{ 'matrix': true, ... }` | Default allowed source types (Matrix is default). |

## How to Edit

1.  Open `lib/config/default_settings.dart`.
2.  Locate the setting you wish to change.
3.  Update the value (e.g., change `false` to `true`).
4.  Run the app.
    *   *Note: If you have already installed the app, your existing preferences are saved locally and will override these defaults. these defaults apply to **fresh installs** or when you **clear data**.*
