---
trigger: audio, web, worker, engine
policy_domain: Web Audio
---
# Web Audio Directives

### Engine Architecture
* **Action:** Use an isolated AudioWorklet worker for the Web Audio engine.
* **Action:** Implement HybridAudioOrchestrator for seamless Engine 1 → Engine 2 handoff.
* **Constraint:** Never refactor the Relisten engine to use ReadableStream.
* **Constraint:** Never share an AudioContext across tracks.
