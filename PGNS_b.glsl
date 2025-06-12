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

// Advanced digital glitch effect with more distortion types
vec2 enhancedGlitch(vec2 p) {
    // Time-varying glitch strength
    float glitchStrength = sin(gTime * 3.0) * 0.5 + 0.5;
    
    // Horizontal scan glitch
    if(glitchStrength > 0.8) {
        float scanGlitch = noise(vec2(floor(p.y * 20.0), gTime)) * 0.03;
        p.x += scanGlitch * glitchStrength;
    }
    
    // Block shifting glitch
    if(sin(gTime * 5.0) > 0.9) {
        float blockHeight = 0.05;
        float blockShift = step(0.5, noise(vec2(floor(p.y / blockHeight), gTime * 0.2))) * 0.02;
        p.x += blockShift * sin(gTime * 50.0);
    }
    
    // Signal interference
    if(sin(gTime * 1.7) > 0.85) {
        float interference = sin(p.y * 100.0 + gTime * 50.0) * 0.004;
        p.x += interference;
    }
    
    // RGB shift - subtle pixel splitting
    if(mod(gTime, 4.0) > 3.0) {
        p.x += sin(p.y * 40.0 + gTime) * 0.002;
    }
    
    return p;
}

// Enhanced scanline effect with rolling distortion
float enhancedScanlines(vec2 p) {
    // Traditional scanlines
    float scan = sin(p.y * 150.0 + gTime * 10.0) * 0.05 + 0.95;
    
    // Rolling scan distortion
    float rollScan = sin(p.y * 50.0 + gTime * 5.0) * sin(gTime * 3.0);
    rollScan = smoothstep(0.85, 1.0, rollScan) * 0.1;
    
    // Flickering
    float flicker = sin(gTime * 10.0) * 0.015 + 0.985;
    
    return scan * (1.0 - rollScan) * flicker;
}

// Improved neon glow with dynamic properties
float enhancedNeonGlow(float d, float width, float intensity, float time) {
    // Base neon glow
    float glow = width / (abs(d) + width) * intensity;
    
    // Energy pulsation
    float pulse = sin(time * 2.0 + d * 10.0) * 0.1 + 0.9;
    
    // Interference patterns in the neon
    float interference = sin(d * 100.0 + time * 5.0) * 0.05 + 0.95;
    
    return glow * pulse * interference;
}

// Holographic flicker effect
float holographicFlicker(float time, float intensity) {
    float flicker = sin(time * 25.0) * 0.1 + 0.9;
    flicker *= sin(time * 17.0) * 0.05 + 0.95;
    flicker *= sin(time * 40.0 + noise(vec2(time))) * 0.03 + 0.97;
    return flicker * intensity;
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

// Distort shape with digital glitches
float distortShape(float d, vec2 p) {
    // Digital distortion based on position and time
    float distortion = sin(p.x * 40.0 + gTime * 3.0) * sin(p.y * 40.0 - gTime * 2.0) * 0.002;
    
    // Random glitches at edges
    float edgeGlitch = smoothstep(0.01, 0.0, abs(d)) * noise(p * 50.0 + gTime) * 0.003;
    
    return d + distortion + edgeGlitch;
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
    float d1 = distortShape(shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink), p);
    
    // P2 Heptagon: {(0.060,36),(0.150,0),(0.300,0),(0.390,6),(0.390,66),(0.300,72),(0.150,72)}
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    
    float d2 = distortShape(shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink), p);
    
    // P3 Quadrilateral: {(0.300,0),(0.390,354),(0.416,0),(0.390,6)}
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float d3 = distortShape(shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink), p);
    
    // P4 Triangle: {(0.390,6),(0.416,0),(0.480,10)}
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float d4 = distortShape(shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink), p);
    
    // P5 Quadrilateral: {(0.390,6),(0.480,10),(0.480,62),(0.390,66)}
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float d5 = distortShape(shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink), p);
    
    // P6 Triangle: {(0.390,66),(0.480,62),(0.416,72)}
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float d6 = distortShape(shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink), p);
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Complete Petersen graph (5-fold symmetry)
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Variable rotation speed with occasional reverse
    float rotSpeed = 0.15 * (sin(gTime * 0.1) * 0.3 + 0.7);
    if(sin(gTime * 0.05) > 0.9) rotSpeed *= -1.0; // Occasional reverse
    p *= rot(gTime * rotSpeed);
    
    // 5-fold rotational symmetry
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * 72.0 * PI / 180.0;
        vec2 rotP = p * rot(-angle);
        d = min(d, petersenPart(rotP));
    }
    
    return d;
}

