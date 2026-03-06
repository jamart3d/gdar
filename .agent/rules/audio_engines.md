---
trigger: audio, playback, state, engine, web, native
policy_domain: Audio Engines & Architecture
---
# Unified Audio Engine & Architecture Directives

### 1. General State Isolation
* **Action:** Never mix UI rendering logic with the core audio playback state. 
* **Constraint:** Assume the audio service operates as a singleton or an isolated state provider. 
* **Focus:** Keep media control events (play, pause, seek) strictly separated from visual layout code.

### 2. Native Engine (`just_audio`)
* **Action:** Use `just_audio` for the primary playback engine on native targets.
* **Action:** Implement `just_audio_background` for OS-level media notifications and background persistence.
* **Action:** Sync track metadata to the OS media controller on every track change.
* **Action:** Use **Hive** for show metadata caching and persistent play counts.
* **Constraint: NEVER use `ConcatenatingAudioSource`.** Use the direct `setAudioSources` API on the player.

### 3. Web & Hybrid Engines
* **Action:** Use an isolated AudioWorklet worker for the Web Audio engine.
* **Action:** Implement `HybridAudioOrchestrator` for seamless Engine 1 (just_audio) → Engine 2 (Web Audio) handoff.
* **Constraint:** Never share an `AudioContext` across tracks.
* **Constraint:** Never refactor the Relisten engine to use `ReadableStream`.
