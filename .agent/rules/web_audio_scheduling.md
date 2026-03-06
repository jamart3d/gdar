# Web Audio Scheduling Rule

### Context
Precise audio transitions (0ms gapless) on Web and PWA platforms are sensitive to browser timer drift, especially during CPU throttling or backgrounding. Standard Dart `Timer` or `Future.delayed` calls are NOT sufficient for high-precision audio events.

### Rules
1. **Use Specialized Scheduler**: All high-precision audio timing (handoffs, crossfades, look-ahead buffering) MUST be orchestrated via the `gapless_audio_engine.js` scheduler.
2. **No Dart Timers for Audio**: Prohibited to use `Timer` or `Future.delayed` for calculating song transitions. These should instead listen for messages or state updates from the JS-side scheduler.
3. **Throttling Awareness**: When modifying the JS engine, always assume a **6x CPU slowdown** (Chrome DevTools simulation). Timers must be "look-ahead" (scheduling events in advance onto the Web Audio `AudioContext.currentTime` timeline) rather than "just-in-time".
4. **Verification**: After any change to the Web audio logic, the `Phase 4` audit in `test/prompts/jules_audit.md` MUST be run to verify 0ms transitions under pressure.
