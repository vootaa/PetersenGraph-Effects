// PetersenPlasmaGraph.glsl - Dynamic visualization of PetersenGraph
// Combines Petersen Graph topology with Plasma visualization effects

// Angles for node positioning (in radians)
const float ANGLES[20] = float[20](
    // Middle circle (chainId 0-4) - Evenly distributed on the circle
5.0265, 0.0, 1.2566, 2.5133, 3.7699,
    // Inner circle (chainId 5-9) - Corresponding to middle circle angles
5.0265, 0.0, 1.2566, 2.5133, 3.7699,
    // Outer circle (chainId 10-19)
4.8521, 0.1745, 1.0821, 2.6878, 3.5954, 5.2009, 6.1087, 1.4312, 2.3387, 3.9444);

const float INNER_RADIUS = 0.15;
const float MIDDLE_RADIUS = 0.3;
const float OUTER_RADIUS = 0.48;

// Connection lookup table (from, to)
const ivec2 CONNECTIONS[30] = ivec2[30](
    // Middle to inner (+5 pattern)
ivec2(0, 5), ivec2(1, 6), ivec2(2, 7), ivec2(3, 8), ivec2(4, 9),
    // Middle to outer (+10 pattern)
ivec2(0, 10), ivec2(1, 11), ivec2(2, 12), ivec2(3, 13), ivec2(4, 14),
    // Middle to outer (+15 pattern)
ivec2(0, 15), ivec2(1, 16), ivec2(2, 17), ivec2(3, 18), ivec2(4, 19),
    // Inner circle connections
ivec2(5, 7), ivec2(6, 8), ivec2(7, 9), ivec2(8, 5), ivec2(9, 6),
    // Outer circle connections
ivec2(10, 11), ivec2(11, 12), ivec2(12, 13), ivec2(13, 14), ivec2(14, 15), ivec2(15, 16), ivec2(16, 17), ivec2(17, 18), ivec2(18, 19), ivec2(19, 10));

// Connection types for coloring
const int CONN_TYPE[30] = int[30](
    // Connection types by group
0, 0, 0, 0, 0,  // Middle to inner
1, 1, 1, 1, 1,  // Middle to outer (+10)
2, 2, 2, 2, 2,  // Middle to outer (+15)
3, 3, 3, 3, 3,  // Inner circle
4, 4, 4, 4, 4, 4, 4, 4, 4, 4  // Outer circle
);

// Get node position based on chainId
vec2 getNodePosition(int chainId) {
    float angle = ANGLES[chainId];
    float radius;

    if(chainId < 5)
        radius = MIDDLE_RADIUS;
    else if(chainId < 10)
        radius = INNER_RADIUS;
    else
        radius = OUTER_RADIUS;

    return vec2(radius * cos(angle), radius * sin(angle));
}

// Hash function from PlasmaGlobe
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// Simplified noise function using basic smooth interpolation
float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f); // Smooth interpolation
    float n = p.x + p.y * 57.0;
    float res = mix(mix(hash(n), hash(n + 1.0), f.x), mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
    return res;
}