// Advanced digital grid with layers and animations
float advancedCyberGrid(vec2 p) {
    // Main grid layer
    float grid1 = abs(sin(p.x * 30.0)) * abs(sin(p.y * 30.0));
    grid1 = smoothstep(0.95, 1.0, grid1);
    
    // Secondary hexagonal grid
    float hexGrid = 0.0;
    for(int i = 0; i < 3; i++) {
        float angle = float(i) * PI / 3.0;
        vec2 dir = vec2(cos(angle), sin(angle));
        hexGrid += abs(sin(dot(p, dir) * 40.0));
    }
    hexGrid = smoothstep(2.7, 2.8, hexGrid);
    
    // Flowing data lines
    float dataLines = sin(p.x * 40.0 + p.y * 20.0 - gTime * 15.0);
    dataLines = smoothstep(0.95, 1.0, dataLines);
    
    // Pulsing nodes at intersections
    float nodes = grid1 * sin(length(p) * 10.0 - gTime * 3.0) * 0.5 + 0.5;
    
    return grid1 * 0.6 + hexGrid * 0.3 + dataLines * 0.2 + nodes * 0.1;
}

// Digital rain with multiple layers and variants
float enhancedDigitalRain(vec2 p) {
    // Main fast green rain
    float rain1 = noise(vec2(p.x * 5.0, p.y * 10.0 - gTime * 3.0));
    rain1 = smoothstep(0.97, 1.0, rain1);
    
    // Secondary slower blue rain
    float rain2 = noise(vec2(p.x * 8.0 + 1.5, p.y * 7.0 - gTime * 1.5 + 10.0));
    rain2 = smoothstep(0.98, 1.0, rain2);
    
    // Occasional "glitch" characters
    float glitchChars = noise(vec2(p.x * 12.0, p.y * 12.0 - gTime * 0.5));
    glitchChars = smoothstep(0.993, 1.0, glitchChars);
    
    // Horizontal data streams
    float dataStream = noise(vec2(p.y * 7.0, p.x * 7.0 - gTime * 1.0));
    dataStream = smoothstep(0.98, 1.0, dataStream);
    
    return rain1 * 0.7 + rain2 * 0.5 + glitchChars * 1.5 + dataStream * 0.3;
}

// Advanced circuit pattern with animated elements
float advancedCircuitPattern(vec2 p, float d) {
    // Base circuit traces
    float circuit = noise(p * 50.0 + gTime * 0.5);
    circuit = step(0.7, circuit);
    
    // Data flow pulses along circuits
    float pulse = sin(p.x * 50.0 + p.y * 50.0 - gTime * 10.0) * 0.5 + 0.5;
    pulse *= circuit;
    pulse = smoothstep(0.9, 1.0, pulse);
    
    // Connection nodes
    float nodes = sin(p.x * 20.0) * sin(p.y * 20.0);
    nodes = smoothstep(0.95, 1.0, nodes);
    
    // Circuit density increases near shape edges
    float edgeFactor = smoothstep(0.05, 0.0, abs(d));
    float edgeCircuit = noise(p * 100.0 + gTime * 0.2);
    edgeCircuit = step(0.6, edgeCircuit) * edgeFactor;
    
    return circuit * 0.7 + pulse * 0.8 + nodes * 0.3 + edgeCircuit * 0.5;
}

