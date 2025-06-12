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

// Enhanced noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Circuit pattern with 3D depth
float balancedCircuitPattern(vec2 p, float d) {
    // Base circuit traces with stable pattern
    float circuit = noise(p * 30.0 + gTime * 0.2);
    circuit = step(0.65, circuit);
    
    // Slow data pulses
    float pulse = sin(p.x * 20.0 + p.y * 20.0 - gTime * 3.0) * 0.5 + 0.5;
    pulse *= circuit;
    pulse = smoothstep(0.8, 1.0, pulse);
    
    // Connection nodes
    float nodes = sin(p.x * 15.0) * sin(p.y * 15.0);
    nodes = smoothstep(0.9, 1.0, nodes);
    
    return circuit * 0.6 + pulse * 0.4 + nodes * 0.2;
}

// 3D scaling effect with z-axis movement
vec2 apply3DEffect(vec2 p) {
    // Create z-axis oscillation
    float zDepth = sin(gTime * 0.5) * 0.5 + 0.5; // 0.0 to 1.0 oscillation
    
    // Scale factor based on perceived z-depth
    float scaleFactor = mix(0.7, 1.3, zDepth); // Scale between 70% and 130%
    
    // Center position shift for 3D movement illusion
    vec2 center = vec2(0.0);
    vec2 displacement = (p - center) * (scaleFactor - 1.0);
    
    // Apply 3D-like perspective scaling
    p = center + (p - center) * scaleFactor;
    
    return p;
}

// Balanced digital glitch effect (subtle, non-flashy)
vec2 balancedGlitch(vec2 p) {
    // Time-varying glitch strength (smoother transition)
    float glitchStrength = smoothstep(0.7, 0.9, sin(gTime * 1.5) * 0.5 + 0.5);
    
    // Subtle horizontal scan lines
    float scanGlitch = noise(vec2(floor(p.y * 15.0), gTime * 0.5)) * 0.015;
    p.x += scanGlitch * glitchStrength;
    
    // Very subtle signal interference (stable)
    float interference = sin(p.y * 80.0 + gTime * 20.0) * 0.001;
    p.x += interference * glitchStrength;
    
    return p;
}

// Subtle scanline effect (stable, non-flashy)
float balancedScanlines(vec2 p) {
    // Consistent scanlines with reduced intensity
    float scan = sin(p.y * 120.0) * 0.03 + 0.97;
    
    // Very subtle drift (no harsh transitions)
    float drift = sin(gTime * 0.2) * 0.01 + 0.99;
    
    return scan * drift;
}

// Stable neon glow with smooth pulsation
float balancedNeonGlow(float d, float width, float intensity, float time) {
    // Base neon glow
    float glow = width / (abs(d) + width) * intensity;
    
    // Gentle energy pulsation (very slow and subtle)
    float pulse = sin(time * 0.8) * 0.1 + 0.9;
    
    return glow * pulse;
}

// 3D depth effect for neon glow
float depthEnhancedNeonGlow(float d, float width, float intensity, float time, float depth) {
    float glow = balancedNeonGlow(d, width, intensity, time);
    
    // Enhance glow based on depth (closer objects glow more intensely)
    float depthFactor = mix(0.8, 1.2, depth);
    
    return glow * depthFactor;
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
        
        // Improved inside/outside determination
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

// Subtle shape distortion (stable, non-flashy)
float subtleDistortShape(float d, vec2 p) {
    // Very gentle distortion based on position
    float distortion = sin(p.x * 30.0 + gTime * 1.0) * sin(p.y * 30.0 - gTime * 0.8) * 0.001;
    return d + distortion;
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
    
    // P1 Triangle: {(0.060,36),(0.060,324),(0.150,0)}
    vec2 p1a = polar(0.060, radians(36.0));
    vec2 p1b = polar(0.060, radians(324.0));
    vec2 p1c = polar(0.150, 0.0);
    float d1 = subtleDistortShape(shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink), p);
    
    // P2 Heptagon: {(0.060,36),(0.150,0),(0.300,0),(0.390,6),(0.390,66),(0.300,72),(0.150,72)}
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    
    float d2 = subtleDistortShape(shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink), p);
    
    // P3 Quadrilateral: {(0.300,0),(0.390,354),(0.416,0),(0.390,6)}
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float d3 = subtleDistortShape(shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink), p);
    
    // P4 Triangle: {(0.390,6),(0.416,0),(0.480,10)}
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float d4 = subtleDistortShape(shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink), p);
    
    // P5 Quadrilateral: {(0.390,6),(0.480,10),(0.480,62),(0.390,66)}
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float d5 = subtleDistortShape(shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink), p);
    
    // P6 Triangle: {(0.390,66),(0.480,62),(0.416,72)}
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float d6 = subtleDistortShape(shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink), p);
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Complete Petersen graph (5-fold symmetry) with 3D effect
float petersenGraph(vec2 p, float zDepth) {
    float d = 1e6;
    
    // Smooth rotation (constant speed, no direction changes)
    float rotSpeed = 0.10;
    p *= rot(gTime * rotSpeed);
    
    // 5-fold rotational symmetry
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * 72.0 * PI / 180.0;
        vec2 rotP = p * rot(-angle);
        d = min(d, petersenPart(rotP));
    }
    
    return d;
}

