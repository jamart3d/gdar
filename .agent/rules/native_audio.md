---
trigger: audio, native, background, queue
policy_domain: Native Audio
---
# Native Audio Directives

### Engine & Queue
* **Action:** Use a flattened AudioSource list for all queue management.
* **Action:** Implement just_audio_background for background awareness and foreground service.
* **Action:** Sync track metadata to the OS media controller on every track change.
* **Action:** Use Hive for show metadata cache on all native targets.
* **Constraint:** Never use ConcatenatingAudioSource under any circumstances.
