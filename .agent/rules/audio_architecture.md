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
* **Action:** Use **Hive** for show metadata caching and persistent play counts on all native/desktop targets.
* **Action:** Use a flattened `AudioSource` list for all queue management.
* **Constraint: NEVER use `ConcatenatingAudioSource`.** Using the old wrapper causes synchronization/shuffle bugs.

### 3. Web Engine Architecture
* **Action:** Use an isolated `AudioWorklet` worker for the Web Audio engine.
* **Action:** Implement `HybridAudioOrchestrator` for seamless Engine 1 → Engine 2 handoff.
* **Constraint:** Never refactor the Relisten engine to use `ReadableStream`.
* **Constraint:** Never share an `AudioContext` across tracks.
