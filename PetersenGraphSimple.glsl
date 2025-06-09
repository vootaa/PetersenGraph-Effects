// PetersenGraphSimple.glsl - Simple clean visualization of PetersenGraph
// Uses basic circles for nodes and straight lines for connections

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

// Matrix for rotations
mat2 mm2(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Draw a simple circle node
vec4 drawSimpleNode(vec2 uv, vec2 pos, int chainId) {
    float dist = length(uv - pos);
    float nodeSize = 0.02;

    // Node base color
    vec3 nodeBaseColor;
    if(chainId < 5)
        nodeBaseColor = vec3(1.0, 0.2, 0.2);  // Red
    else if(chainId < 10)
        nodeBaseColor = vec3(0.2, 0.4, 1.0);  // Blue
    else
        nodeBaseColor = vec3(1.0, 0.8, 0.2);  // Yellow

    // Simple circle with smooth edge
    float circle = smoothstep(nodeSize, nodeSize * 0.7, dist);
    
    return vec4(nodeBaseColor, circle);
}

// Draw a simple straight line connection
vec4 drawSimpleLine(vec2 uv, vec2 p1, vec2 p2, int connType) {
    // Direction vector
    vec2 dir = p2 - p1;
    float len = length(dir);
    dir = normalize(dir);
    vec2 normal = vec2(-dir.y, dir.x);

    // Project uv onto the line segment
    vec2 uv_rel = uv - p1;
    float alongLine = dot(uv_rel, dir);
    float perpLine = abs(dot(uv_rel, normal));

    // Check if point is within line segment bounds
    if(alongLine < -0.005 || alongLine > len + 0.005)
        return vec4(0.0);

    // Line thickness
    float lineWidth = 0.002;

    // Simple color selection based on connection type
    vec3 lineColor;
    switch(connType) {
        case 0:
            lineColor = vec3(0.9, 0.2, 0.2);
            break;  // Bright Red - Middle to inner circle
        case 1:
            lineColor = vec3(0.2, 0.8, 0.2);
            break;  // Bright Green - Middle to outer circle (+10)
        case 2:
            lineColor = vec3(0.2, 0.4, 1.0);
            break;  // Bright Blue - Middle to outer circle (+15)
        case 3:
            lineColor = vec3(1.0, 0.8, 0.0);
            break;  // Yellow - Inner circle connections
        case 4:
            lineColor = vec3(0.9, 0.4, 0.9);
            break;  // Magenta - Outer circle connections
        default:
            lineColor = vec3(0.6, 0.6, 0.6);  // Gray
    }

    // Draw line with smooth edges
    float line = smoothstep(lineWidth, lineWidth * 0.5, perpLine);
    
    return vec4(lineColor, line * 0.8);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Background color - darker for contrast
    vec4 backgroundColor = vec4(0.05, 0.05, 0.08, 1.0);

    // Coordinate system
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

    // Scaling
    float globalScale = 0.7;
    uv = uv / globalScale;

    // Optional slow rotation
    float rotation = iTime * 0.05;
    mat2 rotMat = mm2(rotation);

    // Initialize color
    fragColor = backgroundColor;

    // 1. Draw connections first (so nodes appear on top)
    for(int i = 0; i < 30; i++) {
        int fromId = CONNECTIONS[i].x;
        int toId = CONNECTIONS[i].y;
        int connType = CONN_TYPE[i];

        vec2 fromPos = getNodePosition(fromId) * rotMat;
        vec2 toPos = getNodePosition(toId) * rotMat;

        vec4 lineColor = drawSimpleLine(uv, fromPos, toPos, connType);
        fragColor.rgb = mix(fragColor.rgb, lineColor.rgb, lineColor.a);
    }

    // 2. Draw nodes on top of connections
    for(int i = 0; i < 20; i++) {
        vec2 pos = getNodePosition(i) * rotMat;
        vec4 nodeColor = drawSimpleNode(uv, pos, i);
        fragColor.rgb = mix(fragColor.rgb, nodeColor.rgb, nodeColor.a);
    }

    // Subtle vignette effect
    float vignette = 1.0 - smoothstep(0.6, 1.2, length(fragCoord / iResolution.xy - 0.5));
    fragColor.rgb *= vignette * 1.1;

    // Ensure alpha is 1.0
    fragColor.a = 1.0;
}