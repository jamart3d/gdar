#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 uResolution;
uniform float uTime;

// Configuration
uniform float uFlowSpeed;
uniform float uFilmGrain;
uniform float uPulseIntensity;
uniform float uHeatDrift;

// Audio Energy
uniform float uBassEnergy;
uniform float uMidEnergy;
uniform float uTrebleEnergy;
uniform float uOverallEnergy;

// Palette
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uColor4;

uniform sampler2D uTexture;

vec3 getPaletteColor(float t) {
    t = fract(t);
    if (t < 0.33) {
        return mix(uColor1, uColor2, t * 3.0);
    } else if (t < 0.66) {
        return mix(uColor2, uColor3, (t - 0.33) * 3.0);
    } else {
        return mix(uColor3, uColor4, (t - 0.66) * 3.0);
    }
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 resolution = uResolution;
    if (resolution.x < 1.0 || resolution.y < 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 uv = FlutterFragCoord().xy / resolution;
    float aspect = resolution.x / resolution.y;

    // Background - Pure black for OLED safety
    vec3 bgColor = vec3(0.0);

    // Floating motion using Lissajous curve
    float t = uTime * uFlowSpeed * 0.5;
    vec2 pos = vec2(
        0.5 + 0.25 * sin(t * 1.3) + 0.1 * sin(t * 2.9),
        0.5 + 0.25 * cos(t * 1.7) + 0.1 * cos(t * 3.1)
    );

    // Audio reactivity for position (jitter)
    if (uOverallEnergy > 0.1) {
        pos += vec2(uBassEnergy - 0.5, uMidEnergy - 0.5) * 0.05 * uPulseIntensity;
    }

    // Sprite rendering
    vec2 centeredUV = uv - pos;
    centeredUV.x *= aspect; 

    // Scale/Size - Pulse with bass (Half size adjustment)
    float baseScale = 96.0 / resolution.y; 
    float scale = baseScale * (1.0 + uBassEnergy * 0.2 * uPulseIntensity);

    // Texture UVs
    vec2 texUV = centeredUV / scale + 0.5;

    vec4 texColor = vec4(0.0);

    // Check bounds
    if (texUV.x >= 0.01 && texUV.x <= 0.99 && texUV.y >= 0.01 && texUV.y <= 0.99) {
        // RGB Shift (Chromatic Aberration)
        float shift = 0.02 * (0.5 + uOverallEnergy * 2.0) * uPulseIntensity;

        float r = texture(uTexture, texUV + vec2(shift, 0.0)).r;
        float g = texture(uTexture, texUV).g;
        float b = texture(uTexture, texUV - vec2(shift, 0.0)).b;
        float a = texture(uTexture, texUV).a; 

        texColor = vec4(r, g, b, a);

        // Flash effect
        texColor.rgb += vec3(uTrebleEnergy) * 0.3 * uPulseIntensity;
    }

    // Color Cycling
    vec3 cycleColor = getPaletteColor(uTime * 0.2); 
    cycleColor = pow(cycleColor, vec3(0.6)); 
    cycleColor *= 2.0; 

    // Apply tint
    texColor.rgb = mix(texColor.rgb, texColor.rgb * cycleColor, 0.85);

    // Blend
    vec3 finalColor = mix(bgColor, texColor.rgb, texColor.a);

    // Film Grain
    if (uFilmGrain > 0.0) {
        float grain = (hash(uv * uTime) * 2.0 - 1.0) * uFilmGrain * 0.05;
        finalColor += vec3(grain);
    }

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
