# Screensaver Audio Reactivity & Configuration Manual

This document provides a comprehensive guide to the "Liquid Glass" screensaver engine and its deep configuration options as found in the GDAR TV UI.

---

## 1. Core Reactive Engine
The screensaver is not a simple animation loop; it is a real-time reactive engine driven by the full audio spectrum.

### Dynamic Motion (Lissajous)
The "Steal Your Face" logo follows a complex Lissajous path that never repeats identically between sessions. 
- **Beat Onset Detection**: Sharp spikes in scale (a 0.08 scaling jump) trigger on detected beats.
- **Bass Modulation**: Real-time Bass energy directly drives the logo's expansion/contraction.

### Background Shader (Liquid Glass)
The `steal.frag` fragment shader consumes audio uniforms:
- **uBass**: Drives the primary expansion of the glass ripples.
- **uMid/uTreble**: Modulates the "heat drift" and color shimmering frequency.
- **uOverall**: Increases global flow intensity and color vibrancy during busy passages.

---

## 2. Configuration Settings (TV UI Reference)

### **SYSTEM SECTION**
Controls the activation and lifecycle of the screensaver.
- **Prevent Sleep**: Prevents the TV from going into standby while music is playing.
- **Shakedown Screen Saver**: Master toggle for the Steal Your Face visual effect.
- **Inactivity Timeout**: Choices of **1 min**, **5 min**, or **15 min** before automatic activation.
- **Start Screen Saver**: Manual trigger to test your current visual configuration.

### **VISUAL SECTION**
Fine-tune the appearance of the logo and its motion trails.
- **Color Palette**: Choose from several high-intensity, animated RGB color schemes.
- **Flat Color Mode**: Disables color animation, locking to the primary palette color.
- **Auto Palette Cycle**: Automatically rotates through different palettes every 20-40 seconds.
- **Logo Scale**: Adjusts the base size of the logo from **Small (10%)** to **Full (100%)**.
- **Trail Intensity**: Controls the transparency of the "ghost" motion trails (**Off** to **Strong**).
- **Dynamic Trails**: Automatically adjusts trail quality/count based on the logo's current velocity.
- **Trail Slices**: Number of ghost copies (**2** to **16**). At high levels, this creates a "liquid" effect.
- **Trail Spread**: Controls the temporal distance between slices (**Tight** to **Long**).
- **Trail Initial Scale**: Starting size of the first ghost slice (**50%** to **200%**).
- **Trail Decay Scale**: How much ghost slices shrink as they age (**1:1** to **Tapered**).
- **Logo Blur**: Applies a soft focus to the logo edges for a more ethereal look (**Sharp** to **Soft**).
- **Motion Smoothing**: Damping factor for movement (**Crisp** to **Ultra-Smooth**).
- **Flow Speed**: Global animation rate for the shader liquid (**Slow** to **Fast**).
- **Pulse Intensity**: Strength of the audio-reactive scaling (**Subtle** to **Strong**).
- **Heat Drift**: Amount of wavy distortion in the background ripples (**Still** to **Wavy**).

### **TRACK INFO SECTION**
Configure the display of Track Title, Venue, and Date.
- **Show Track Info**: Toggle visibility of current playback metadata.
- **Display Style**: 
  - **Ring**: Three rotating text rings orbiting the logo.
  - **Flat**: Three stacked vertical lines centered relative to the logo.
- **Banner Font**: Choose between **Rock Salt** (Handwritten) or **Roboto** (Clean).
- **Text Resolution**: Ratios from **1.0x (Native)** to **4.0x (Ultra)**. Higher resolution prevents blur during motion.
- **Letter/Word Spacing**: Global controls to adjust text density.
- **Orbit Settings (Ring Only)**:
  - **Inner Ring Size**: Radius of the date ring.
  - **Title/Venue Gaps**: Spacing between the three concentric rings.
  - **Orbit Drift**: Amount the rings swing away from the center (**Centered** to **Wide**).
- **Placement Settings (Flat Only)**:
  - **Text Placement**: Position text block **Above** or **Below** the logo.
  - **Text Proximity**: Distance from the logo center (**Away** to **On Logo**).
- **Neon Aesthetics**:
  - **Neon Glow**: Applies a multi-layer colored glow to every letter.
  - **Flicker**: Rhythmic "buzzing" and brightness drops mimicking a real neon sign.
  - **Glow Blur**: The thickness of the neon light bleed (**Tight** to **Wide**).

### **AUDIO REACTIVITY SECTION**
Configure how the engine listens to your music.
- **Enable Audio Reactivity**: Taps into the system audio output for FFT analysis.
- **Reactivity Strength**: Global multiplier for all reactive effects (**Subtle** to **Wild**).
- **Bass Boost**: Amplifies low-end frequencies for more aggressive logo pulsing.
- **Peak Decay**: How fast the system resets its "loudest point." 
  - **Fast**: Visuals stay active even during quiet instrumental passages.
  - **Slow**: Keeps a "high bar" so only the loud sections trigger maximum movement.
- **Beat Sensitivity**: Threshold for kick/snare detection (**Gentle** to **Aggressive**).
- **Audio Graph**: Displays a real-time EQ.
  - **Off**: Minimal visual load.
  - **Corner**: 8-bar spectral analyzer in the bottom-left corner.
  - **Circular**: 8 radial bars emanating directly from the logo.

### **PERFORMANCE SECTION**
Optimize the engine for your hardware.
- **Rendering Quality**:
  - **High**: Spectral chromatic aberration + high-accuracy ghost blur.
  - **Balanced**: Standard box blurs and smooth movement.
  - **Fast**: Sharp edges, 1-sample minimal GPU load.
- **Logo Anti-Aliasing**: Smooths the logo edges using sub-pixel precision (Can be heavy at 4K).
