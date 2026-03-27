# DevAudioHud

`DevAudioHud` is the web playback diagnostics overlay for GDAR. It is a
compact, always-expanded HUD that exposes engine state, hybrid handoff state,
buffering health, and Web Audio timing data in real time.

This document describes the implemented HUD behavior in the current codebase.

## 1. Layout

The HUD is rendered as five semantic rows:

1. `Sparklines`
2. `Controls`
3. `State`
4. `Metrics`
5. `Messaging`

The rows are built in
[packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_build.dart](../../packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_build.dart).

### Sparklines

Each sparkline chip combines:

- a trend graph
- a key badge in the top-left
- the current numeric value in a separate badge at the bottom-right
- a tooltip on hover / long-press

The label and value are intentionally styled differently so the sparkline can
be scanned quickly.

### Controls

Interactive chips have a visible border and dropdown affordance:

- `ENG`
- `HF`
- `BG`
- `STB`
- `PF`

### State

Read-only state chips summarize what the engine is doing now:

- `AE`
- `V`
- `ST`
- `PS`
- `SHD`
- `GAP`
- `PM`
- WA-only telemetry when relevant: `LAT`, `ERR`, `WTC`, `SR`, `CAC`
- hybrid-only telemetry: `HS`, `HAT`

### Metrics

Numeric metrics and session counters:

- `BUF`
- `NX`
- `LG`
- `BGT`
- `D`

`D` is the runtime profile chip. Internally the key is still `DET`, but the
visible label is intentionally shortened to `D:`.

### Messaging

Bottom-row messaging chips:

- `E`
- `SIG`
- `MSG`

`MSG` is tappable and clears the active issue.

## 2. Sparkline Suite

The top row adapts to the active engine.

### Always shown

- `DFT`: tick drift history
- `HD`: headroom history

### Shown in Web Audio and Hybrid

- `NET`: fetch time-to-first-byte history

### Shown only when WA telemetry is actually valid

These are shown in pure `WBA`, or in `HYB` only when the active sub-engine is
currently Web Audio:

- `SCH`: schedule lead time
- `DEC`: decode time
- `BCT`: buffer concat time

### Shown in Hybrid

- `HPD`: handoff poll depth

### Sparkline meanings

| Key | Meaning | Notes |
| :--- | :--- | :--- |
| `DFT` | Time between state ticks | Lower and steadier is better |
| `HD` | Buffer time ahead of playback | Dimmed in pure WA because it behaves more like time remaining |
| `NET` | Archive fetch TTFB | In-flight fetches show elapsed time |
| `SCH` | Seconds until the next WA start | Computed from `scheduledStartContextTime - ctxCurrentTime` |
| `DEC` | `decodeAudioData()` time | Last decode cost |
| `BCT` | post-fetch concat time | Cost of assembling downloaded chunks |
| `HPD` | restore poll cycles | Number of polls before WA became ready |

## 3. Chip Reference

### Controls

| Key | Meaning |
| :--- | :--- |
| `ENG` | Configured engine mode |
| `HF` | Hybrid handoff mode |
| `BG` | Background strategy |
| `STB` | Hidden-session preset |
| `PF` | Prefetch window |

### Core State

| Key | Meaning |
| :--- | :--- |
| `AE` | Active playback engine or active hybrid sub-engine |
| `V` | Visibility state |
| `ST` | Internal engine state |
| `PS` | Playback processing state |
| `SHD` | Session shield summary |
| `GAP` | Gapless readiness summary |
| `PM` | Performance mode |
| `E` | Error flag |
| `SIG` | Message severity |
| `MSG` | Current status message |

### Metrics

| Key | Meaning |
| :--- | :--- |
| `BUF` | Current-track buffered amount |
| `NX` | Next-track buffered amount |
| `LG` | Last measured track gap |
| `BGT` | Total hidden-tab time this session |
| `D` | Runtime profile: `L`, `P`, `D`, `W` |

### WA Telemetry

| Key | Meaning |
| :--- | :--- |
| `LAT` | AudioContext output latency |
| `ERR` | Failed fetch/decode count |
| `WTC` | Worker tick count |
| `SR` | AudioContext sample rate |
| `CAC` | Decoded buffer cache depth |
| `SCH` | Schedule lead time |
| `DEC` | Decode time |
| `BCT` | Concat time |

### Hybrid Telemetry