// Holographic depth layers
float holographicDepth(vec2 p, float d, float time) {
    // Displacement waves
    float displacement = sin(p.x * 20.0 + p.y * 20.0 - time * 5.0) * 0.5 + 0.5;
    
    // Fresnel-like edge effect
    float edge = smoothstep(0.05, 0.0, abs(d));
    
    // Interference patterns
    float interference = sin(length(p) * 50.0 - time * 8.0) * 0.5 + 0.5;
    
    return mix(displacement * 0.3, interference * 0.7, edge);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

    gTime = iTime;
    
    // Apply enhanced digital glitch effect
    p = enhancedGlitch(p);

    float d = petersenGraph(p);

    // Deep cyberpunk background gradient
    float gradientFactor = p.y * 0.2 + 0.5;
    vec3 col = mix(
        vec3(0.02, 0.0, 0.08), // Bottom - deep purple
        vec3(0.05, 0.02, 0.12), // Top - midnight blue
        gradientFactor
    );

    // Add dark cityscape silhouettes
    float cityHeight = 0.4 + sin(p.x * 15.0) * 0.1;
    float cityscape = smoothstep(0.0, 0.01, p.y + cityHeight);
    col = mix(col, vec3(0.15, 0.05, 0.2) * 0.5, 1.0 - cityscape);
    
    // Add distant city lights
    float cityLights = pow(noise(p * 50.0), 5.0) * (1.0 - cityscape) * 3.0;
    col += cityLights * vec3(1.0, 0.6, 0.3) * 0.3;
    
    // Advanced cyberpunk grid
    float grid = advancedCyberGrid(p);
    vec3 gridColor = mix(
        vec3(0.0, 0.6, 0.8), // Cyan
        vec3(0.0, 0.8, 0.4), // Teal
        sin(p.x * 2.0 + gTime) * 0.5 + 0.5
    );
    col += grid * gridColor * 0.25;
    
    // Enhanced digital rain
    float rain = enhancedDigitalRain(p);
    vec3 rainColor = mix(
        vec3(0.0, 1.0, 0.4), // Green
        vec3(0.0, 0.5, 1.0), // Blue
        sin(p.y * 5.0 + gTime * 0.5) * 0.5 + 0.5
    );
    col += rain * rainColor * 0.35;
    
    // Holographic atmosphere
    float holo = holographicDepth(p, d, gTime);
    col += holo * vec3(0.1, 0.3, 0.7) * 0.15;
    
    // Multi-layered neon glow with enhanced properties
    float neonMagenta = enhancedNeonGlow(d, 0.01, 2.0, gTime);
    float neonCyan = enhancedNeonGlow(d, 0.02, 1.0, gTime + 0.5);
    float neonBlue = enhancedNeonGlow(d, 0.03, 0.5, gTime + 1.0);
    float neonYellow = enhancedNeonGlow(d, 0.045, 0.3, gTime + 1.5);
    
    // Dynamic neon colors based on position and time
    vec3 magentaColor = vec3(1.0, 0.0, 0.5) * holographicFlicker(gTime, 1.0);
    vec3 cyanColor = vec3(0.0, 0.8, 1.0) * holographicFlicker(gTime + 0.3, 1.0);
    vec3 blueColor = vec3(0.2, 0.0, 0.8) * holographicFlicker(gTime + 0.6, 1.0);
    vec3 yellowColor = vec3(1.0, 0.8, 0.0) * holographicFlicker(gTime + 0.9, 1.0);
    
    col += neonMagenta * magentaColor; // Hot magenta inner glow
    col += neonCyan * cyanColor;       // Cyan middle glow
    col += neonBlue * blueColor;       // Blue outer glow
    col += neonYellow * yellowColor;   // Yellow outermost glow
    
    // Advanced RGB splitting (chromatic aberration)
    vec3 rgbSplit = vec3(0.0);
    for(int i = 0; i < 5; i++) {
        float offset = float(i) * 0.0015;
        vec2 offsetDir = vec2(cos(float(i) * PI / 2.5), sin(float(i) * PI / 2.5));
        vec2 offsetP = p + offsetDir * offset;
        float offsetD = petersenGraph(offsetP);
        
        float edge = smoothstep(0.005, 0.0, abs(offsetD));
        
        // Extended color spectrum
        vec3 spectrumColor;
        if(i == 0) spectrumColor = vec3(1.0, 0.0, 0.0);      // Red
        else if(i == 1) spectrumColor = vec3(1.0, 0.5, 0.0); // Orange
        else if(i == 2) spectrumColor = vec3(0.0, 1.0, 0.0); // Green
        else if(i == 3) spectrumColor = vec3(0.0, 0.5, 1.0); // Sky blue
        else spectrumColor = vec3(0.5, 0.0, 1.0);            // Purple
        
        rgbSplit += edge * spectrumColor * 0.7;
    }
    
    // Apply RGB split with digital distortion
    float digitalDistortion = sin(p.x * 100.0 + p.y * 100.0 + gTime * 10.0) * 0.5 + 0.5;
    rgbSplit *= 0.8 + digitalDistortion * 0.4;
    col += rgbSplit;
    
    // Main edge with sharper cyberpunk look
    float edgeWidth = 0.005;
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    col += edge * vec3(1.0, 0.9, 1.0) * 0.8;
    
    // Solid fill with advanced digital pattern
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.15, 0.05, 0.25);
    
    // Add advanced circuit pattern to fill
    float circuitPattern = advancedCircuitPattern(p, d);
    vec3 circuitColor = mix(
        vec3(0.0, 0.3, 0.5), // Blue circuit
        vec3(0.5, 0.0, 0.5), // Purple circuit
        sin(length(p) * 5.0 + gTime) * 0.5 + 0.5
    );
    fillColor += circuitPattern * circuitColor * 0.4;
    
    col += solid * fillColor;
    
    // Enhanced electric sparks with color variations
    float sparks = noise(p * 80.0 + gTime * 5.0);
    sparks = pow(sparks, 20.0) * 8.0;
    vec3 sparkColor = mix(
        vec3(1.0, 0.8, 0.0), // Yellow
        vec3(0.0, 1.0, 1.0), // Cyan
        noise(vec2(p.x + p.y, gTime))
    );
    col += sparks * sparkColor * 0.6;
    
    // Data transmission bursts
    float dataBurst = noise(vec2(length(p) * 5.0 - gTime * 2.0, atan(p.y, p.x) * 3.0));
    dataBurst = pow(dataBurst, 8.0) * 2.0;
    col += dataBurst * vec3(0.0, 1.0, 0.5) * 0.4;
    
    // Enhanced scanlines effect
    col *= enhancedScanlines(fragCoord);
    
    // Advanced digital noise overlay with color variations
    float digitalNoise = noise(fragCoord + gTime * 10.0);
    digitalNoise = step(0.985, digitalNoise);
    vec3 noiseColor = mix(
        vec3(1.0, 1.0, 1.0), // White noise
        vec3(1.0, 0.0, 1.0), // Magenta noise
        noise(vec2(gTime * 0.1))
    );
    col += digitalNoise * noiseColor * 0.15;
    
    // Cinematic vignette effect
    float centerDist = length(p);
    float vignette = 1.0 - centerDist * 0.5;
    vignette = pow(vignette, 1.5);
    col *= vignette;
    
    // CRT screen curvature distortion
    float screenCurve = length(p * vec2(0.9, 1.2));
    screenCurve = pow(screenCurve, 2.0) * 0.05;
    col *= 1.0 - screenCurve;
    
    // Enhanced glitch flash effect
    float glitchFlash = step(0.98, noise(vec2(gTime * 0.5)));
    if(glitchFlash > 0.5) {
        // Multi-stage glitch
        float glitchType = noise(vec2(gTime * 0.2));
        if(glitchType < 0.33) {
            // Color inversion
            col = mix(col, 1.0 - col, 0.7);
        } else if(glitchType < 0.66) {
            // Magenta flash
            col = mix(col, vec3(1.0, 0.0, 0.5) * length(col), 0.6);
        } else {
            // Horizontal offset
            float yPos = floor(fragCoord.y / 4.0);
            col = mix(col, vec3(0.0), step(0.5, noise(vec2(yPos, gTime))) * 0.5);
        }
    }
    
    // Cyber pulse through the entire image
    float globalPulse = sin(gTime * 0.8) * 0.5 + 0.5;
    col *= 0.9 + globalPulse * 0.2;
    
    // Color grading for cyberpunk aesthetic
    col.r = pow(col.r, 0.8); // Enhance reds
    col.g = pow(col.g, 0.95); // Slightly enhance greens
    col.b = pow(col.b, 0.75); // Enhance blues
    
    // Cyan-magenta color shift in shadows
    col = mix(
        col,
        mix(vec3(0.0, 0.4, 0.4), vec3(0.4, 0.0, 0.4), sin(gTime * 0.3) * 0.5 + 0.5),
        (1.0 - length(col)) * 0.3
    );
    
    // Final contrast enhancement with subtle bloom
    col = pow(col, vec3(0.8));
    col *= 1.6;
    
    // Subtle film grain
    float grain = noise(fragCoord + gTime) * 0.03;
    col += grain * col;

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Ultra Cyberpunk",
    "description": "Advanced cyberpunk visualization with holographic elements, digital distortions, and urban night aesthetic",
    "model": "plane"
}
*/