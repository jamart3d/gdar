#version 460 core

// Precision for mobile/TV compatibility
precision mediump float;

#include <flutter/runtime_effect.glsl>

// Output
out vec4 fragColor;

// Uniforms - Screen
uniform vec2 uResolution;
uniform float uTime;

// Uniforms - Configuration
uniform float uViscosity;      // 0.0-1.0: Controls blob movement speed
uniform float uFlowSpeed;      // 0.0-2.0: Overall animation speed multiplier
uniform float uFilmGrain;      // 0.0-1.0: Film grain intensity
uniform float uPulseIntensity; // 0.0-1.0: Audio pulse strength
uniform float uHeatDrift;      // 0.0-1.0: Vertical drift for burn-in prevention

// Uniforms - Audio Energy
uniform float uBassEnergy;    // 0.0-1.0
uniform float uMidEnergy;     // 0.0-1.0
uniform float uTrebleEnergy;  // 0.0-1.0
uniform float uOverallEnergy; // 0.0-1.0

// Uniforms - Palette (RGB colors)
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uColor4;

// Uniforms - Metaball configuration
uniform float uMetaballCount;  // 4-10 metaballs
uniform float uVisualMode;    // 0=lava, 1=silk, 2=psychedelic, 3=steal
uniform float uPerformanceMode; // 0=off, 1=on (Google TV)
uniform sampler2D uTexture;   // For sprite-based modes

void main() {
    // 1. Resolution Check
    if (uResolution.x < 10.0 || uResolution.y < 10.0) {
        fragColor = vec4(1.0, 0.0, 0.0, 1.0); // RED: Bad resolution
        return;
    }
    
    // 2. Uniform/Mode Check - Output solid colors for modes
    if (abs(uVisualMode - 0.0) < 0.1) {
        fragColor = vec4(0.0, 0.0, 1.0, 1.0); // BLUE: Lava Lamp
        return;
    }
    if (abs(uVisualMode - 1.0) < 0.1) {
        fragColor = vec4(1.0, 1.0, 0.0, 1.0); // YELLOW: Silk
        return;
    }
    if (abs(uVisualMode - 3.0) < 0.1) {
        fragColor = vec4(0.0, 1.0, 0.0, 1.0); // GREEN: Steal Mode detected!
        return;
    }
    
    // 3. Fallthrough
    fragColor = vec4(0.5, 0.0, 0.5, 1.0); // PURPLE: Unknown Mode
}
