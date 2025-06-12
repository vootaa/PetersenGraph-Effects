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

// Advanced spacetime warp with ripple effect
vec2 spacetimeWarp(vec2 p) {
    float warpStrength = sin(gTime * 0.4) * 0.5 + 0.5;

    // Radial ripples
    float dist = length(p);
    float ripple = sin(dist * 15.0 - gTime * 8.0) * warpStrength * 0.1;

    // Spiral distortion
    float angle = atan(p.y, p.x);
    float spiral = sin(angle * 3.0 + gTime * 2.0) * warpStrength * 0.05;

    return p * (1.0 + ripple + spiral);
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
    float d1 = shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink);
    
    // P2 Heptagon: {(0.060,36),(0.150,0),(0.300,0),(0.390,6),(0.390,66),(0.300,72),(0.150,72)}
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    
    float d2 = shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink);
    
    // P3 Quadrilateral: {(0.300,0),(0.390,354),(0.416,0),(0.390,6)}
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float d3 = shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink);
    
    // P4 Triangle: {(0.390,6),(0.416,0),(0.480,10)}
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float d4 = shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink);
    
    // P5 Quadrilateral: {(0.390,6),(0.480,10),(0.480,62),(0.390,66)}
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float d5 = shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink);
    
    // P6 Triangle: {(0.390,66),(0.480,62),(0.416,72)}
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float d6 = shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink);
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Complete Petersen graph (5-fold symmetry)
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Slow rotation
    float rotSpeed = 0.05;
    p *= rot(gTime * rotSpeed);
    
    // 5-fold rotational symmetry
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * 72.0 * PI / 180.0;
        vec2 rotP = p * rot(-angle);
        d = min(d, petersenPart(rotP));
    }
    
    return d;
}

// Balanced cyberpunk grid
float balancedCyberGrid(vec2 p) {
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
    
    return grid1 * 0.6 + hexGrid * 0.2 + dataLines * 0.1;
}

// Digital circuit pattern
float circuitPattern(vec2 p, float d) {
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

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    gTime = iTime;

    // Apply spacetime distortion from PGNS_2
    vec2 warpedP = spacetimeWarp(p);
    float d = petersenGraph(warpedP);

    // Deep cyberpunk background gradient from PGNS_d
    float gradientFactor = p.y * 0.2 + 0.5;
    vec3 col = mix(
        vec3(0.02, 0.01, 0.07), // Bottom - deep purple
        vec3(0.04, 0.02, 0.10), // Top - midnight blue
        gradientFactor
    );

    // Add dark cityscape silhouettes from PGNS_d
    float cityHeight = 0.4 + sin(p.x * 10.0) * 0.05;
    float cityscape = smoothstep(0.0, 0.01, p.y + cityHeight);
    col = mix(col, vec3(0.08, 0.03, 0.12) * 0.5, 1.0 - cityscape);
    
    // Add distant city lights from PGNS_d
    float cityLights = pow(noise(p * 40.0), 6.0) * (1.0 - cityscape) * 2.0;
    col += cityLights * vec3(0.8, 0.5, 0.3) * 0.2;
    
    // Cyberpunk grid from PGNS_d
    float grid = balancedCyberGrid(p);
    vec3 gridColor = vec3(0.0, 0.5, 0.7); // Stable cyan color
    col += grid * gridColor * 0.15;
    
    // Distortion visualization from PGNS_2 (enhanced for cyberpunk)
    float warpVis = length(warpedP - p) * 12.0;
    col += warpVis * vec3(1.0, 0.0, 0.5) * 0.2; // Magenta distortion visualization
    
    // Multi-layered neon glow from PGNS_d
    float neonMagenta = balancedNeonGlow(d, 0.01, 1.8, gTime);
    float neonCyan = balancedNeonGlow(d, 0.02, 0.9, gTime + 0.5);
    float neonBlue = balancedNeonGlow(d, 0.03, 0.4, gTime + 1.0);
    float neonYellow = balancedNeonGlow(d, 0.045, 0.2, gTime + 1.5);
    
    // Neon colors from PGNS_d
    vec3 magentaColor = vec3(1.0, 0.0, 0.5);
    vec3 cyanColor = vec3(0.0, 0.8, 1.0);
    vec3 blueColor = vec3(0.2, 0.0, 0.8);
    vec3 yellowColor = vec3(1.0, 0.8, 0.0);
    
    col += neonMagenta * magentaColor; // Hot magenta inner glow
    col += neonCyan * cyanColor;       // Cyan middle glow
    col += neonBlue * blueColor;       // Blue outer glow
    col += neonYellow * yellowColor;   // Yellow outermost glow
    
    // Chromatic aberration from PGNS_2 (enhanced with PGNS_d colors)
    vec3 rgbSplit = vec3(0.0);
    for(int i = 0; i < 3; i++) {
        float offset = float(i) * 0.002;
        vec2 chromaP = warpedP + vec2(offset, -offset);
        float chromaD = petersenGraph(chromaP);

        float edge = smoothstep(0.005, 0.0, abs(chromaD));
        
        // RGB color spectrum from PGNS_d
        vec3 spectrumColor;
        if(i == 0) spectrumColor = vec3(1.0, 0.0, 0.0);      // Red
        else if(i == 1) spectrumColor = vec3(0.0, 1.0, 0.0); // Green
        else spectrumColor = vec3(0.0, 0.0, 1.0);            // Blue
        
        rgbSplit += edge * spectrumColor * 0.6;
    }
    
    col += rgbSplit;
    
    // Main edge with cyberpunk look from PGNS_d
    float edgeWidth = 0.005;
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    col += edge * vec3(1.0, 0.9, 1.0) * 0.7;
    
    // Solid fill with digital pattern from PGNS_d
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.12, 0.04, 0.2);
    
    // Add circuit pattern to fill from PGNS_d
    float circuitPat = circuitPattern(warpedP, d);
    vec3 circuitColor = vec3(0.0, 0.2, 0.4); // Stable color
    fillColor += circuitPat * circuitColor * 0.3;
    
    col += solid * fillColor;
    
    // Electric sparks from PGNS_d
    float sparks = noise(warpedP * 50.0 + gTime * 2.0);
    sparks = pow(sparks, 15.0) * 5.0; 
    col += sparks * vec3(1.0, 0.8, 0.2) * 0.3;
    
    // Scanlines effect from PGNS_d
    col *= balancedScanlines(fragCoord);
    
    // Smooth vignette effect from PGNS_d
    float centerDist = length(p);
    float vignette = 1.0 - centerDist * 0.4;
    vignette = pow(vignette, 1.5);
    col *= vignette;
    
    // Color grading for cyberpunk aesthetic from PGNS_d
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
    "title": "Petersen Graph - Ripple Cyberpunk",
    "description": "Spacetime ripple effect with cyberpunk aesthetic",
    "model": "plane"
}
*/