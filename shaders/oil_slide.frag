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

// Constants
const int MAX_METABALLS = 10;  // Reduced from 15 for performance
const float BLOB_BASE_RADIUS = 0.17; // Reduced from 0.22 per user feedback ("too large")
const float METABALL_THRESHOLD = 1.0;

// Simple hash function for pseudo-random values
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // Smoothstep
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for organic movement
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    int maxOctaves = (uPerformanceMode == 1.0) ? 2 : 4;
    for (int i = 0; i < 4; i++) {
        if (i >= maxOctaves) break;
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Calculate blob position with organic movement
vec2 getBlobPosition(int index, float time) {
    float t = time * uFlowSpeed;
    float indexFloat = float(index);
    
    // Base circular motion
    float angle = t * 0.3 + indexFloat * 6.28318 / uMetaballCount;
    float radius = 0.25 + 0.15 * sin(t * 0.5 + indexFloat);
    
    // Add noise-based organic movement
    vec2 noiseOffset = vec2(
        fbm(vec2(t * 0.2 + indexFloat, indexFloat * 2.0)) - 0.5,
        fbm(vec2(indexFloat * 2.0, t * 0.2 + indexFloat)) - 0.5
    ) * 0.2;
    
    // Audio reactivity - bass affects horizontal, mid affects vertical
    vec2 audioOffset = vec2(
        (uBassEnergy - 0.5) * 0.1,
        (uMidEnergy - 0.5) * 0.1
    );
    
    // Heat drift for OLED burn-in prevention
    float drift = sin(t * 0.1) * uHeatDrift * 0.05;
    
    // Lava Lamp Mode: Vertical Convection
    if (uVisualMode == 0.0) {
        // Slowed down by 1/3 (0.2 -> 0.13) as requested
        float cycle = t * 0.13 + indexFloat * 1.5;
        // Rising and falling motion (sine wave)
        // Add secondary frequency for dynamic clustering
        float vertical = 0.5 + 0.5 * sin(cycle) + 0.15 * sin(cycle * 2.3 + indexFloat); 
        
        // Horizontal drift with noise
        float horizontal = 0.5 + (fbm(vec2(t * 0.1, indexFloat * 5.0)) - 0.5) * 0.4;
        
        // Audio reactivity affects horizontal spread
        horizontal += (uBassEnergy - 0.5) * 0.1;
        
        vec2 pos = vec2(horizontal, vertical);
        return pos;
    }

    vec2 pos = vec2(
        0.5 + cos(angle) * radius + noiseOffset.x + audioOffset.x,
        0.5 + sin(angle) * radius + noiseOffset.y + audioOffset.y + drift
    );
    
    return pos;
}

// Calculate blob radius with audio pulsing
float getBlobRadius(int index, float time) {
    float t = time * uFlowSpeed;
    float indexFloat = float(index);
    
    // Base radius with slow pulsing
    float baseRadius = BLOB_BASE_RADIUS * (1.0 + 0.2 * sin(t + indexFloat * 2.0));
    
    // Audio pulse - different blobs react to different frequencies
    float audioPulse = 0.0;
    if (index < 2) {
        audioPulse = uBassEnergy * uPulseIntensity;
    } else if (index < 4) {
        audioPulse = uMidEnergy * uPulseIntensity;
    } else {
        audioPulse = uTrebleEnergy * uPulseIntensity;
    }
    
    // Viscosity affects pulse responsiveness
    float pulseAmount = mix(0.3, 0.1, uViscosity);
    
    return baseRadius * (1.0 + audioPulse * pulseAmount);
}

// Metaball field calculation
float metaballField(vec2 uv, float time) {
    float field = 0.0;
    
    for (int i = 0; i < MAX_METABALLS; i++) {
        if (float(i) >= uMetaballCount) break;  // Only process active metaballs
        
        vec2 blobPos = getBlobPosition(i, time);
        float blobRadius = getBlobRadius(i, time);
        
        // Lava Lamp: Scale radius based on height (smaller at top)
        if (uVisualMode == 0.0) {
            // y=0 is top, y=1 is bottom. 
            // Scale from 0.5 (top) to 1.1 (bottom)
            float heightScale = 0.5 + 0.6 * clamp(blobPos.y, 0.0, 1.0);
            blobRadius *= heightScale;
        }
        
        float dist = distance(uv, blobPos);
        field += (blobRadius * blobRadius) / (dist * dist + 0.001);
    }
    
    return field;
}

// Get color from palette based on field value
vec3 getPaletteColor(float t) {
    t = fract(t); // Wrap to 0-1
    
    if (t < 0.33) {
        return mix(uColor1, uColor2, t * 3.0);
    } else if (t < 0.66) {
        return mix(uColor2, uColor3, (t - 0.33) * 3.0);
    } else {
        return mix(uColor3, uColor4, (t - 0.66) * 3.0);
    }
}

// Film grain effect
float filmGrain(vec2 uv, float time) {
    return hash(uv * time) * 2.0 - 1.0;
}

// Calculate normal from metaball field gradient
vec3 getMetaballNormal(vec2 uv, float time) {
    if (uPerformanceMode == 1.0) {
        // Cheaper numeric gradient with single side lookup
        float v = metaballField(uv, time);
        float vx = metaballField(uv + vec2(0.02, 0.0), time) - v;
        float vy = metaballField(uv + vec2(0.0, 0.02), time) - v;
        return normalize(vec3(-vx, -vy, 0.02));
    }
    vec2 e = vec2(0.01, 0.0);
    float v = metaballField(uv, time);
    float vx = metaballField(uv + e.xy, time) - metaballField(uv - e.xy, time);
    float vy = metaballField(uv + e.yx, time) - metaballField(uv - e.yx, time);
    return normalize(vec3(-vx, -vy, e.x)); // Approximation
}

// Bottle SDF (Conical Frustum)
float sdBottle(vec2 p, float centerX) {
    // Center the bottle
    p.x -= centerX;
    
    // Bottle dimensions
    // y=0 is top, y=1 is bottom in typical Flutter shader coords
    float rTop = 0.15;    // Narrow top
    float rBottom = 0.40; // Wide bottom
    
    // Vertical limits (Expanded slightly to fill more vertical space if needed, or keep 0.1-0.9)
    float y = p.y;
    // Removing strict vertical clip to let it flow off screen or just keep it contained?
    // User said "dont need top and base", usually implies infinite look or just glass.
    // Let's keep the vertical bounds for the "bottle" feel but remove the caps logic.
    if (y < 0.05 || y > 0.95) return 1.0; 
    
    // Horizontal limits (Conical interpolation)
    // Map y from 0.05..0.95 to 0..1 for radius mixing
    float t = (y - 0.05) / 0.9;
    float r = mix(rTop, rBottom, t);
    
    return abs(p.x) - r;
}

// Silk Height Map (Fabric Simulation)
float silkHeight(vec2 uv, float time) {
    float t = time * 0.5;
    
    // Large folds
    float h = sin(uv.x * 4.0 + t) * 0.5 + sin(uv.y * 3.0 - t * 0.7) * 0.5;
    
    // Medium details (diagonal folds)
    h += sin((uv.x + uv.y) * 8.0 + t * 1.5) * 0.2;
    
    // Small ripples (wind/turbulence) - Skip in performance mode
    if (uPerformanceMode == 0.0) {
        h += fbm(uv * 10.0 + vec2(t)) * 0.05 * uBassEnergy; // Audio reactivity
    }
    
    return h * 0.5 + 0.5;
}

// Silk Normal
vec3 getSilkNormal(vec2 uv, float time) {
    vec2 e = vec2(0.005, 0.0);
    float v = silkHeight(uv, time);
    float vx = silkHeight(uv + e.xy, time) - silkHeight(uv - e.xy, time);
    float vy = silkHeight(uv + e.yx, time) - silkHeight(uv - e.yx, time);
    return normalize(vec3(-vx * 2.0, -vy * 2.0, e.x)); // Exaggerate normal for sheen
}

void main() {
    // Normalize coordinates to 0-1
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Adjust aspect ratio for shape calculations
    float aspect = uResolution.x / uResolution.y;
    // We work in aspect-corrected coordinates for shapes and normals
    vec2 aspectUV = uv;
    aspectUV.x *= aspect;
    
    // ---------------------------------------------------------
    // Mode 1: High Fidelity Silk (Fabric Simulation)
    // ---------------------------------------------------------
    // ---------------------------------------------------------
    // Mode 3: Steal Your Face (Floating Sprite with RGB effects)
    // ---------------------------------------------------------
    if (uVisualMode == 3.0) {
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
        // Correct for aspect ratio to keep image square
        vec2 centeredUV = uv - pos;
        centeredUV.x *= aspect; 
        
        // Scale/Size - Pulse with bass (Half size of original 192x192)
        float baseScale = 96.0 / uResolution.y; 
        float scale = baseScale * (1.0 + uBassEnergy * 0.2 * uPulseIntensity);
        
        // Texture UVs
        // centeredUV is (-scale/2, scale/2). Map to (0, 1).
        vec2 texUV = centeredUV / scale + 0.5;
        
        vec4 texColor = vec4(0.0);
        
        // Check bounds (0.0 to 1.0)
        if (texUV.x >= 0.01 && texUV.x <= 0.99 && texUV.y >= 0.01 && texUV.y <= 0.99) {
           // RGB Shift (Chromatic Aberration) based on energy
           float shift = 0.02 * (0.5 + uOverallEnergy * 2.0) * uPulseIntensity;
           
           // Sample texture channels with offsets
           float r = texture(uTexture, texUV + vec2(shift, 0.0)).r;
           float g = texture(uTexture, texUV).g;
           float b = texture(uTexture, texUV - vec2(shift, 0.0)).b;
           float a = texture(uTexture, texUV).a; 
           
           texColor = vec4(r, g, b, a);
           
           // Flash effect on high energy
           texColor.rgb += vec3(uTrebleEnergy) * 0.3 * uPulseIntensity;
        }
        
        // Simple radial gradient background - REMOVED for OLED safety
        
        // Color Cycling for Texture
        // Get a color from the current palette based on time
        vec3 cycleColor = getPaletteColor(uTime * 0.2); 
        
        // Gamma Color Trick: 
        // Applying non-linear boost to make colors feel "electric" and avoid washing out
        cycleColor = pow(cycleColor, vec3(0.6)); 
        cycleColor *= 2.0; // Restoring intensity after gamma crunch
        
        // Apply tint to the texture
        // Mix original color with tinted version to preserve some detail
        texColor.rgb = mix(texColor.rgb, texColor.rgb * cycleColor, 0.85);

        // Blend texture over background
        vec3 finalColor = mix(bgColor, texColor.rgb, texColor.a);
        
        fragColor = vec4(finalColor, 1.0);
        return;
    }

    // ---------------------------------------------------------
    // Mode 1: High Fidelity Silk (Fabric Simulation)
    // ---------------------------------------------------------
    if (uVisualMode == 1.0) {
        vec3 normal = getSilkNormal(aspectUV, uTime);
        float height = silkHeight(aspectUV, uTime);
        
        // Lighting
        vec3 lightDir = normalize(vec3(0.5, 0.5, 1.0));
        vec3 viewDir = vec3(0.0, 0.0, 1.0);
        vec3 halfDir = normalize(lightDir + viewDir);
        
        // Anisotropic Specular (simulated by stretching)
        // Shift tangent based on height to follow folds
        vec3 tangent = normalize(vec3(1.0, 0.2 * sin(aspectUV.x * 10.0 + height * 10.0), 0.0));
        float dotTH = dot(tangent, halfDir);
        float sinTH = sqrt(1.0 - dotTH * dotTH);
        float dirAtten = smoothstep(-1.0, 0.0, dotTH); 
        float spec = pow(sinTH, 40.0) * dirAtten; // Kajiya-Kay approximation
        
        // Standard Blinn-Phong for general gloss
        float blinn = pow(max(dot(normal, halfDir), 0.0), 16.0);
        
        // Base Color from palette (Champagne)
        vec3 baseColor = mix(uColor4, uColor1, height); // Dark to Light
        
        // Combine Light
        vec3 ambient = baseColor * 0.2;
        vec3 diffuse = baseColor * max(dot(normal, lightDir), 0.0) * 0.5;
        vec3 specular = uColor2 * (spec * 0.8 + blinn * 0.4); // Silver highlights
        
        // Fresnel/Rim for velvety feel
        float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 3.0);
        vec3 rim = uColor1 * fresnel * 0.4;

        vec3 finalColor = ambient + diffuse + specular + rim;
        
        // Film Grain
        if (uFilmGrain > 0.0) {
            float grain = filmGrain(aspectUV, uTime) * uFilmGrain * 0.05;
            finalColor += vec3(grain);
        }

        fragColor = vec4(finalColor, 1.0);
        return;
    }

    // Calculate metaball field (Only for Lava Lamp and Standard modes)
    // Use aspectUV for correct shape distortion
    float field = metaballField(aspectUV, uTime);
    
    // Determine if we're inside a blob
    float blobMask = smoothstep(METABALL_THRESHOLD - 0.1, METABALL_THRESHOLD + 0.1, field);
    
    // Color based on field strength and audio energy
    float colorPhase = field * 0.3 + uTime * 0.1 + uOverallEnergy * 0.2;
    vec3 blobColor = getPaletteColor(colorPhase);
    
    // Background color (very dark, almost black)
    vec3 bgColor = vec3(0.02, 0.02, 0.03);
    
    // Lava Lamp Specific Effects
    if (uVisualMode == 0.0) {
        // High Fidelity Lava Lamp
        
        // 1. Bottle Shape Mask
        // Center of screen in aspect coords is aspect * 0.5
        float centerX = aspect * 0.5;
        float bottleDist = sdBottle(aspectUV, centerX);
        float bottleMask = 1.0 - smoothstep(0.0, 0.01, bottleDist);
        
        // 2. Background (Inside Bottle) -> INVISIBLE now
        // Use standard background color instead of colored bottle background
        vec3 bottleBg = bgColor; 
        
        // 3. Blobs with 3D Shading
        // STRICT CLIPPING: Blobs must strictly be inside the bottle.
        // bottleDist < 0 inside.
        // We use a sharp step for strict clipping, or a very tight smoothstep.
        float strictClip = 1.0 - smoothstep(0.0, 0.001, bottleDist);
        
        if (blobMask > 0.01) {
            vec3 normal = getMetaballNormal(aspectUV, uTime);
            
            // Lighting vectors
            // Light from BOTTOM (y=1.2) to match real lava lamp base light
            vec3 lightPos = vec3(centerX, 1.2, 0.5); 
            vec3 viewDir = vec3(0.0, 0.0, 1.0);
            vec3 lightDir = normalize(lightPos - vec3(aspectUV, 0.0));
            
            // Diffuse (Lambert)
            float diff = max(dot(normal, lightDir), 0.0);
            
            // Specular (Blinn-Phong)
            vec3 halfDir = normalize(lightDir + viewDir);
            float spec = pow(max(dot(normal, halfDir), 0.0), 32.0);
            
            // Fresnel (Rim)
            float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 2.0);
            
            // Combine lighting
            vec3 ambient = uColor2 * 0.3;
            
            // Waxy Gradient:
            // Hotter (brighter/yellower - uColor3) at bottom, Cooler (redder/darker - uColor2) at top.
            // aspectUV.y is 0 at top, >1 at bottom (depending on aspect).
            // Let's map 0.0-1.0 to the gradient.
            vec3 blobBaseColor = mix(uColor2, uColor3, smoothstep(0.0, 1.2, aspectUV.y));
            
            // Attenuate diffuse based on height (brighter at bottom)
            float heightAtten = smoothstep(0.0, 1.0, aspectUV.y);
            vec3 diffuse = blobBaseColor * diff * (0.6 + 0.6 * heightAtten); // Boosted diffuse
            
            vec3 specular = vec3(1.0, 1.0, 0.8) * spec * 0.8;
            vec3 rim = uColor4 * fresnel * 0.5;
            
            vec3 shadedBlob = ambient + diffuse + specular + rim;
            
            // Mix blob into bottle background
            // Apply strict clipping to the blob contribution
            bottleBg = mix(bottleBg, shadedBlob, blobMask * strictClip);
        }
        
        // 4. Glass Interaction Glow
        // Show glass boundary ONLY where blobs are near/touching it
        // bottleDist is 0 at boundary.
        // field is high near blobs.
        // Edge softness 0.005 as requested (bit softer than 0.002, sharper than 0.01)
        float interaction = smoothstep(0.005, 0.0, abs(bottleDist)); 
        interaction *= smoothstep(0.1, 0.8, field); // Close to blob (field strength)
        
        // Vertical Gradient: Glow is bright at bottom, fades at top
        float verticalGlow = smoothstep(0.1, 0.9, aspectUV.y);
        
        // Less glow (0.4) combined with vertical gradient
        vec3 interactionColor = uColor3 * 0.4 * verticalGlow; 
        
        // Composite
        // We clip the blobs with bottleMask (which controls the main "shape" anti-aliasing)
        // strictClip handled internal blob bleeding.
        vec3 finalColor = mix(bgColor, bottleBg, bottleMask);
        
        // Add interaction glow on top of border
        finalColor += interactionColor * interaction;

        fragColor = vec4(finalColor, 1.0);
        return;
    } 

    // Add brightness variation based on field strength
    float brightness = smoothstep(0.5, 2.0, field);
    blobColor *= 0.6 + brightness * 0.4;

    // Mix blob and background
    vec3 color = mix(bgColor, blobColor, blobMask);
    
    // Silk visual mode...
    // Add subtle edge glow
    float edgeGlow = smoothstep(0.0, 0.3, blobMask) * (1.0 - blobMask);
    color += blobColor * edgeGlow * 0.3;
    
    // Apply film grain
    if (uFilmGrain > 0.0) {
        float grain = filmGrain(uv, uTime) * uFilmGrain * 0.05;
        color += vec3(grain);
    }
    
    // Audio flash effect on high energy
    if (uOverallEnergy > 0.8) {
        float flash = (uOverallEnergy - 0.8) * 5.0;
        color += blobColor * flash * 0.1;
    }
    
    // Output
    fragColor = vec4(color, 1.0);
}
