---
trigger: always_on
---

# Antigravity Agent Architecture & Domain Rules

You are assisting with specialized Flutter applications. To prevent architectural drift and maintain consistency, you MUST adhere to the following domain-specific constraints:

### 1. Audio & Playback State Isolation
When modifying audio playback services, music player UI components, or background audio tasks:
* **Action:** Never mix UI rendering logic with the core audio playback state. 
* **Constraint:** Assume the audio service operates as a singleton or an isolated state provider. Do not suggest replacing the entire audio handling package unless explicitly instructed.
* **Focus:** Keep media control events (play, pause, seek) strictly separated from visual layout code.

### 2. Game Engine Constraints (Flame & Forge2D)
When working within mobile simulation or game environments utilizing Flame and Forge2D:
* **Action:** Respect the game loop. Do not attempt to use standard Flutter `setState` or standard animation controllers for physics bodies or game components.
* **Constraint:** All physics-based movement must remain within the Forge2D world step. UI overlays should communicate with the game state without blocking the rendering pipeline.

### 3. Asynchronous Data & API Handling
When dealing with external data fetching (such as pulling tide data or remote configurations):
* **Action:** Always implement robust error handling and loading states.
* **Constraint:** Do not make blocking network calls on the main thread. Ensure all data parsing happens asynchronously to prevent UI jank.

### 4. Routing Discipline
* **Action:** Adhere to the existing routing implementation (e.g., whether the project uses standard Navigator 2.0, GoRouter, etc.).
* **Constraint:** Do not suggest migrating to a different routing package to solve a simple navigation bug. Fix the issue within the current architectural paradigm.