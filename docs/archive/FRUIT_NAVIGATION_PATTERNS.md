# Fruit Navigation Patterns & Synchronization

## The Goal
The **Fruit** theme (Liquid Glass) requires instantaneous response to user interaction while managing background audio engine complex state.

## Synchronization Rules

### 1. The PlayRandom Flow
When `AudioProvider.playRandomShow()` is called:
- **Audio Side**: Triggers an asynchronous fetch of the show metadata.
- **UI Side**: The UI MUST navigate to the `track_list` or `playback` screen immediately, even if the audio is still buffering or being processed via `delayPlayback`.
- **Logic**: Use `Navigator.of(context).pushNamed(RouteNames.playback)` as the primary entry point.

### 2. SplashScreen Handover
The `SplashScreen` is the first point of theme-based routing.
- If `settings.appTheme` is `fruit`, the splash screen MUST route to `FruitTabHostScreen`.
- Never use `MaterialPageRoute` for Fruit transitions; only use transparent or fade-through transitions to preserve the backdrop blur.

### 3. State-Based Redirection
Ensure any `AudioProvider` state changes (like `trackFinished` or `playRandom`) trigger appropriate tab selections in the host screen via the `audioProvider.trackStream`.

## Common Pitfalls
- **M3 Leakage**: Do not use `Scaffold.appBar` in Fruit screens; use custom `Stack` + `Positioned` to prevent layout jumps during navigation.
- **Async Latency**: If the UI waits for a `Future` from the audio player BEFORE navigating, the experience feels sluggish. Always navigate first, then let the track load into the destination UI.
