# TV Hardware Beat Tuning Checklist

Date: 2026-03-21

Use this during real-device testing of the TV screensaver beat detector.

## Setup

- [ ] Build and install the current TV app on hardware.
- [ ] Start playback with a track that has stable audible rhythm.
- [ ] Set audio graph mode to `beat_debug`.
- [ ] Let the detector warm up for `10-15` seconds before judging it.

## Track Pass

### 1. Kick-heavy studio track

- [ ] Test one kick-heavy studio track first.
- [ ] Pulses feel locked to the groove.
- [ ] No frequent missed beats.
- [ ] No obvious double-fires or machine-gun chatter.

Notes:

```text
Track:
Source:
Result:
Notes:
```

### 2. Live Grateful Dead track

- [ ] Test one live Dead track next.
- [ ] Detector follows groove better than vocals/guitar transients.
- [ ] No obvious drift during dense sections.
- [ ] No chatter during loud live passages.

Notes:

```text
Track:
Source:
Result:
Notes:
```

### 3. Quieter acoustic track

- [ ] Test one quieter acoustic track last.
- [ ] Detector still produces useful motion.
- [ ] Floor is not suppressing all meaningful beats.
- [ ] No false chatter in low-energy passages.

Notes:

```text
Track:
Source:
Result:
Notes:
```

## `beat_debug` Readout Checks

- [ ] `SCR` rises above `THR` cleanly on strong hits.
- [ ] `CNF` spikes on real hits instead of staying high constantly.
- [ ] `WIN` changes sensibly, but final pulse quality is more important than the winning label.
- [ ] If bars are active but beats do not fire, note possible threshold or floor issue.
- [ ] If beats chatter in dense passages, note possible floor or refractory issue.

## Settings Checks

### `beatSensitivity`

- [ ] Lower `beatSensitivity` once and observe trigger rate.
- [ ] Raise `beatSensitivity` once and observe trigger rate.
- [ ] Higher sensitivity increases triggers without making chatter unacceptable.

Notes:

```text
Lower setting:
Higher setting:
Effect:
```

### `bassBoost`

- [ ] Lower `bassBoost` once and observe visuals.
- [ ] Raise `bassBoost` once and observe visuals.
- [ ] Visual intensity changes more than beat timing.
- [ ] Beat frequency does not noticeably change with `bassBoost`.

Notes:

```text
Lower setting:
Higher setting:
Effect:
```

## Regression Checks

- [ ] `corner` still looks correct.
- [ ] `scope` still looks correct.
- [ ] `vu` still looks correct.
- [ ] `corner_only` still looks correct.
- [ ] If stereo capture is enabled, `ST` appears only when true stereo is active.

## Summary To Report Back

```text
Studio:
Live:
Acoustic:
Sensitivity:
BassBoost:
Regressions:
Overall verdict:
```
