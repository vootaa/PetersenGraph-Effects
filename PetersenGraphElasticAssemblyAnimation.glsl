precision highp float;

float gTime = 0.;
const float PI = 3.14159265;

// Efficient rotation function
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

// Polar to Cartesian coordinate conversion
vec2 polar(float r, float a) {
    return vec2(r * cos(a), r * sin(a));
}

// Simplified noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Simplified spacetime warp
vec2 spacetimeWarp(vec2 p) {
    float dist = length(p);
    float ripple = sin(dist * 12.0 - gTime * 6.0) * 0.08;
    return p * (1.0 + ripple);
}

// Simplified neon glow
float balancedNeonGlow(float d, float width, float intensity) {
    return width / (abs(d) + width) * intensity;
}

// Elastic easing function for smooth bouncy animation
float elasticEaseOut(float t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    
    float p = 0.3;
    float a = 1.0;
    float s = p / 4.0;
    
    return a * pow(2.0, -10.0 * t) * sin((t - s) * (2.0 * PI) / p) + 1.0;
}

// Smooth step function for timing
float smoothProgress(float t, float start, float end) {
    if (t < start) return 0.0;
    if (t > end) return 1.0;
    
    float progress = (t - start) / (end - start);
    return smoothstep(0.0, 1.0, progress);
}

// Calculate elastic rotation angle for each part
float getElasticAngle(int partIndex, float time) {
    // Animation cycle duration (total time for one complete cycle)
    float cycleDuration = 8.0;
    
    // Time within current cycle
    float cycleTime = mod(time, cycleDuration);
    
    // Target angle for this part (72 degrees apart)
    float targetAngle = float(partIndex) * 72.0 * PI / 180.0;
    
    // Animation phases:
    // Phase 1 (0-2s): Parts animate in with elastic motion
    // Phase 2 (2-6s): Parts stay stable at target position (2/3 of cycle)
    // Phase 3 (6-8s): Brief transition to next cycle
    
    float animationStart = float(partIndex) * 0.2; // Stagger start times
    float animationEnd = animationStart + 2.0;     // Animation duration
    float stableStart = 2.0;                       // Stable phase start
    float stableEnd = 6.0;                         // Stable phase end
    
    if (cycleTime < stableStart) {
        // Animation phase - elastic motion
        float progress = smoothProgress(cycleTime, animationStart, animationEnd);
        float elasticProgress = elasticEaseOut(progress);
        
        // Add some overshoot and oscillation
        float overshoot = sin(progress * PI * 3.0) * (1.0 - progress) * 0.3;
        
        return targetAngle * (elasticProgress + overshoot);
    } else if (cycleTime < stableEnd) {
        // Stable phase - parts hold position
        return targetAngle;
    } else {
        // Transition phase - prepare for next cycle
        float transitionProgress = (cycleTime - stableEnd) / (cycleDuration - stableEnd);
        float smoothTransition = smoothstep(0.0, 1.0, transitionProgress);
        
        // Add slight breathing motion during transition
        float breathing = sin(transitionProgress * PI * 2.0) * 0.1;
        
        return targetAngle + breathing;
    }
}

// Fixed polygon distance field
float sdPolygon(vec2 p, vec2 vertices[7], int n) {
    float d = dot(p - vertices[0], p - vertices[0]);
    float s = 1.0;
    
    for(int i = 0, j = n - 1; i < n; j = i, i++) {
        vec2 e = vertices[j] - vertices[i];
        vec2 w = p - vertices[i];
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));
        
        bvec3 c = bvec3(p.y >= vertices[i].y, p.y < vertices[j].y, e.x * w.y > e.y * w.x);
        if(all(c) || all(not(c))) s *= -1.0;
    }
    
    return s * sqrt(d);
}

// Triangle distance field
float sdTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    vec2 vertices[7];
    vertices[0] = a; vertices[1] = b; vertices[2] = c;
    return sdPolygon(p, vertices, 3);
}

// Quadrilateral distance field
float sdQuad(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
    vec2 vertices[7];
    vertices[0] = a; vertices[1] = b; vertices[2] = c; vertices[3] = d;
    return sdPolygon(p, vertices, 4);
}

// Heptagon distance field
float sdHeptagon(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e, vec2 f, vec2 g) {
    vec2 vertices[7];
    vertices[0] = a; vertices[1] = b; vertices[2] = c; vertices[3] = d;
    vertices[4] = e; vertices[5] = f; vertices[6] = g;
    return sdPolygon(p, vertices, 7);
}

// Shrink shape to create gaps
float shrinkShape(float d, float amount) {
    return d + amount;
}

