#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 uResolution;
uniform float uTime;

// Configuration
uniform float uFlowSpeed;
uniform float uFilmGrain;
uniform float uPulseIntensity;
uniform float uHeatDrift;
uniform float uLogoScale;
uniform float uBlurAmount;   // 0.0 = sharp, 1.0 = soft box blur
uniform float uFlatColor;    // 0.0 = animated cycling, 1.0 = static palette color

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
    vec3 c1 = clamp(uColor1, 0.0, 1.0);
    vec3 c2 = clamp(uColor2, 0.0, 1.0);
    vec3 c3 = clamp(uColor3, 0.0, 1.0);
    vec3 c4 = clamp(uColor4, 0.0, 1.0);
    if (t < 0.33) {
        return mix(c1, c2, t * 3.0);
    } else if (t < 0.66) {
        return mix(c2, c3, (t - 0.33) * 3.0);
    } else {
        return mix(c3, c4, (t - 0.66) * 3.0);
    }
}

// Box blur: samples texture at 8 surrounding offsets + center
vec4 sampleBlurred(sampler2D tex, vec2 uv, float blurRadius) {
    if (blurRadius < 0.0001) return texture(tex, uv);
    vec4 col = vec4(0.0);
    float r = blurRadius;
    col += texture(tex, uv + vec2(-r, -r));
    col += texture(tex, uv + vec2( 0, -r));
    col += texture(tex, uv + vec2( r, -r));
    col += texture(tex, uv + vec2(-r,  0));
    col += texture(tex, uv                );
    col += texture(tex, uv + vec2( r,  0));
    col += texture(tex, uv + vec2(-r,  r));
    col += texture(tex, uv + vec2( 0,  r));
    col += texture(tex, uv + vec2( r,  r));
    return col / 9.0;
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 resolution = uResolution;
    if (resolution.x < 2.0 || resolution.y < 2.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 uv = FlutterFragCoord().xy / resolution;
    float aspect = resolution.x / resolution.y;

    vec3 bgColor = vec3(0.0);

    float safeTime = max(uTime, 0.0);
    float t = safeTime * clamp(uFlowSpeed, 0.0, 2.0) * 0.5;

    vec2 pos = vec2(
        0.5 + 0.25 * sin(t * 1.3) + 0.1 * sin(t * 2.9),
        0.5 + 0.25 * cos(t * 1.7) + 0.1 * cos(t * 3.1)
    );

    float pulse = clamp(uPulseIntensity, 0.0, 2.0);
    float ebass = clamp(uBassEnergy, 0.0, 2.0);
    float emid = clamp(uMidEnergy, 0.0, 2.0);
    float eover = clamp(uOverallEnergy, 0.0, 2.0);
    float etreble = clamp(uTrebleEnergy, 0.0, 2.0);

    if (eover > 0.01) {
        pos += vec2(ebass - 0.5, emid - 0.5) * 0.05 * pulse;
    }

    vec2 centeredUV = uv - pos;
    centeredUV.x *= aspect;

    float safeLogoScale = clamp(uLogoScale, 0.05, 1.0);
    float baseScale = (110.0 / resolution.y) * safeLogoScale;
    float scale = baseScale * (1.0 + ebass * 0.2 * pulse);
    scale = max(scale, 0.001);

    vec2 texUV = centeredUV / scale + 0.5;

    float drift = clamp(uHeatDrift, 0.0, 2.0);
    if (drift > 0.01) {
        float wave  = sin(texUV.y * 10.0 + safeTime * 2.0) * 0.01 * drift;
        float wave2 = cos(texUV.x * 12.0 + safeTime * 1.5) * 0.01 * drift;
        texUV += vec2(wave, wave2);
    }

    float shift = 0.02 * (0.5 + eover * 2.0) * pulse;

    // Map blur 0–1 → UV offset 0–0.018 (≈18px at 1080p — soft but not mush)
    float blurRadius = clamp(uBlurAmount, 0.0, 1.0) * 0.018;

    float r = sampleBlurred(uTexture, texUV + vec2(shift, 0.0), blurRadius).r;
    float g = sampleBlurred(uTexture, texUV,                     blurRadius).g;
    float b = sampleBlurred(uTexture, texUV - vec2(shift, 0.0), blurRadius).b;
    float a = sampleBlurred(uTexture, texUV,                     blurRadius).a;

    vec4 texColor = vec4(r, g, b, a);
    texColor.rgb += vec3(etreble) * 0.3 * pulse;

    // Flat color mode: use uColor1 directly; animated mode: cycle through palette
    vec3 cycleColor;
    if (uFlatColor > 0.5) {
        // Static — just use the first palette color, boosted to match animated brightness
        cycleColor = clamp(uColor1, 0.0, 1.0);
        cycleColor = pow(cycleColor, vec3(0.6));
        cycleColor *= 2.0;
    } else {
        cycleColor = getPaletteColor(safeTime * 0.2);
        cycleColor = pow(clamp(cycleColor, 0.0, 1.0), vec3(0.6));
        cycleColor *= 2.0;
    }

    texColor.rgb = mix(texColor.rgb, texColor.rgb * cycleColor, 0.85);

    vec3 finalColor = mix(bgColor, texColor.rgb, clamp(texColor.a, 0.0, 1.0));

    float grainAmt = clamp(uFilmGrain, 0.0, 1.0);
    if (grainAmt > 0.0) {
        float grain = (hash(uv * (safeTime + 1.0)) * 2.0 - 1.0) * grainAmt * 0.05;
        finalColor += vec3(grain);
    }

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