// Balanced cyberpunk grid (stable, non-flashy) with 3D depth
float balancedCyberGrid(vec2 p, float depth) {
    // Main grid layer (stable)
    float grid1 = abs(sin(p.x * 30.0)) * abs(sin(p.y * 30.0));
    grid1 = smoothstep(0.93, 1.0, grid1);
    
    // Subtle hexagonal grid
    float hexGrid = 0.0;
    for(int i = 0; i < 3; i++) {
        float angle = float(i) * PI / 3.0;
        vec2 dir = vec2(cos(angle), sin(angle));
        hexGrid += abs(sin(dot(p, dir) * 30.0));
    }
    hexGrid = smoothstep(2.7, 2.8, hexGrid);
    
    // Gentle data flow lines (slow, stable movement)
    float dataLines = sin(p.x * 20.0 + p.y * 10.0 - gTime * 5.0);
    dataLines = smoothstep(0.9, 1.0, dataLines);
    
    // Depth-adjusted intensity (grid fades when object moves away)
    float depthFactor = mix(0.5, 1.0, depth);
    
    return (grid1 * 0.6 + hexGrid * 0.2 + dataLines * 0.1) * depthFactor;
}

// 3D shadow effect
float shadow3D(vec2 p, float d, float depth) {
    // Shadow offset based on depth
    float shadowOffset = mix(0.01, 0.03, depth);
    
    // Shadow direction based on light source
    vec2 shadowDir = vec2(0.03, 0.03);
    
    // Sample distance at shadow position
    vec2 shadowPos = p + shadowDir * shadowOffset;
    float shadowD = petersenGraph(shadowPos, depth);
    
    // Create soft shadow
    float shadowStrength = smoothstep(0.0, 0.02, shadowD);
    shadowStrength = mix(0.0, 0.7, shadowStrength); // Adjust shadow opacity
    
    return shadowStrength;
}

