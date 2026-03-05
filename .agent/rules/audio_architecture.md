---
trigger: audio, playback, state, native, background
policy_domain: Audio Architecture
---
# Audio Architecture & Native Engine Directives

### 1. State Isolation
* **Action:** Never mix UI rendering logic with the core audio playback state. 
* **Constraint:** Assume the audio service operates as a singleton or an isolated state provider. 
* **Focus:** Keep media control events (play, pause, seek) strictly separated from visual layout code.

### 2. Native Engine & Queue
* **Action:** Use `just_audio` for the primary playback engine on native targets.
* **Action:** Implement `just_audio_background` for OS-level media notifications and background persistence.
* **Action:** Sync track metadata to the OS media controller on every track change.
* **Action:** Use **Hive** for show metadata caching and persistent play counts.
* **Constraint: NEVER use `ConcatenatingAudioSource`.** This class is legacy/deprecated in favor of the direct `setAudioSources` API on the player. Using the old wrapper causes synchronization/shuffle bugs on Android and TV.
