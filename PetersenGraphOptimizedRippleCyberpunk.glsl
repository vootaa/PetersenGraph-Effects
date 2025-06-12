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

// Complete Petersen graph
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Slow rotation
    p *= rot(gTime * 0.05);
    
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
    
    // Simplified circuit pattern (removed complex pulse calculation)
    float circuit = step(0.7, noise(warpedP * 25.0));
    fillColor += circuit * vec3(0.3, 0.0, 0.2) * 0.2;
    
    col += solid * fillColor;
    

    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Optimized Ripple Cyberpunk",
    "description": "Performance optimized version with simplified effects",
    "model": "plane"
}
*/