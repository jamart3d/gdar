# Audio Reactivity Tuning Guide

**Project:** gdar_tv — Sheep screensaver  
**Current state:** FFT-based logo scaling, not matching beat well  
**Goal:** Logo scale locked to beat, foundation for future audio→visual mappings

---

## The problem

Raw FFT data averaged across too wide a frequency band smears the beat punch.  
The fix is two things: **target the right band** + **asymmetric smoothing**.

---

## Step 1 — Target the bass band

Beat energy (kick drum, snare, bass guitar) lives at 80–250 Hz.  
Everything else is noise for this purpose.

```dart
double getBassEnergy(List<double> fftData, int sampleRate) {
  final binHz   = sampleRate / fftData.length;
  final lowBin  = (80  / binHz).floor();
  final highBin = (250 / binHz).ceil();

  double sum = 0;
  for (int i = lowBin; i <= highBin; i++) {
    sum += fftData[i];
  }
  return sum / (highBin - lowBin); // normalized 0.0–1.0
}
```

---

## Step 2 — Asymmetric smoothing

Fast attack = jumps on the beat.  
Slow release = decays naturally instead of snapping back.  
This is what makes audio reactivity *feel* locked vs just technically correct.

```dart
class BassSmoothing {
  double _smoothed = 0;

  // Tune these two constants on device
  static const double attack  = 0.8;  // 0.0–1.0, higher = snappier rise
  static const double release = 0.15; // 0.0–1.0, lower  = longer tail

  double update(double rawBass) {
    _smoothed = rawBass > _smoothed
        ? rawBass * attack  + _smoothed * (1 - attack)
        : rawBass * release + _smoothed * (1 - release);
    return _smoothed;
  }

  double get value => _smoothed;
}
```

---

## Step 3 — Map to logo scale

```dart
// Keep scale range subtle — too much looks jittery
double get logoScale => 1.0 + bassSmoothing.value * 0.4; // 1.0x → 1.4x max
```

---

## Tuning constants on device

Adjust these two values while music is playing on the TV:

| Constant | Too low | Too high | Sweet spot |
|----------|---------|----------|------------|
| `attack` | Slow to respond, feels laggy | Jittery, no smoothing | 0.7–0.85 |
| `release` | Snaps back instantly | Stays up, never drops | 0.1–0.2 |

**Tuning process:**
1. Start with `attack = 0.8`, `release = 0.15`
2. Play a track with a clear kick drum
3. If scale feels laggy → increase attack toward 0.9
4. If scale feels jittery → decrease attack toward 0.7
5. If scale drops too fast → increase release toward 0.25
6. If scale never fully drops → decrease release toward 0.08

---

## Frequency band map (full picture)

Current phase only uses bass. Other bands are reserved for future visual mappings.

| Band | Range | Current use | Future use |
|------|-------|-------------|------------|
| Sub-bass | 20–80 Hz | — | Forge2D gravity pulse |
| **Bass** | **80–250 Hz** | **Logo scale** | Genome mutation trigger |
| Mids | 250 Hz–2 kHz | — | Trail color hue shift |
| Highs | 2–20 kHz | — | Trail length, particle burst |
| Beat onset | any | — | Trigger sheep evolution event |

---

## Beat onset detection (future)

When you're ready to trigger genome mutations on the beat, add this on top of the smoothed bass:

```dart
class BeatDetector {
  double _energy    = 0;
  double _threshold = 0;
  bool   _triggered = false;

  // Call each frame after BassSmoothing.update()
  bool update(double smoothedBass) {
    // Adaptive threshold — tracks average energy
    _threshold = _threshold * 0.95 + smoothedBass * 0.05;

    final isBeat = smoothedBass > _threshold * 1.5 && !_triggered;
    _triggered   = smoothedBass > _threshold * 1.2; // hysteresis — prevent double trigger
    return isBeat;
  }
}

// Usage
if (beatDetector.update(bassSmoothing.value)) {
  genomeEvolution.triggerMutation(); // Phase 3
}
```

---

## Quality level considerations

Audio processing is cheap — runs the same across all quality levels.  
No changes needed to `QualityConfig` for audio.

---

## Done when

- [ ] Logo visibly pulses on kick drum hits
- [ ] No jitter between beats
- [ ] Scale drops cleanly between beats — doesn't stay inflated
- [ ] Tested with at least two genres (electronic + something with live drums)
- [ ] `attack` and `release` constants confirmed on actual Google TV hardware

---

## 2026-03-21 audit corrections

This guide is only partially accurate now.

### What still holds up

- The instinct to keep logo scaling subtle is still correct.
- Fast-attack / slow-release behavior is still a good visual target for pulse
  feel.
- Real-device tuning is still mandatory for TV audio reactivity work.

### What is outdated

1. The document is describing a future-facing screensaver concept, not the
   current TV implementation.
   - It says `Sheep screensaver`.
   - Sheep may still be a valid future feature.
   - The current TV screensaver path in code is the Steal visualizer.

2. The current implementation is not "FFT-based logo scaling only".
   - The current pipeline includes:
     - native Android `VisualizerPlugin.kt`
     - `AudioEnergy`
     - `StealGame.beatPulse`
     - `StealBackground` continuous energy uniforms
     - `StealGraph` graph modes and `beat_debug`

3. "Target the bass band" is too narrow for the current TV hardware.
   - Current native code does not trust bass alone.
   - The active beat path is currently `MID`, with other parallel detector
     variants for bass, broad, all-band, EMA, and treble.
   - This is because some TV hardware reports weak sub-bass / bass bins.

4. The code no longer maps logo scale with a simple `1.0 + bass * 0.4`.
   - Current scale behavior is split across:
     - continuous selected-band scale in `StealGame.pulseScale`
     - discrete beat boost in `StealBackground` using `beatPulse` and
       `beatImpact`

5. Beat detection is no longer a future idea in this codebase.
   - A native beat detector already exists.
   - The real issue is that it is still weak and `beat_debug` is still partly
     diagnostic.

6. The "frequency map" and "genome mutation / Forge2D gravity pulse" notes read
   as future-feature design ideas, not current TV screensaver behavior.

### Corrected current-state summary

The current system is better described like this:

- graph rendering uses normalized and smoothed band energy
- logo motion and shader uniforms use selected-band continuous energy
- logo punch uses a separate boolean beat pulse path
- native beat detection currently runs multiple simple detector variants
- the final beat signal is still not reliable enough for production-quality beat
  locking

### Best way to use this guide now

Treat this file as an old design note, not a current implementation spec.

The parts worth carrying forward are:

- subtle scaling
- asymmetric visual pulse feel
- real-device tuning

The parts that should not be followed literally are:

- bass-only detector advice
- simple `logoScale = 1.0 + bass * 0.4` mapping
- "beat detection is future work"
- the old future-feature references

### Better next-step guidance

If this guide is kept, the modern replacement direction should be:

1. use a hybrid detector instead of bass-only logic
2. keep continuous energy and discrete beat impact as separate channels
3. tune `beatPulse` feel independently from graph smoothing
4. prefer real TV hardware and, eventually, PCM-based detection for timing
