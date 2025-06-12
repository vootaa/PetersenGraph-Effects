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

// Stable digital effect without flickering
vec2 stableGlitch(vec2 p) {
    // Very subtle scan lines
    float scanGlitch = noise(vec2(floor(p.y * 15.0), 0.5)) * 0.01;
    p.x += scanGlitch;
    
    // Subtle signal interference (constant)
    float interference = sin(p.y * 80.0) * 0.001;
    p.x += interference;
    
    return p;
}

// Stable scanline effect (no flicker)
float stableScanlines(vec2 p) {
    // Consistent scanlines with minimal intensity
    float scan = sin(p.y * 120.0) * 0.02 + 0.98;
    return scan;
}

// Stable neon glow without pulsation
float stableNeonGlow(float d, float width, float intensity) {
    // Base neon glow without time variation
    float glow = width / (abs(d) + width) * intensity;
    return glow;
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

// Stable shape without distortion
float stableShape(float d) {
    return d;
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
    float d1 = stableShape(shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink));
    
    // P2 Heptagon: {(0.060,36),(0.150,0),(0.300,0),(0.390,6),(0.390,66),(0.300,72),(0.150,72)}
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    
    float d2 = stableShape(shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink));
    
    // P3 Quadrilateral: {(0.300,0),(0.390,354),(0.416,0),(0.390,6)}
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float d3 = stableShape(shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink));
    
    // P4 Triangle: {(0.390,6),(0.416,0),(0.480,10)}
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float d4 = stableShape(shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink));
    
    // P5 Quadrilateral: {(0.390,6),(0.480,10),(0.480,62),(0.390,66)}
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float d5 = stableShape(shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink));
    
    // P6 Triangle: {(0.390,66),(0.480,62),(0.416,72)}
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float d6 = stableShape(shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink));
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Complete Petersen graph (5-fold symmetry)
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Constant slow rotation (no direction changes)
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

// Stable cyberpunk grid without animations
float stableCyberGrid(vec2 p) {
    // Main grid layer
    float grid1 = abs(sin(p.x * 30.0)) * abs(sin(p.y * 30.0));
    grid1 = smoothstep(0.95, 1.0, grid1);
    
    // Secondary hexagonal grid
    float hexGrid = 0.0;
    for(int i = 0; i < 3; i++) {
        float angle = float(i) * PI / 3.0;
        vec2 dir = vec2(cos(angle), sin(angle));
        hexGrid += abs(sin(dot(p, dir) * 30.0));
    }
    hexGrid = smoothstep(2.7, 2.8, hexGrid);
    
    // Very slow data flow (barely noticeable movement)
    float dataLines = sin(p.x * 30.0 + p.y * 15.0 - gTime * 2.0);
    dataLines = smoothstep(0.95, 1.0, dataLines);
    
    return grid1 * 0.5 + hexGrid * 0.2 + dataLines * 0.1;
}

// Stable digital rain (minimal movement)
float stableDigitalRain(vec2 p) {
    // Main rain with fixed pattern and very slow movement
    float rain1 = noise(vec2(p.x * 5.0, p.y * 8.0 - gTime * 0.5));
    rain1 = smoothstep(0.97, 1.0, rain1);
    
    // Secondary rain with different pattern
    float rain2 = noise(vec2(p.x * 7.0 + 1.5, p.y * 5.0 - gTime * 0.3 + 10.0));
    rain2 = smoothstep(0.98, 1.0, rain2);
    
    return rain1 * 0.4 + rain2 * 0.3;
}

