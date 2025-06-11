// PetersenGraphIntersections.glsl - Visualization of PetersenGraph with intersection points
// Uses pre-calculated node positions and intersection points for better performance

const float INNER_RADIUS = 0.15;
const float MIDDLE_RADIUS = 0.3;
const float OUTER_RADIUS = 0.48;

// Pre-calculated node positions
const vec2 NODE_POSITIONS[20] = vec2[20](
    // Middle circle nodes (0-4)
    vec2(MIDDLE_RADIUS * cos(5.0265), MIDDLE_RADIUS * sin(5.0265)),
    vec2(MIDDLE_RADIUS * cos(0.0), MIDDLE_RADIUS * sin(0.0)),
    vec2(MIDDLE_RADIUS * cos(1.2566), MIDDLE_RADIUS * sin(1.2566)),
    vec2(MIDDLE_RADIUS * cos(2.5133), MIDDLE_RADIUS * sin(2.5133)),
    vec2(MIDDLE_RADIUS * cos(3.7699), MIDDLE_RADIUS * sin(3.7699)),
    // Inner circle nodes (5-9)
    vec2(INNER_RADIUS * cos(5.0265), INNER_RADIUS * sin(5.0265)),
    vec2(INNER_RADIUS * cos(0.0), INNER_RADIUS * sin(0.0)),
    vec2(INNER_RADIUS * cos(1.2566), INNER_RADIUS * sin(1.2566)),
    vec2(INNER_RADIUS * cos(2.5133), INNER_RADIUS * sin(2.5133)),
    vec2(INNER_RADIUS * cos(3.7699), INNER_RADIUS * sin(3.7699)),
    // Outer circle nodes (10-19)
    vec2(OUTER_RADIUS * cos(4.8521), OUTER_RADIUS * sin(4.8521)),
    vec2(OUTER_RADIUS * cos(0.1745), OUTER_RADIUS * sin(0.1745)),
    vec2(OUTER_RADIUS * cos(1.0821), OUTER_RADIUS * sin(1.0821)),
    vec2(OUTER_RADIUS * cos(2.6878), OUTER_RADIUS * sin(2.6878)),
    vec2(OUTER_RADIUS * cos(3.5954), OUTER_RADIUS * sin(3.5954)),
    vec2(OUTER_RADIUS * cos(5.2009), OUTER_RADIUS * sin(5.2009)),
    vec2(OUTER_RADIUS * cos(6.1087), OUTER_RADIUS * sin(6.1087)),
    vec2(OUTER_RADIUS * cos(1.4312), OUTER_RADIUS * sin(1.4312)),
    vec2(OUTER_RADIUS * cos(2.3387), OUTER_RADIUS * sin(2.3387)),
    vec2(OUTER_RADIUS * cos(3.9444), OUTER_RADIUS * sin(3.9444))
);

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

// Storage for calculated intersection points
vec2 intersectionPoints[20];
int intersectionTypes[20];
int intersectionCount = 0;
bool intersectionsCalculated = false;

// Get pre-calculated node position based on chainId
vec2 getNodePosition(int chainId) {
    return NODE_POSITIONS[chainId];
}

// Matrix for rotations
mat2 mm2(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Improved line intersection function with better precision
bool lineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4, inout vec2 intersection) {
    vec2 dir1 = p2 - p1;
    vec2 dir2 = p4 - p3;

    float denom = dir1.x * dir2.y - dir1.y * dir2.x;
    if(abs(denom) < 0.0001) {
        return false; // Lines are parallel
    }

    vec2 diff = p3 - p1;
    float t1 = (diff.x * dir2.y - diff.y * dir2.x) / denom;
    float t2 = (diff.x * dir1.y - diff.y * dir1.x) / denom;

    // Check if intersection is STRICTLY within both line segments
    // Exclude endpoints to avoid node intersections
    float tolerance = 0.05; // Minimum distance from endpoints
    if(t1 > tolerance && t1 < (1.0 - tolerance) && 
       t2 > tolerance && t2 < (1.0 - tolerance)) {
        intersection = p1 + t1 * dir1;
        
        // Additional check: ensure intersection is not too close to any node
        for(int nodeId = 0; nodeId < 20; nodeId++) {
            vec2 nodePos = getNodePosition(nodeId);
            if(length(intersection - nodePos) < 0.03) {
                return false; // Too close to a node
            }
        }
        
        return true;
    }
    return false;
}

