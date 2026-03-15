#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2  uResolution;
uniform float uTime;

// Configuration
uniform float uFlowSpeed;
uniform float uFilmGrain;
uniform float uPulseIntensity;
uniform float uHeatDrift;
uniform float uLogoScale;
uniform float uBlurAmount;   // 0.0 = sharp, 1.0 = soft box blur
uniform float uFlatColor;    // 0.0 = animated cycling, 1.0 = static palette color
uniform float uAntiAlias;    // 0.0 = off, 1.0 = fwidth smoothstep AA on logo edge
uniform float uPerformanceLevel; // 0=High (36 spm), 1=Balanced (9 spm), 2=Fast (1 spm)

// Smoothed logo position (0–1 UV space) — computed & lerped in Dart, passed in.
// This replaces the old internal sin/cos computation so the shader and banner
// canvas always use the exact same position.
uniform float uLogoPosX;
uniform float uLogoPosY;

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

// Box blur: 3×3 grid of samples around UV
vec4 sampleBlurred(sampler2D tex, vec2 uv, float blurRadius) {
    if (blurRadius < 0.0001) return texture(tex, uv);
    vec4 col = vec4(0.0);
    float r = blurRadius;
    col += texture(tex, uv + vec2(-r, -r));
    col += texture(tex, uv + vec2( 0, -r));
    col += texture(tex, uv + vec2( r, -r));
    col += texture(tex, uv + vec2(-r,  0));
    col += texture(tex, uv               );
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

    float safeTime = max(uTime, 0.0);

    // Use smoothed position passed from Dart (StealBackground.update())
    vec2 pos = vec2(uLogoPosX, uLogoPosY);

    float pulse  = clamp(uPulseIntensity, 0.0, 2.0);
    float ebass  = clamp(uBassEnergy,     0.0, 2.0);
    float emid   = clamp(uMidEnergy,      0.0, 2.0);
    float eover  = clamp(uOverallEnergy,  0.0, 2.0);
    float etreble = clamp(uTrebleEnergy,  0.0, 2.0);

    // Audio nudge applied on top of smoothed pos
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
    float blurRadius = clamp(uBlurAmount, 0.0, 1.0) * 0.018;

    vec4 texColor;

    if (uPerformanceLevel > 1.5) {
        // Fast: 1 sample
        texColor = texture(uTexture, texUV);
    } else if (uPerformanceLevel > 0.5) {
        // Balanced: 9 samples
        texColor = sampleBlurred(uTexture, texUV, blurRadius);
    } else {
        // High: 36 samples (Chromatic Aberration + Blur)
        float r = sampleBlurred(uTexture, texUV + vec2(shift, 0.0), blurRadius).r;
        float g = sampleBlurred(uTexture, texUV,                    blurRadius).g;
        float b = sampleBlurred(uTexture, texUV - vec2(shift, 0.0), blurRadius).b;
        float a = sampleBlurred(uTexture, texUV,                    blurRadius).a;
        texColor = vec4(r, g, b, a);
    }

    // Anti-alias: smooth the logo edge using fwidth for sub-pixel crisp edges.
    // Only active when uAntiAlias > 0.5. Uses the raw center alpha (not blurred)
    // so the edge is always crisp regardless of the blur setting.
    if (uAntiAlias > 0.5) {
        float rawA = texColor.a; // Use the blurred alpha so AA doesn't fight blur
        float fw = fwidth(rawA) * 1.5 + 0.001;
        texColor.a = smoothstep(0.5 - fw, 0.5 + fw, rawA);
    }

    texColor.rgb += vec3(etreble) * 0.3 * pulse;

    vec3 cycleColor;
    if (uFlatColor > 0.5) {
        cycleColor = pow(clamp(uColor1, 0.0, 1.0), vec3(0.6)) * 2.0;
    } else {
        cycleColor = getPaletteColor(safeTime * 0.2);
        cycleColor = pow(clamp(cycleColor, 0.0, 1.0), vec3(0.6)) * 2.0;
    }

    texColor.rgb = mix(texColor.rgb, texColor.rgb * cycleColor, 0.85);

    vec3 finalColor = mix(vec3(0.0), texColor.rgb, clamp(texColor.a, 0.0, 1.0));

    float grainAmt = clamp(uFilmGrain, 0.0, 1.0);
    if (grainAmt > 0.0) {
        float grain = (hash(uv * (safeTime + 1.0)) * 2.0 - 1.0) * grainAmt * 0.05;
        finalColor += vec3(grain);
    }

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