// Stable circuit pattern without animation
float stableCircuitPattern(vec2 p) {
    // Base circuit traces with fixed pattern
    float circuit = noise(p * 30.0 + vec2(0.5, 0.3));
    circuit = step(0.7, circuit);
    
    // Fixed nodes
    float nodes = sin(p.x * 15.0) * sin(p.y * 15.0);
    nodes = smoothstep(0.95, 1.0, nodes);
    
    return circuit * 0.6 + nodes * 0.2;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

    gTime = iTime;
    
    // Apply stable subtle effect
    p = stableGlitch(p);

    float d = petersenGraph(p);

    // Deep cyberpunk background gradient
    float gradientFactor = p.y * 0.2 + 0.5;
    vec3 col = mix(
        vec3(0.02, 0.0, 0.08), // Bottom - deep purple
        vec3(0.05, 0.02, 0.12), // Top - midnight blue
        gradientFactor
    );

    // Add dark cityscape silhouettes (stable)
    float cityHeight = 0.4 + sin(p.x * 10.0) * 0.05;
    float cityscape = smoothstep(0.0, 0.01, p.y + cityHeight);
    col = mix(col, vec3(0.15, 0.05, 0.2) * 0.5, 1.0 - cityscape);
    
    // Add distant city lights (stable pattern)
    float cityLights = pow(noise(p * 40.0 + vec2(0.2, 0.3)), 6.0) * (1.0 - cityscape) * 2.0;
    col += cityLights * vec3(1.0, 0.6, 0.3) * 0.2;
    
    // Stable cyberpunk grid
    float grid = stableCyberGrid(p);
    vec3 gridColor = vec3(0.0, 0.6, 0.8); // Fixed cyan color
    col += grid * gridColor * 0.15;
    
    // Stable digital rain
    float rain = stableDigitalRain(p);
    vec3 rainColor = vec3(0.0, 0.8, 0.3); // Fixed green color
    col += rain * rainColor * 0.2;
    
    // Stable neon glow without pulsation
    float neonMagenta = stableNeonGlow(d, 0.01, 1.8);
    float neonCyan = stableNeonGlow(d, 0.02, 0.9);
    float neonBlue = stableNeonGlow(d, 0.03, 0.4);
    float neonYellow = stableNeonGlow(d, 0.045, 0.2);
    
    // Fixed neon colors (no flicker)
    vec3 magentaColor = vec3(1.0, 0.0, 0.5);
    vec3 cyanColor = vec3(0.0, 0.8, 1.0);
    vec3 blueColor = vec3(0.2, 0.0, 0.8);
    vec3 yellowColor = vec3(1.0, 0.8, 0.0);
    
    col += neonMagenta * magentaColor; // Hot magenta inner glow
    col += neonCyan * cyanColor;       // Cyan middle glow
    col += neonBlue * blueColor;       // Blue outer glow
    col += neonYellow * yellowColor;   // Yellow outermost glow
    
    // Subtle chromatic aberration (fixed offset, no flicker)
    vec3 rgbSplit = vec3(0.0);
    for(int i = 0; i < 3; i++) {
        float offset = float(i) * 0.001; // Reduced offset
        vec2 offsetDir = vec2(cos(float(i) * PI / 1.5), sin(float(i) * PI / 1.5));
        vec2 offsetP = p + offsetDir * offset;
        float offsetD = petersenGraph(offsetP);
        
        float edge = smoothstep(0.005, 0.0, abs(offsetD));
        
        // RGB color spectrum
        vec3 spectrumColor;
        if(i == 0) spectrumColor = vec3(1.0, 0.0, 0.0);      // Red
        else if(i == 1) spectrumColor = vec3(0.0, 1.0, 0.0); // Green
        else spectrumColor = vec3(0.0, 0.0, 1.0);            // Blue
        
        rgbSplit += edge * spectrumColor * 0.5;
    }
    
    col += rgbSplit;
    
    // Main edge with cyberpunk look
    float edgeWidth = 0.005;
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    col += edge * vec3(1.0, 0.9, 1.0) * 0.7;
    
    // Solid fill with circuit pattern
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.15, 0.05, 0.25);
    
    // Add stable circuit pattern to fill
    float circuitPattern = stableCircuitPattern(p);
    vec3 circuitColor = vec3(0.0, 0.3, 0.5); // Fixed blue circuit color
    fillColor += circuitPattern * circuitColor * 0.3;
    
    col += solid * fillColor;
    
    // Very subtle sparks (rare and minimal)
    float sparks = pow(noise(p * 50.0 + vec2(0.7, 0.2)), 20.0) * 3.0;
    col += sparks * vec3(1.0, 0.8, 0.0) * 0.15;
    
    // Stable scanlines effect
    col *= stableScanlines(fragCoord);
    
    // Smooth vignette effect
    float centerDist = length(p);
    float vignette = 1.0 - centerDist * 0.4;
    vignette = pow(vignette, 1.5);
    col *= vignette;
    
    // Gentle screen curvature
    float screenCurve = length(p * vec2(0.8, 1.0));
    screenCurve = pow(screenCurve, 2.0) * 0.03;
    col *= 1.0 - screenCurve;
    
    // Color grading for cyberpunk aesthetic
    col.r = pow(col.r, 0.85); // Enhance reds
    col.g = pow(col.g, 0.95); // Slightly enhance greens
    col.b = pow(col.b, 0.8); // Enhance blues
    
    // Final contrast enhancement
    col = pow(col, vec3(0.85));
    col *= 1.5;
    
    // Very subtle film grain (static, non-flickering)
    float grain = noise(fragCoord * 0.5 + vec2(0.1, 0.1)) * 0.02;
    col += grain * col;

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Stable Cyberpunk",
    "description": "Cyberpunk visualization with stable elements and no flickering effects",
    "model": "plane"
}
*/