// Calculate all intersection points (only once)
void calculateIntersections() {
    if(intersectionsCalculated) return;
    
    intersectionCount = 0;

    // Use the actual line intersection algorithm to find all intersections
    for(int i = 0; i < 30; i++) {
        for(int j = i + 1; j < 30; j++) {
            // Skip if the two connections share a common node
            if(CONNECTIONS[i].x == CONNECTIONS[j].x || 
               CONNECTIONS[i].x == CONNECTIONS[j].y ||
               CONNECTIONS[i].y == CONNECTIONS[j].x || 
               CONNECTIONS[i].y == CONNECTIONS[j].y) {
                continue; // Skip connections that share nodes
            }
            
            vec2 p1 = getNodePosition(CONNECTIONS[i].x);
            vec2 p2 = getNodePosition(CONNECTIONS[i].y);
            vec2 p3 = getNodePosition(CONNECTIONS[j].x);
            vec2 p4 = getNodePosition(CONNECTIONS[j].y);

            vec2 intersection = vec2(0.0);
            if(lineIntersection(p1, p2, p3, p4, intersection)) {
                if(intersectionCount < 20) {
                    intersectionPoints[intersectionCount] = intersection;

                    // Determine intersection type based on connection types
                    int type1 = CONN_TYPE[i];
                    int type2 = CONN_TYPE[j];

                    if(type1 == 3 && type2 == 3) {
                        intersectionTypes[intersectionCount] = 0; // Inner yellow intersections
                    } else if(type1 == 4 && type2 == 4) {
                        intersectionTypes[intersectionCount] = 1; // Outer magenta intersections
                    } else if((type1 == 4 && type2 == 1) || (type1 == 1 && type2 == 4)) {
                        intersectionTypes[intersectionCount] = 2; // Magenta-Green intersections
                    } else if((type1 == 4 && type2 == 2) || (type1 == 2 && type2 == 4)) {
                        intersectionTypes[intersectionCount] = 3; // Magenta-Blue intersections
                    } else {
                        intersectionTypes[intersectionCount] = 4; // Other intersections
                    }

                    intersectionCount++;
                }
            }
        }
    }
    
    intersectionsCalculated = true;
}

// Draw a simple circle node
vec4 drawSimpleNode(vec2 uv, vec2 pos, int chainId) {
    float dist = length(uv - pos);
    float nodeSize = 0.025;

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

// Draw intersection point with label
vec4 drawIntersectionPoint(vec2 uv, vec2 pos, int index, int type) {
    float dist = length(uv - pos);
    float pointSize = 0.015;

    // Color based on intersection type
    vec3 pointColor;
    switch(type) {
        case 0: pointColor = vec3(1.0, 1.0, 0.5); break; // Inner yellow intersections - bright yellow
        case 1: pointColor = vec3(1.0, 0.5, 1.0); break; // Outer magenta intersections - bright magenta
        case 2: pointColor = vec3(0.5, 1.0, 0.5); break; // Magenta-Green intersections - bright green
        case 3: pointColor = vec3(0.5, 0.7, 1.0); break; // Magenta-Blue intersections - bright blue
        default: pointColor = vec3(1.0, 1.0, 1.0); break; // Other - white
    }

    // Draw intersection point as a small circle
    float circle = smoothstep(pointSize, pointSize * 0.6, dist);
    
    // Add a thin border
    float border = smoothstep(pointSize * 1.2, pointSize, dist) - circle;
    vec3 finalColor = mix(vec3(0.0), pointColor, circle) + vec3(1.0) * border * 0.5;
    float alpha = max(circle, border * 0.5);
    
    return vec4(finalColor, alpha);
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
    // Calculate intersections only once
    calculateIntersections();
    
    // Background color - darker for contrast
    vec4 backgroundColor = vec4(0.05, 0.05, 0.08, 1.0);

    // Coordinate system
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

    // Scaling
    float globalScale = 0.7;
    uv = uv / globalScale;

    // Optional slow rotation
    float rotation = iTime * 0.02; // Slower rotation to see intersections clearly
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

    // 2. Draw intersection points using calculated data
    for(int i = 0; i < intersectionCount; i++) {
        vec2 pos = intersectionPoints[i] * rotMat;
        vec4 intersectionColor = drawIntersectionPoint(uv, pos, i, intersectionTypes[i]);
        fragColor.rgb = mix(fragColor.rgb, intersectionColor.rgb, intersectionColor.a);
    }

    // 3. Draw nodes on top of everything
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