// 1/5 part of the Petersen graph
float petersenPart(vec2 p) {
    float scale = 2.0;
    p /= scale;
    
    float shrink = 0.005;
    
    // P1 Triangle
    vec2 p1a = polar(0.060, radians(36.0));
    vec2 p1b = polar(0.060, radians(324.0));
    vec2 p1c = polar(0.150, 0.0);
    float d1 = shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink);
    
    // P2 Heptagon
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    
    float d2 = shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink);
    
    // P3 Quadrilateral
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float d3 = shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink);
    
    // P4 Triangle
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float d4 = shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink);
    
    // P5 Quadrilateral
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float d5 = shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink);
    
    // P6 Triangle
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float d6 = shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink);
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Complete Petersen graph with elastic rotation
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Global slow rotation
    p *= rot(gTime * 0.02);
    
    // 5-fold rotational symmetry with elastic motion
    for(int i = 0; i < 5; i++) {
        // Get elastic angle for this part
        float elasticAngle = getElasticAngle(i, gTime);
        
        // Apply the elastic rotation
        vec2 rotP = p * rot(-elasticAngle);
        d = min(d, petersenPart(rotP));
    }
    
    return d;
}

// Simplified grid
float simpleCyberGrid(vec2 p) {
    float grid1 = abs(sin(p.x * 25.0)) * abs(sin(p.y * 25.0));
    grid1 = smoothstep(0.95, 1.0, grid1);
    
    // Simple data flow lines
    float dataLines = sin(p.x * 15.0 - gTime * 3.0);
    dataLines = smoothstep(0.95, 1.0, dataLines);
    
    return grid1 * 0.6 + dataLines * 0.2;
}

// Simplified scanlines
float balancedScanlines(vec2 p) {
    return sin(p.y * 120.0) * 0.02 + 0.98;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    gTime = iTime;

    // Apply simplified spacetime distortion
    vec2 warpedP = spacetimeWarp(p);
    float d = petersenGraph(warpedP);

    // Simplified background gradient
    vec3 col = mix(
        vec3(0.04, 0.01, 0.05), 
        vec3(0.09, 0.01, 0.08), 
        p.y * 0.2 + 0.5
    );

    // Simplified cityscape
    float cityHeight = 0.4 + sin(p.x * 8.0) * 0.03;
    float cityscape = smoothstep(0.0, 0.01, p.y + cityHeight);
    col = mix(col, vec3(0.10, 0.02, 0.08), 1.0 - cityscape);
    
    // Simplified city lights
    float cityLights = pow(noise(p * 30.0), 8.0) * (1.0 - cityscape);
    col += cityLights * vec3(1.0, 0.5, 0.2) * 0.15;
    
    // Simplified grid
    float grid = simpleCyberGrid(p);
    col += grid * vec3(0.7, 0.0, 0.5) * 0.12;
    
    // Simplified distortion visualization
    float warpVis = length(warpedP - p) * 8.0;
    col += warpVis * vec3(1.0, 0.0, 0.5) * 0.15;
    
    // Reduced neon glow layers (from 4 to 2)
    float neonInner = balancedNeonGlow(d, 0.01, 1.5);
    float neonOuter = balancedNeonGlow(d, 0.03, 0.6);
    
    col += neonInner * vec3(1.0, 0.0, 0.6);
    col += neonOuter * vec3(0.6, 0.0, 0.5);
    
    // Simplified chromatic aberration (reduced from 3 to 2 samples)
    vec3 rgbSplit = vec3(0.0);
    for(int i = 0; i < 2; i++) {
        float offset = float(i) * 0.0015;
        vec2 chromaP = warpedP + vec2(offset, -offset);
        float chromaD = petersenGraph(chromaP);

        float edge = smoothstep(0.005, 0.0, abs(chromaD));
        
        vec3 spectrumColor = (i == 0) ? vec3(1.0, 0.0, 0.0) : vec3(0.8, 0.0, 0.8);
        
        rgbSplit += edge * spectrumColor * 0.5;
    }
    
    col += rgbSplit;
    
    // Main edge
    float edge = smoothstep(0.005, 0.0, abs(d));
    col += edge * vec3(1.0, 0.7, 0.9) * 0.6;
    
    // Simplified fill
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.12, 0.02, 0.10);
    
    // Simplified circuit pattern
    float circuit = step(0.7, noise(warpedP * 25.0));
    fillColor += circuit * vec3(0.3, 0.0, 0.2) * 0.2;
    
    col += solid * fillColor;
    
    // Reduced sparks intensity
    float sparks = pow(noise(warpedP * 40.0 + gTime), 18.0) * 2.0;
    col += sparks * vec3(1.0, 0.8, 0.2) * 0.2;
    
    // Simplified scanlines
    col *= balancedScanlines(fragCoord);
    
    // Simplified vignette
    float vignette = 1.0 - length(p) * 0.3;
    col *= clamp(vignette, 0.0, 1.0);
    
    // Simplified color grading
    col = pow(col, vec3(0.85));
    col *= 1.4;

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Elastic Assembly Animation",
    "description": "Parts elastically animate into position with 2/3 stable time",
    "model": "plane"
}
*/