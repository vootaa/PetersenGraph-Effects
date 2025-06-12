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

// Digital glitch effect
vec2 digitalGlitch(vec2 p) {
    float glitchStrength = sin(gTime * 3.0) * 0.5 + 0.5;
    if(glitchStrength > 0.8) {
        float glitchOffset = noise(vec2(floor(p.y * 20.0), gTime)) * 0.02;
        p.x += glitchOffset * glitchStrength;
    }
    return p;
}

// Scanline effect
float scanlines(vec2 p) {
    return sin(p.y * 150.0 + gTime * 10.0) * 0.05 + 0.95;
}

// Neon glow effect
float neonGlow(float d, float width, float intensity) {
    return width / (abs(d) + width) * intensity;
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
    
    // Rotation speed
    p *= rot(gTime * 0.15);
    
    // 5-fold rotational symmetry
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * 72.0 * PI / 180.0;
        vec2 rotP = p * rot(-angle);
        d = min(d, petersenPart(rotP));
    }
    
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

    gTime = iTime;
    
    // Apply digital glitch effect
    p = digitalGlitch(p);

    float d = petersenGraph(p);

    // Dark cyberpunk background
    vec3 col = vec3(0.03, 0.02, 0.09); // Deep blue/purple

    // Add dark cityscape atmosphere
    float centerDist = length(p);
    col += vec3(0.05, 0.0, 0.07) * (1.0 - centerDist * 0.5);
    
    // Digital grid
    float grid = abs(sin(p.x * 30.0)) * abs(sin(p.y * 30.0));
    grid = smoothstep(0.95, 1.0, grid);
    col += grid * vec3(0.0, 0.6, 0.8) * 0.2; // Cyan grid
    
    // Digital rain effect (Matrix style)
    float rain = noise(vec2(p.x * 5.0, p.y * 10.0 - gTime * 2.0));
    rain = smoothstep(0.97, 1.0, rain);
    col += rain * vec3(0.0, 1.0, 0.4) * 0.3; // Green digital rain
    
    // Multi-layered neon glow effect
    float neonPink = neonGlow(d, 0.01, 2.0);
    float neonCyan = neonGlow(d, 0.02, 1.0);
    float neonBlue = neonGlow(d, 0.03, 0.5);
    
    col += neonPink * vec3(1.0, 0.0, 0.5); // Hot pink inner glow
    col += neonCyan * vec3(0.0, 0.8, 1.0); // Cyan middle glow
    col += neonBlue * vec3(0.2, 0.0, 0.8); // Blue outer glow
    
    // Chromatic aberration
    for(int i = 0; i < 3; i++) {
        float offset = float(i) * 0.002;
        vec2 offsetP = p + vec2(offset, -offset * 0.5);
        float offsetD = petersenGraph(offsetP);
        
        float edge = smoothstep(0.005, 0.0, abs(offsetD));
        
        // RGB separation
        vec3 edgeColor = vec3(0.0);
        if(i == 0) edgeColor.r = 1.0; // Red channel
        else if(i == 1) edgeColor.g = 1.0; // Green channel
        else edgeColor.b = 1.0; // Blue channel
        
        col += edge * edgeColor * 0.8;
    }
    
    // Main edge with sharper cyberpunk look
    float edgeWidth = 0.005;
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    col += edge * vec3(1.0, 0.9, 1.0) * 0.8; // Bright core
    
    // Solid fill with digital pattern
    float solid = smoothstep(0.002, -0.002, d);
    vec3 fillColor = vec3(0.15, 0.05, 0.25); // Dark purple fill
    
    // Add digital circuit pattern to fill
    float circuitPattern = noise(p * 50.0 + gTime * 0.5);
    circuitPattern = step(0.7, circuitPattern);
    fillColor += circuitPattern * vec3(0.0, 0.3, 0.5) * 0.3; // Blue circuit traces
    
    col += solid * fillColor;
    
    // Electric sparks
    float sparks = noise(p * 80.0 + gTime * 5.0);
    sparks = step(0.98, sparks);
    col += sparks * vec3(1.0, 0.8, 0.0) * 0.5; // Yellow electric sparks
    
    // Scanlines effect
    col *= scanlines(fragCoord);
    
    // Digital noise overlay
    float digitalNoise = noise(fragCoord + gTime * 10.0);
    digitalNoise = step(0.98, digitalNoise);
    col += digitalNoise * vec3(0.8, 0.8, 1.0) * 0.1; // White digital noise
    
    // Vignette effect
    float vignette = 1.0 - centerDist * 0.5;
    col *= vignette;
    
    // Occasional glitch flash
    float glitchFlash = step(0.98, noise(vec2(gTime * 0.5)));
    col = mix(col, vec3(1.0, 0.0, 0.5) * length(col), glitchFlash * 0.3);
    
    // Color enhancement for cyberpunk feel
    col.r = pow(col.r, 0.8); // Enhance reds
    col.b = pow(col.b, 0.9); // Slightly enhance blues
    
    // Final contrast enhancement
    col = pow(col, vec3(0.8));
    col *= 1.5;

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Cyberpunk Style",
    "description": "Cyberpunk visualization with neon glow, digital artifacts, and urban dystopian aesthetic",
    "model": "plane"
}
*/