// Matrix for rotations
mat2 mm2(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Flow effect function
float flow(in vec2 p, in float t) {
    float z = 2.0;
    float rz = 0.0;
    vec2 bp = p;

    for(float i = 1.0; i < 3.0; i++) {
        p += iTime * 0.1;
        float n = noise(p * 4.0 + t * 0.8); // Lower frequency
        rz += (sin(n * 6.0) * 0.5 + 0.5) / z;
        p = mix(bp, p, 0.6);
        z *= 2.0;
        p *= 2.01;
        p = p * mm2(iTime * 0.04 * i);
    }
    return rz;
}

// Draw a node with plasma effect
vec4 drawNode(vec2 uv, vec2 pos, int chainId) {
    float dist = length(uv - pos);
    float nodeSize = 0.025;

    // Node base color
    vec3 nodeBaseColor;
    if(chainId < 5)
        nodeBaseColor = vec3(1.0, 0.0, 0.0);  // Red
    else if(chainId < 10)
        nodeBaseColor = vec3(0.0, 0.0, 1.0);  // Blue
    else
        nodeBaseColor = vec3(1.0, 1.0, 0.0);   // Yellow

    // Flow effect calculation
    float flowEffect = flow(uv * 15.0, iTime * 0.2 + float(chainId));
    float glowSize = nodeSize * (1.8 + 0.4 * sin(iTime * 2.0 + float(chainId)));

    // Core and glow effect
    float core = smoothstep(nodeSize, nodeSize * 0.4, dist);
    float glow = smoothstep(glowSize, nodeSize, dist) * 0.8 * flowEffect;

    vec3 nodeColor = mix(nodeBaseColor, vec3(1.0), 0.3 + 0.3 * flowEffect);
    float alpha = max(core, glow * 0.8);
    vec3 finalColor = nodeColor * (core + glow * 1.2);

    return vec4(finalColor, alpha);
}

vec4 drawPlasmaConnection(vec2 uv, vec2 p1, vec2 p2, int connType, float seed) {
    // Direction vector and distance to the point
    vec2 dir = p2 - p1;
    float len = length(dir);
    dir = normalize(dir);
    vec2 normal = vec2(-dir.y, dir.x);

    // Project uv onto the line segment
    vec2 uv_rel = uv - p1;
    float alongLine = dot(uv_rel, dir);
    float perpLine = dot(uv_rel, normal);

    // Return if outside the line segment range
    if(alongLine < -0.01 || alongLine > len + 0.01)
        return vec4(0.0);

    // Normalize along-line position (0-1)
    float normAlong = clamp(alongLine / len, 0.0, 1.0);
    float time = iTime * 1.1;

    // Simplified color selection
    vec3 baseColor;
    switch(connType) {
        case 0:
            baseColor = vec3(1.0, 0.4, 0.3);
            break;  // Red - Middle to inner circle
        case 1:
            baseColor = vec3(0.9, 0.7, 0.3);
            break;  // Gold - Middle to outer circle (+10)
        case 2:
            baseColor = vec3(0.22, 0.59, 0.96);
            break; // Blue - Middle to outer circle (+15)
        case 3:
            baseColor = vec3(0.3, 0.9, 1.0);
            break;  // Cyan - Inner circle connections
        case 4:
            baseColor = vec3(1.0, 1.0, 0.21);
            break; // Yellow - Outer circle connections
        default:
            baseColor = vec3(0.7, 0.7, 0.7);        // Gray
    }

    // Base arc width remains constant
    float arcWidth = 0.0025 * (0.8 + 0.2 * len / 0.5);

    float distortionAmount;

    // Determine connection ring type
    if(connType == 3) {
        // Inner circle connections - Minimum distortion
        distortionAmount = 0.008;
    } else if(connType == 0) {
        // Middle to inner circle - Small distortion
        distortionAmount = 0.015;
    } else if(connType == 1 || connType == 2) {
        // Middle to outer circle - Moderate distortion
        distortionAmount = 0.02;
    } else if(connType == 4) {
        // Outer circle connections - Maximum distortion
        distortionAmount = 0.025;
    } else {
        // Default
        distortionAmount = 0.02;
    }

    float lowFreq = 5.0;
    float highFreq = 20.0;

    // Use only two noise layers, but adjust frequency based on connection type
    float noise1 = noise(vec2(normAlong * lowFreq + time * 0.5, seed * 10.0)) * 2.0 - 1.0;  // Low frequency
    float noise2 = noise(vec2(normAlong * highFreq - time * 0.7, seed * 5.0)) * 2.0 - 1.0;  // High frequency

    // Combine noise layers - Simplified to two layers
    float combinedNoise = noise1 * 0.7 + noise2 * 0.3;

    // Calculate distorted distance
    float distortedDist = abs(perpLine - distortionAmount * combinedNoise);

    // Main arc path, fixed thickness
    float thickness = arcWidth * (0.6 + 0.4 * noise(vec2(normAlong * 5.0, time * 0.3 + seed * 10.0)));

    // Main arc rendering
    float mainArc = smoothstep(thickness, thickness * 0.3, distortedDist);

    // Glow effect
    float glow = 0.2 / (1.0 + 15.0 * distortedDist * distortedDist);

    // Color variation
    vec3 arcColor = baseColor + 0.2 * sin(vec3(3.0, 1.0, 2.0) * (time * 0.5 + normAlong * 3.0));

    // Flicker effect - Adjust flicker speed and amplitude
    float flickerSpeed = 3.0;

    float flickerAmount;
    if(connType == 3) {
        // Inner circle - Slower flicker, smaller amplitude
        flickerAmount = 0.2;
    } else if(connType == 0) {
        // Middle to inner circle
        flickerAmount = 0.25;
    } else if(connType == 1 || connType == 2) {
        // Middle to outer circle
        flickerAmount = 0.3;
    } else {
        // Outer circle - Faster flicker, larger amplitude
        flickerAmount = 0.35;
    }

    float flicker = (1.0 - flickerAmount) + flickerAmount * sin(time * (flickerSpeed + seed * 3.0) + normAlong * 4.0);
    float arcIntensity = mainArc * flicker * 1.2 + glow * 0.9;

    vec3 finalColor = arcColor * arcIntensity;

    // Spark effect
    float sparkThreshold = 0.9;

    if(noise(vec2(time * 5.0 + seed * 15.0, normAlong * 10.0)) > sparkThreshold) {
        // Outer circle sparks are larger and brighter
        float sparkSize = (connType == 4) ? 25.0 : 20.0;
        float sparkDist = length(vec2(normAlong - noise(vec2(time * 1.5, seed)) * 0.08, perpLine) * sparkSize);
        float sparkBrightness = (connType == 4) ? 1.2 : 0.7;
        float spark = sparkBrightness / (1.0 + sparkDist * sparkDist);
        finalColor += arcColor * spark;
    }

    // Alpha value
    float alpha = min(arcIntensity * 0.8, 1.0);

    return vec4(finalColor, alpha);
}

// Circle drawing function
vec4 drawCircle(vec2 uv, float radius, vec3 color, float time) {
    // Distance to the center
    float dist = length(uv);

    // Fixed circle width
    float thickness = 0.003;

    // Simple circle
    float ring = smoothstep(radius + thickness, radius, dist) *
        smoothstep(radius - thickness, radius, dist);

    // Return color
    return vec4(color * ring, ring * 0.8);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Background color
    vec4 backgroundColor = vec4(0.02, 0.02, 0.05, 1.0);

    // Coordinate system
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

    // Scaling
    float globalScale = 0.7;
    uv = uv / globalScale;

    // Rotation
    float rotation = iTime * 0.1;
    mat2 rotMat = mm2(rotation);
    vec2 rotatedUv = uv * rotMat;

    // Initialize color
    fragColor = backgroundColor;

    // 1. Draw concentric circles
    vec3 innerCircleColor = vec3(0.3, 0.8, 1.0) * 0.5;  // Inner circle color - Blue
    vec3 middleCircleColor = vec3(1.0, 0.5, 0.3) * 0.5; // Middle circle color - Red
    vec3 outerCircleColor = vec3(1.0, 1.0, 0.4) * 0.5;  // Outer circle color - Yellow

    vec4 innerCircle = drawCircle(rotatedUv, INNER_RADIUS, innerCircleColor, iTime);
    vec4 middleCircle = drawCircle(rotatedUv, MIDDLE_RADIUS, middleCircleColor, iTime * 0.8);
    vec4 outerCircle = drawCircle(rotatedUv, OUTER_RADIUS, outerCircleColor, iTime * 0.6);

    // Blend circles
    fragColor.rgb = mix(fragColor.rgb, innerCircle.rgb, innerCircle.a);
    fragColor.rgb = mix(fragColor.rgb, middleCircle.rgb, middleCircle.a);
    fragColor.rgb = mix(fragColor.rgb, outerCircle.rgb, outerCircle.a);

    // 2. Draw arcs
    for(int i = 0; i < 30; i++) {
        int fromId = CONNECTIONS[i].x;
        int toId = CONNECTIONS[i].y;
        int connType = CONN_TYPE[i];

        vec2 fromPos = getNodePosition(fromId) * rotMat;
        vec2 toPos = getNodePosition(toId) * rotMat;

        float seed = float(i) * 0.1;

        vec4 arcColor = drawPlasmaConnection(uv, fromPos, toPos, connType, seed);
        fragColor.rgb = mix(fragColor.rgb, arcColor.rgb, arcColor.a * 0.7);
    }

    // 3. Draw nodes
    for(int i = 0; i < 20; i++) {
        vec2 pos = getNodePosition(i) * rotMat;
        vec4 nodeColor = drawNode(uv, pos, i);
        fragColor.rgb = mix(fragColor.rgb, nodeColor.rgb, nodeColor.a * 0.9);
    }

    // Add vignette effect
    float vignette = 1.0 - smoothstep(0.5, 1.8, length(fragCoord / iResolution.xy - 0.5) * 1.1);
    fragColor.rgb *= vignette * 1.2;

    // Remove redundant background plasma effect

    // Ensure alpha is 1.0
    fragColor.a = 1.0;
}