// 3D parallax effect for background elements
vec2 parallaxOffset(vec2 p, float depth) {
    // Depth-based parallax movement
    float parallaxAmount = mix(0.0, 0.05, depth);
    
    // Slow movement direction
    vec2 parallaxDir = vec2(sin(gTime * 0.2), cos(gTime * 0.3));
    
    return p + parallaxDir * parallaxAmount;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

    gTime = iTime;
    
    // Get z-depth oscillation (0.0 to 1.0)
    float zDepth = sin(gTime * 0.5) * 0.5 + 0.5;
    
    // Apply balanced glitch effect (subtle)
    p = balancedGlitch(p);
    
    // Apply 3D scaling and movement effect
    vec2 p3D = apply3DEffect(p);
    
    // Calculate distance field with original coordinates for background elements
    float d = petersenGraph(p3D, zDepth);
    
    // Deep cyberpunk background gradient (stable) with parallax
    vec2 bgP = parallaxOffset(p, 1.0 - zDepth); // Inverse depth for background
    float gradientFactor = bgP.y * 0.2 + 0.5;
    vec3 col = mix(
        vec3(0.02, 0.01, 0.07), // Bottom - deep purple
        vec3(0.04, 0.02, 0.10), // Top - midnight blue
        gradientFactor
    );

    // Add dark cityscape silhouettes (stable) with parallax
    float cityHeight = 0.4 + sin(bgP.x * 10.0) * 0.05;
    float cityscape = smoothstep(0.0, 0.01, bgP.y + cityHeight);
    col = mix(col, vec3(0.08, 0.03, 0.12) * 0.5, 1.0 - cityscape);
    
    // Add distant city lights (subtle, non-flashy) with parallax
    float cityLights = pow(noise(bgP * 40.0), 6.0) * (1.0 - cityscape) * 2.0;
    col += cityLights * vec3(0.8, 0.5, 0.3) * 0.2;
    
    // Balanced cyberpunk grid with 3D depth effect
    float grid = balancedCyberGrid(bgP, 1.0 - zDepth); // Grid fades with depth
    vec3 gridColor = vec3(0.0, 0.5, 0.7); // Stable cyan color
    col += grid * gridColor * 0.15;
    
    // 3D shadow effect for Petersen graph
    float shadow = shadow3D(p, d, zDepth);
    col = mix(col, vec3(0.0), shadow * 0.5);
    
    // Multi-layered neon glow with 3D enhanced effect
    float neonMagenta = depthEnhancedNeonGlow(d, 0.01, 1.8, gTime, zDepth);
    float neonCyan = depthEnhancedNeonGlow(d, 0.02, 0.9, gTime + 0.5, zDepth);
    float neonBlue = depthEnhancedNeonGlow(d, 0.03, 0.4, gTime + 1.0, zDepth);
    float neonYellow = depthEnhancedNeonGlow(d, 0.045, 0.2, gTime + 1.5, zDepth);
    
    // Stable neon colors (no flashy variations)
    vec3 magentaColor = vec3(1.0, 0.0, 0.5);
    vec3 cyanColor = vec3(0.0, 0.8, 1.0);
    vec3 blueColor = vec3(0.2, 0.0, 0.8);
    vec3 yellowColor = vec3(1.0, 0.8, 0.0);
    
    col += neonMagenta * magentaColor; // Hot magenta inner glow
    col += neonCyan * cyanColor;       // Cyan middle glow
    col += neonBlue * blueColor;       // Blue outer glow
    col += neonYellow * yellowColor;   // Yellow outermost glow
    
    // Balanced RGB splitting (chromatic aberration) with 3D effect
    vec3 rgbSplit = vec3(0.0);
    for(int i = 0; i < 3; i++) {
        // Increase offset based on depth for enhanced 3D effect
        float offset = float(i) * 0.0015 * (1.0 + zDepth);
        vec2 offsetDir = vec2(cos(float(i) * PI / 1.5), sin(float(i) * PI / 1.5));
        vec2 offsetP = p3D + offsetDir * offset;
        float offsetD = petersenGraph(offsetP, zDepth);
        
        float edge = smoothstep(0.005, 0.0, abs(offsetD));
        
        // RGB color spectrum
        vec3 spectrumColor;
        if(i == 0) spectrumColor = vec3(1.0, 0.0, 0.0);      // Red
        else if(i == 1) spectrumColor = vec3(0.0, 1.0, 0.0); // Green
        else spectrumColor = vec3(0.0, 0.0, 1.0);            // Blue
        
        rgbSplit += edge * spectrumColor * 0.6;
    }
    
    col += rgbSplit;
    
    // Main edge with cyberpunk look
    float edgeWidth = 0.005;
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    
    // Edge highlight depends on depth (brighter when closer)
    float edgeHighlight = mix(0.5, 1.0, zDepth);
    col += edge * vec3(1.0, 0.9, 1.0) * 0.7 * edgeHighlight;
    
    // Solid fill with digital pattern
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.12, 0.04, 0.2);
    
    // Add 3D shading to fill color (darker when further away)
    fillColor *= mix(0.7, 1.2, zDepth);
    
    // Add balanced circuit pattern to fill
    float circuitPattern = balancedCircuitPattern(p3D, d);
    vec3 circuitColor = vec3(0.0, 0.2, 0.4); // Stable color
    fillColor += circuitPattern * circuitColor * 0.3;
    
    col += solid * fillColor;
    
    // Subtle electric sparks (reduced intensity, non-flashy)
    float sparks = noise(p3D * 50.0 + gTime * 2.0);
    sparks = pow(sparks, 15.0) * 5.0 * zDepth; // More sparks when closer
    col += sparks * vec3(1.0, 0.8, 0.2) * 0.3;
    
    // 3D atmosphere fog (more intense when further away)
    float fogAmount = mix(0.0, 0.3, 1.0 - zDepth);
    vec3 fogColor = vec3(0.1, 0.05, 0.2);
    col = mix(col, fogColor, fogAmount * solid);
    
    // Balanced scanlines effect
    col *= balancedScanlines(fragCoord);
    
    // Smooth vignette effect
    float centerDist = length(p);
    float vignette = 1.0 - centerDist * 0.4;
    vignette = pow(vignette, 1.5);
    col *= vignette;
    
    // Gentle screen curvature
    float screenCurve = length(p * vec2(0.8, 1.1));
    screenCurve = pow(screenCurve, 2.0) * 0.03;
    col *= 1.0 - screenCurve;
    
    // 3D motion blur effect (subtle)
    float motionBlurAmount = abs(sin(gTime * 0.5 - 0.25)) * 0.1; // Motion blur during transitions
    col = mix(col, vec3(dot(col, vec3(0.333))), motionBlurAmount);
    
    // Color grading for cyberpunk aesthetic
    col.r = pow(col.r, 0.85); // Enhance reds
    col.g = pow(col.g, 0.95); // Slightly enhance greens
    col.b = pow(col.b, 0.8); // Enhance blues
    
    // Final contrast enhancement
    col = pow(col, vec3(0.85));
    col *= 1.5;

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - 3D Cyberpunk",
    "description": "3D cyberpunk visualization with z-axis movement, scaling effects, and enhanced depth perception",
    "model": "plane"
}
*/