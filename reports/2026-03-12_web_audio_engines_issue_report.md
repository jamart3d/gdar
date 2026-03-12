# Web UI Audio Engines Issue Report (2026-03-12)

## Scope
Review the current web/PWA audio engines, hybrid behavior, and settings, and
recommend the best approach for long background sessions with gapless playback.

## Current Engine Map (Repo)
- Web Audio gapless engine: `web/gapless_audio_engine.js` (AudioContext scheduling)
- HTML5 gapless engine: `web/html5_audio_engine.js` (Relisten gapless port)
- Hybrid engine: `web/hybrid_audio_engine.js` (Web Audio foreground, HTML5 background)
- Passive engine: `web/passive_audio_engine.js` (HTMLAudioElement + Media Session)
- Selector/dispatcher: `web/hybrid_init.js`
- Dart bridge: `lib/services/gapless_player/gapless_player_web.dart`
- Settings: `lib/providers/settings_provider.dart`
- Settings UI: `lib/ui/widgets/settings/playback_section.dart`
- Defaults: `lib/config/default_settings.dart`

## Constraints (Web/PWA Reality)
- Web Audio can be suspended or interrupted when the tab is hidden or the OS
  throttles background execution.
- Autoplay and background survival tricks (silent audio/video) require user
  gesture and are not guaranteed on all browsers.
- HTMLAudioElement is the most reliable path for long background sessions,
  but true 0ms gapless across tracks is less reliable while hidden.

## Findings
- Hybrid engine already detects Web Audio suspension and can hand off to HTML5.
- Hybrid engine uses a heartbeat (silent audio/video) to improve background
  survivability when enabled.
- Hidden Session Presets map to concrete engine choices:
  - stability: html5 + video survival
  - balanced: hybrid + buffered + heartbeat
  - maxGapless: webAudio first, allow hidden Web Audio
- Web defaults currently prefer HTML5 on web for compatibility.

## Recommendations
1. Best overall for long background sessions (PWA):
   - Use Hybrid with HTML5 background and Web Audio foreground.
   - Keep "Allow Web Audio while hidden" OFF.
   - Prefer the "Balanced" or "Stability" preset depending on device class.
2. Best gapless while visible (accept background fragility):
   - Use Web Audio or Hybrid + Max Gapless.
   - Expect interruptions when hidden on mobile browsers.
3. Maximum background longevity (accept small gaps):
   - Use HTML5 or Passive engine. This is the most reliable for long sessions.

## Suggested Defaults (If You Want to Bias for Long Sessions)
- Web/PWA default: Hybrid + Balanced
- Allow hidden Web Audio: OFF
- Hybrid background mode: heartbeat (or video on the most aggressive profile)
- Prefetch seconds: keep current fixed value unless profiling suggests otherwise

## Validation Plan
- Run long background soak tests by preset (stability/balanced/maxGapless).
- Verify Media Session metadata and controls are active for HTML5/passive paths.
- Confirm handoff behavior with visibility changes and long tracks (> 15 min).

## Open Questions
- Do we want to change the default web engine from HTML5 to Hybrid (Balanced)?
- Should the "Hidden Session Preset" be the primary web/PWA audio choice UI?
