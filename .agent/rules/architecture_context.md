---
trigger: always_on
---

# Antigravity Agent Architecture & Domain Rules

You are assisting with specialized Flutter applications. To prevent architectural drift and maintain consistency, you MUST adhere to the following domain-specific constraints:

### 1. Game Engine Constraints (Flame)
When working within mobile simulation or game environments utilizing Flame:
* **Action:** Respect the game loop. Do not attempt to use standard Flutter `setState` or standard animation controllers for components inside the Flame world.
* **Constraint:** All game-state updates must remain within the Flame `update(dt)` cycle. UI overlays should communicate with the game state via event notifications without blocking the rendering pipeline.

### 2. Asynchronous Data & API Handling
When dealing with external data fetching (such as pulling tide data or remote configurations):
* **Action:** Always implement robust error handling and loading states.
* **Constraint:** Do not make blocking network calls on the main thread. Ensure all data parsing happens asynchronously to prevent UI jank.

### 3. Routing Discipline
* **Action:** Adhere to the existing routing implementation (e.g., whether the project uses standard Navigator 2.0, GoRouter, etc.).
* **Constraint:** Do not suggest migrating to a different routing package to solve a simple navigation bug. Fix the issue within the current architectural paradigm.

### 4. AMOLED & True Black Design
* **Action:** When implementing "Glow" effects (e.g., in `AnimatedGradientBorder`), ensure shadows are NOT fully disabled in True Black mode if the glow intensity is > 0.
* **Constraint:** True Black mode removes background colors but should preserve depth through subtle shadows to maintain UI hierarchy.

### 5. UI Padding & Scaffold
* **Action:** When using a custom `Positioned` AppBar inside a `Stack` (e.g., in `PlaybackScreen`), set `primary: false` on the parent `Scaffold`.
* **Constraint:** This prevents the `Scaffold` from adding its own automatic top padding (status bar height), which results in "double-padding" when the AppBar is already handling its own offset.
 
### 6. Async Playback Transitions
* **Action**: When implementing "pending" or "look-ahead" states for show selection (e.g., during dice rolls or automated transitions), ensure these states are strictly cleared or synchronized when the underlying audio engine's `currentIndexStream` or `MediaItem` tag emits a new value.
* **Constraint**: Do not rely on loose timers or `Future.delayed` to synchronize UI metadata with the audio engine; authoritative stream synchronization is mandatory to prevent stale metadata.
