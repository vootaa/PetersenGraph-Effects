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

// Enhanced 1/5 part with 3D separation and individual polygon animation
float petersenPart(vec2 p, int partIndex, float separation, float depth) {
    float scale = 2.0;
    p /= scale;
    
    float shrink = 0.003; // Thinner edges
    
    // Individual polygon positioning with 3D-like separation
    vec2 offsets[6];
    float separationAmount = separation * 0.05;
    
    // P1 Triangle offset (center-inward)
    offsets[0] = vec2(-separationAmount * 0.5, 0.0);
    
    // P2 Heptagon offset (stays central)
    offsets[1] = vec2(0.0, 0.0);
    
    // P3-P6 offsets (outward radial)
    offsets[2] = vec2(separationAmount, 0.0);
    offsets[3] = vec2(separationAmount * 0.7, separationAmount * 0.7);
    offsets[4] = vec2(0.0, separationAmount);
    offsets[5] = vec2(-separationAmount * 0.7, separationAmount * 0.7);
    
    // P1 Triangle with 3D effect
    vec2 p1a = polar(0.060, radians(36.0)) + offsets[0];
    vec2 p1b = polar(0.060, radians(324.0)) + offsets[0];
    vec2 p1c = polar(0.150, 0.0) + offsets[0];
    float d1 = sdTriangle(p, p1a, p1b, p1c) + shrink + depth * 0.01;
    
    // P2 Heptagon (main body)
    vec2 p2a = polar(0.060, radians(36.0)) + offsets[1];
    vec2 p2b = polar(0.150, 0.0) + offsets[1];
    vec2 p2c = polar(0.300, 0.0) + offsets[1];
    vec2 p2d = polar(0.390, radians(6.0)) + offsets[1];
    vec2 p2e = polar(0.390, radians(66.0)) + offsets[1];
    vec2 p2f = polar(0.300, radians(72.0)) + offsets[1];
    vec2 p2g = polar(0.150, radians(72.0)) + offsets[1];
    float d2 = sdHeptagon(p, p2a, p2b, p2c, p2d, p2e, p2f, p2g) + shrink;
    
    // P3 Quadrilateral
    vec2 p3a = polar(0.300, 0.0) + offsets[2];
    vec2 p3b = polar(0.390, radians(354.0)) + offsets[2];
    vec2 p3c = polar(0.416, 0.0) + offsets[2];
    vec2 p3d = polar(0.390, radians(6.0)) + offsets[2];
    float d3 = sdQuad(p, p3a, p3b, p3c, p3d) + shrink + depth * 0.008;
    
    // P4 Triangle
    vec2 p4a = polar(0.390, radians(6.0)) + offsets[3];
    vec2 p4b = polar(0.416, 0.0) + offsets[3];
    vec2 p4c = polar(0.480, radians(10.0)) + offsets[3];
    float d4 = sdTriangle(p, p4a, p4b, p4c) + shrink + depth * 0.012;
    
    // P5 Quadrilateral
    vec2 p5a = polar(0.390, radians(6.0)) + offsets[4];
    vec2 p5b = polar(0.480, radians(10.0)) + offsets[4];
    vec2 p5c = polar(0.480, radians(62.0)) + offsets[4];
    vec2 p5d = polar(0.390, radians(66.0)) + offsets[4];
    float d5 = sdQuad(p, p5a, p5b, p5c, p5d) + shrink + depth * 0.006;
    
    // P6 Triangle
    vec2 p6a = polar(0.390, radians(66.0)) + offsets[5];
    vec2 p6b = polar(0.480, radians(62.0)) + offsets[5];
    vec2 p6c = polar(0.416, radians(72.0)) + offsets[5];
    float d6 = sdTriangle(p, p6a, p6b, p6c) + shrink + depth * 0.01;
    
    return min(min(min(min(min(d1, d2), d3), d4), d5), d6);
}

// Background polygons for visual richness
float backgroundPolygons(vec2 p) {
    float d = 1e6;
    
    // Multiple layers of background polygons at different scales and rotations
    for(int layer = 0; layer < 3; layer++) {
        float layerScale = 0.3 + float(layer) * 0.4;
        float layerRotation = gTime * (0.1 + float(layer) * 0.05);
        float layerAlpha = 0.8 - float(layer) * 0.25;
        
        vec2 layerP = p * rot(layerRotation) / layerScale;
        
        for(int i = 0; i < 8; i++) {
            float angle = float(i) * 45.0 * PI / 180.0;
            vec2 rotP = layerP * rot(-angle);
            rotP.x += 2.0 + float(layer) * 0.5;
            
            // Simple triangle for background
            vec2 ta = vec2(0.0, 0.1);
            vec2 tb = vec2(-0.05, -0.05);
            vec2 tc = vec2(0.05, -0.05);
            float bgD = sdTriangle(rotP, ta, tb, tc) + 0.02;
            d = min(d, bgD);
        }
    }
    
    return d;
}