| Key | Meaning |
| :--- | :--- |
| `HS` | Hybrid handoff state |
| `HAT` | True handoff-attempt count for the current session |
| `HPD` | Poll depth of the last successful restore |

`HAT` is intentionally a session counter now. It no longer mirrors the
internal stale-loop cancellation token.

## 4. Engine Gating

The HUD hides or dims chips when their source data is not meaningful.

### Pure Web Audio (`WBA`)

- Shows WA telemetry
- Shows `NET`
- Shows `HD` dimmed
- Does not show hybrid-only controls or counters

### Pure HTML5 (`H5`)

- Hides WA-only telemetry
- Hides `NET`
- Hides hybrid controls
- Keeps the general state, metric, and messaging rows

### Hybrid (`HYB` / `AUT`)

- Shows hybrid controls and counters
- Shows `NET`
- Shows WA-only telemetry only when the active sub-engine is WA
- Keeps `HPD` visible as a hybrid-only sparkline

## 5. Tooltip Behavior

Every sparkline and chip can expose a tooltip.

### Fruit tooltip styling

In Fruit mode, the HUD uses
[packages/shakedown_core/lib/ui/widgets/theme/fruit_tooltip.dart](../../packages/shakedown_core/lib/ui/widgets/theme/fruit_tooltip.dart).

Tooltips support rich text, and important tokens are color-aligned with the
HUD language where possible, for example:

- `WA` / `WBA`
- `H5`
- `HYB`
- `ISS`
- `RDY`
- `D`

### Tooltip goals

Tooltip copy is intentionally short:

- explain the acronym
- describe whether lower/higher is better when useful
- avoid repeating obvious label text

## 6. Color Cues

The HUD uses color as a fast risk signal.

### Common patterns

- `Green`: healthy / ready / low latency / low gap
- `Amber` or `Orange`: caution / transition / moderate latency
- `Red`: issue / starvation / high gap / failure
- `Cyan` / `Light Blue`: Web Audio or visibility/context signals

### Specific examples

- `LG` turns green for very small gaps, amber for moderate gaps, red for large
  gaps
- `NET` uses green, amber, and red thresholds for completed TTFB samples
- `ERR` is highlighted when non-zero
- `HS` and `HAT` shift warmer when handoff activity grows

## 7. Session Health Chips

### `SHD`

Session shield summary:

- `VIS`: tab visible
- `OK`: protected
- `SOFT`: best-effort protection
- `RISK`: protection needed but not active
- `DEAD`: no useful protection
- `--`: not playing

### `GAP`

Gapless readiness summary:

- `RDY`
- `WAIT`
- `LOW`
- `MISS`
- `OFF`
- `--`

### `LG`

`LG` reports the last audible transition gap. In hybrid mode this includes the
full H5-to-WA boundary gap when that path is used.

## 8. Hybrid Handoff Telemetry

### `HS`

Hybrid handoff state:

- `IDLE`
- `ARM`
- `FNC`
- `PRB`
- `DONE`

### `HAT`

`HAT` counts real hybrid handoff launches for the current session. Lower is
usually better. A high number can indicate frequent swaps, repeated retry
pressure, or lots of seeking/skipping.

### `HPD`

`HPD` shows how many restore polls were needed before Web Audio reported
`ready`. Lower is better.

## 9. Data Sources

The HUD is built from `HudSnapshot`, which is fed by:

- web engine JS state
- hybrid engine JS state
- computed Dart-side summaries and histories

Key files:

- [packages/shakedown_core/lib/models/hud_snapshot.dart](../../packages/shakedown_core/lib/models/hud_snapshot.dart)
- [packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart](../../packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart)
- [packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_build.dart](../../packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_build.dart)
- [packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_helpers.dart](../../packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_helpers.dart)
- [apps/gdar_web/web/gapless_audio_engine.js](../web/gapless_audio_engine.js)
- [apps/gdar_web/web/hybrid_audio_engine.js](../web/hybrid_audio_engine.js)

## 10. Current Status

The HUD now includes:

- adaptive sparkline chips with embedded values
- WA advanced telemetry
- hybrid handoff telemetry
- engine-gated visibility
- concise tooltips for chips and sparklines
- rich Fruit tooltips with color-aligned keywords
- the shortened `D` profile chip instead of a visible `DET` label

If the HUD changes again, this file should be updated alongside the widget and
engine code so the documentation stays implementation-first.
