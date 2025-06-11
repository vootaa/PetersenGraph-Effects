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

// Enhanced polygon distance field with animation support
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

// Dynamic shape scaling with pulsing effect
float shrinkShape(float d, float amount, float pulse) {
    return d + amount * (0.5 + 0.5 * pulse);
}

// Enhanced 1/5 part with individual polygon animations
float petersenPart(vec2 p, int partIndex) {
    float scale = 2.0;
    
    // Individual part scaling animation
    float partPhase = float(partIndex) * 0.4;
    float partScale = 1.0 + 0.3 * sin(gTime * 0.8 + partPhase);
    scale *= partScale;
    
    p /= scale;
    
    float shrink = 0.005;
    float globalPulse = sin(gTime * 1.5);
    
    // P1 Triangle with individual animation
    vec2 p1a = polar(0.060, radians(36.0));
    vec2 p1b = polar(0.060, radians(324.0));
    vec2 p1c = polar(0.150, 0.0);
    float pulse1 = sin(gTime * 2.0 + partPhase);
    float d1 = shrinkShape(sdTriangle(p, p1a, p1b, p1c), shrink, pulse1);
    
    // P2 Heptagon - main body with slower pulse
    vec2 p2a = polar(0.060, radians(36.0));
    vec2 p2b = polar(0.150, 0.0);
    vec2 p2c = polar(0.300, 0.0);
    vec2 p2d = polar(0.390, radians(6.0));
    vec2 p2e = polar(0.390, radians(66.0));
    vec2 p2f = polar(0.300, radians(72.0));
    vec2 p2g = polar(0.150, radians(72.0));
    float pulse2 = sin(gTime * 0.7 + partPhase * 0.5);
    float d2 = shrinkShape(sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g), shrink, pulse2);
    
    // P3-P6 with varied pulsing
    vec2 p3a = polar(0.300, 0.0);
    vec2 p3b = polar(0.390, radians(354.0));
    vec2 p3c = polar(0.416, 0.0);
    vec2 p3d = polar(0.390, radians(6.0));
    float pulse3 = sin(gTime * 1.8 + partPhase * 1.2);
    float d3 = shrinkShape(sdQuad(p, p3a, p3b, p3c, p3d), shrink, pulse3);
    
    vec2 p4a = polar(0.390, radians(6.0));
    vec2 p4b = polar(0.416, 0.0);
    vec2 p4c = polar(0.480, radians(10.0));
    float pulse4 = sin(gTime * 2.2 + partPhase * 0.8);
    float d4 = shrinkShape(sdTriangle(p, p4a, p4b, p4c), shrink, pulse4);
    
    vec2 p5a = polar(0.390, radians(6.0));
    vec2 p5b = polar(0.480, radians(10.0));
    vec2 p5c = polar(0.480, radians(62.0));
    vec2 p5d = polar(0.390, radians(66.0));
    float pulse5 = sin(gTime * 1.6 + partPhase * 1.5);
    float d5 = shrinkShape(sdQuad(p, p5a, p5b, p5c, p5d), shrink, pulse5);
    
    vec2 p6a = polar(0.390, radians(66.0));
    vec2 p6b = polar(0.480, radians(62.0));
    vec2 p6c = polar(0.416, radians(72.0));
    float pulse6 = sin(gTime * 2.4 + partPhase * 0.6);
    float d6 = shrinkShape(sdTriangle(p, p6a, p6b, p6c), shrink, pulse6);
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Enhanced Petersen graph with aggregation/separation effects
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Global rotation with variable speed
    float rotSpeed = 0.02 + 0.01 * sin(gTime * 0.3);
    p *= rot(gTime * rotSpeed);
    
    // Aggregation/separation effect
    float separation = 1.0 + 0.4 * sin(gTime * 0.6);
    
    // 5-fold rotational symmetry with dynamic separation
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * 72.0 * PI / 180.0;
        vec2 rotP = p * rot(-angle);
        
        // Apply separation effect
        rotP /= separation;
        
        d = min(d, petersenPart(rotP, i));
    }
    
    return d * separation;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    
    gTime = iTime;
    
    float d = petersenGraph(p);
    
    // Dynamic background with central vortex effect
    vec2 center = vec2(0.0);
    float centerDist = length(p - center);
    float vortex = sin(centerDist * 8.0 - gTime * 3.0) * 0.1 + 0.9;
    
    // Multi-layered background
    vec3 bgBase = vec3(0.15, 0.12, 0.25);
    vec3 bgVortex = vec3(0.3, 0.2, 0.5) * vortex;
    vec3 col = mix(bgBase, bgVortex, smoothstep(0.8, 0.2, centerDist));
    
    // Dynamic edge colors with rainbow effect
    float edgeWidth = 0.015 + 0.005 * sin(gTime * 4.0);
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    
    // Rainbow edge effect
    float hueShift = gTime * 0.5 + atan(p.y, p.x) / (2.0 * PI);
    vec3 edgeColor = vec3(
        sin(hueShift * 6.28) * 0.5 + 0.5,
        sin(hueShift * 6.28 + 2.09) * 0.5 + 0.5,
        sin(hueShift * 6.28 + 4.18) * 0.5 + 0.5
    );
    edgeColor = mix(vec3(1.0, 0.9, 0.6), edgeColor, 0.7);
    col += edge * edgeColor * 1.5;
    
    // Dynamic solid fill with depth effect
    float solid = smoothstep(0.008, -0.008, d);
    
    // Multi-colored fill based on distance from center
    vec3 fillNear = vec3(0.8, 0.4, 1.0);
    vec3 fillFar = vec3(0.2, 0.1, 0.6);
    vec3 fillColor = mix(fillFar, fillNear, smoothstep(0.6, 0.1, centerDist));
    
    // Add pulsing intensity
    float fillPulse = sin(gTime * 2.0) * 0.3 + 0.7;
    col += solid * fillColor * fillPulse;
    
    // Add glow effect around shapes
    float glow = smoothstep(0.05, 0.0, abs(d));
    col += glow * vec3(0.4, 0.6, 1.0) * 0.3;
    
    // Final color enhancement
    col = pow(col, vec3(0.9)); // Slight gamma correction
    col *= 1.2; // Brightness boost
    
    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Dynamic Effects",
    "description": "Enhanced Petersen Graph with aggregation, separation, and visual impact effects",
    "model": "plane"
}
*/