// Turbine-style aggregation/dispersion
float petersenGraph(vec2 p) {
    float d = 1e6;
    
    // Turbine rotation with variable speed
    float turbinePhase = sin(gTime * 0.3) * 0.5 + 0.5;
    float rotSpeed = 0.05 + turbinePhase * 0.15;
    p *= rot(gTime * rotSpeed);
    
    // Aggregation factor: 0 = fully dispersed, 1 = fully aggregated
    float aggregation = sin(gTime * 0.4) * 0.5 + 0.5;
    aggregation = smoothstep(0.0, 1.0, aggregation);
    
    // Dispersion distance
    float maxDispersion = 1.5;
    float dispersionRadius = maxDispersion * (1.0 - aggregation);
    
    // Individual polygon separation within each part
    float polygonSeparation = sin(gTime * 0.6) * 0.5 + 0.5;
    
    // 5-fold rotational symmetry with turbine dispersion
    for(int i = 0; i < 5; i++) {
        float partAngle = float(i) * 72.0 * PI / 180.0;
        
        // Turbine spiral effect
        float spiralOffset = gTime * 0.8 + float(i) * 0.4;
        float turbineAngle = partAngle + sin(spiralOffset) * (1.0 - aggregation) * 2.0;
        
        // Position offset for dispersion
        vec2 offset = polar(dispersionRadius, turbineAngle);
        vec2 rotP = (p - offset) * rot(-partAngle);
        
        // Individual part scale based on dispersion
        float partScale = 0.8 + (1.0 - aggregation) * 0.4;
        rotP /= partScale;
        
        // Depth effect for 3D appearance
        float depth = sin(gTime * 1.2 + float(i) * 1.5) * 0.5 + 0.5;
        
        float partD = petersenPart(rotP, i, polygonSeparation, depth);
        d = min(d, partD * partScale);
    }
    
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    
    gTime = iTime;
    
    float d = petersenGraph(p);
    float bgD = backgroundPolygons(p);
    
    vec3 col = vec3(0.0);
    
    // Rich background with polygon patterns
    float bgSolid = smoothstep(0.01, -0.01, bgD);
    col += bgSolid * vec3(0.08, 0.06, 0.15) * 0.5;
    
    float bgEdge = smoothstep(0.005, 0.0, abs(bgD));
    col += bgEdge * vec3(0.2, 0.15, 0.3) * 0.3;
    
    // Base background
    vec2 center = vec2(0.0);
    float centerDist = length(p);
    vec3 bgGradient = mix(
        vec3(0.25, 0.20, 0.45),
        vec3(0.15, 0.12, 0.25),
        smoothstep(0.0, 1.5, centerDist)
    );
    col += bgGradient * (1.0 - bgSolid * 0.5);
    
    // Main Petersen graph with thin edges
    float edgeWidth = 0.004; // Much thinner edges
    float edge = smoothstep(edgeWidth, 0.0, abs(d));
    
    // Dynamic edge colors
    float hue = gTime * 0.3 + atan(p.y, p.x);
    vec3 edgeColor = vec3(
        sin(hue) * 0.3 + 0.7,
        sin(hue + 2.0) * 0.3 + 0.7,
        sin(hue + 4.0) * 0.3 + 0.7
    );
    col += edge * edgeColor * 1.8;
    
    // Solid fill with depth variation
    float solid = smoothstep(0.002, -0.002, d);
    
    // Multi-layered fill colors
    vec3 fillColor = mix(
        vec3(0.6, 0.4, 0.9),
        vec3(0.3, 0.2, 0.7),
        smoothstep(0.5, 0.0, centerDist)
    );
    
    // Pulsing intensity
    float pulse = sin(gTime * 2.5) * 0.2 + 0.8;
    col += solid * fillColor * pulse;
    
    // Glow effect
    float glow = smoothstep(0.02, 0.0, abs(d));
    col += glow * vec3(0.4, 0.3, 0.8) * 0.4;
    
    // Final enhancement
    col = pow(col, vec3(0.85));
    col *= 1.3;
    
    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Petersen Graph - Turbine Effects",
    "description": "Enhanced Petersen Graph with turbine aggregation, polygon separation, and rich background",
    "model": "plane"
}
*/