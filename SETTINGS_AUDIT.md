# Settings Configuration Audit

**Date**: 2026-02-10
**App Version**: 1.0.31+31
**AI Model**: Gemini 2.0
**Project**: Shakedown (GDAR)

---

## 🛠️ Configuration Overview

This report details the persistent settings managed by `SettingsProvider`. These values are stored in `SharedPreferences`.

### 1. Playback & Audio
| Setting | Key | Default | Description |
| :--- | :--- | :--- | :--- |
| **Play On Tap** | `play_on_tap` | `true` | Instantly play a track when tapped in the list. |
| **Gapless Playback** | *Core* | `true` | Enforced by `JustAudioBackground` and `setAudioSources`. |
| **Offline Buffering** | `offline_buffering` | `true` | **Active Cache**: Uses `LockCachingAudioSource` to download and lock audio files to a dedicated temp directory (`shakedown_audio_cache`). Files are named via SHA-256 hash of the URL. Includes auto-cleanup logic (keeps ~20 recently played files). |
| **Buffer Agent** | `enable_buffer_agent` | `true` | **Smart Recovery**: Background service that monitors network/player state. <br>• **Foreground**: Notifies user to retry if buffering stalls (>20s). <br>• **Background**: Silently attempts connection recovery with randomized backoff (15-30s). |
| **Playback Messages** | `show_playback_messages` | `false` | Show verbose SnackBars on playback state changes (Pause/Resume). |

### 2. Random Show Logic
| Setting | Key | Default | Description |
| :--- | :--- | :--- | :--- |
| **Play on Startup** | `play_random_on_startup` | `false` | Automatically start a random show on app launch. |
| **Play on Completion** | `play_random_on_completion` | `false` | Queue a random show after the current one finishes. |
| **Exclude Played** | `random_exclude_played` | `false` | Avoid repeating previously played shows. |
| **High Rated Only** | `random_only_high_rated` | `false` | Restrict random selection to 4+ star shows. |
| **Unplayed Only** | `random_only_unplayed` | `false` | Restrict random selection to unplayed shows. |

### 3. UI & Aesthetics
| Setting | Key | Default | Description |
| :--- | :--- | :--- | :--- |
| **App Font** | `app_font` | `default` | Options: Default, Caveat, Rock Salt, Permanent Marker. |
| **Dynamic Color** | `use_dynamic_color` | `true` | Material You (Monet) theming based on wallpaper. |
| **True Black** | `use_true_black` | `false` | OLED-optimized dark mode. |
| **Glow Mode** | `glow_mode` | `0` (Off) | Border glow intensity (0%, 25%, 50%, 100%). |
| **RGB Animations** | `highlight_playing_with_rgb` | `true` | RGB border effect for playing track/show. |
| **UI Scale** | `ui_scale` | `Auto` | Adapts layout density based on screen width (<720px = Mobile). |
| **Marquee** | `marquee_enabled` | `true` | Scroll long titles in the player. |

### 4. List Display
| Setting | Key | Default | Description |
| :--- | :--- | :--- | :--- |
| **Track Numbers** | `show_track_numbers` | `true` | Display indices in track lists. |
| **Track Duration** | `hide_track_duration` | `false` | Hide/Show MM:SS duration. |
| **Single Source SHNID** | `show_single_shnid` | `false` | Show ID even if show has only 1 source. |
| **Date First** | `date_first_in_show_card` | `false` | Date before Venue in list cards. |
| **Show Day of Week** | `show_day_of_week` | `true` | Include "Fri", "Sat", etc. in dates. |

### 5. Debug & Development
| Setting | Key | Default | Description |
| :--- | :--- | :--- | :--- |
| **Debug Layout** | `show_debug_layout` | `false` | Show visual debug bounds/overlays. |
| **Shakedown Tween** | `enable_shakedown_tween` | `true` | Enable complex custom animations. |
| **Strict Categorization**| `use_strict_src_categorization`| `true` | strict filtering of source types. |

---

## 🔒 Security Audit
**Release Mode Restrictions**:
- Deep Links for `navigate` and `settings` are **DISABLED**.
- ADB `ui_scale` overrides are effective but restricted by debug signing constraints on some platforms.
