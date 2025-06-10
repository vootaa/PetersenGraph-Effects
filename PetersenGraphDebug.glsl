// PetersenGraphDebug.glsl - Debug version showing node and intersection indices
// Displays index numbers at each position for polygon definition debugging

// Pre-calculated node positions (same as original)
const float INNER_RADIUS = 0.15;
const float MIDDLE_RADIUS = 0.3;
const float OUTER_RADIUS = 0.48;

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

// Connection lookup table (same as original)
const ivec2 CONNECTIONS[30] = ivec2[30](
    ivec2(0, 5), ivec2(1, 6), ivec2(2, 7), ivec2(3, 8), ivec2(4, 9),
    ivec2(0, 10), ivec2(1, 11), ivec2(2, 12), ivec2(3, 13), ivec2(4, 14),
    ivec2(0, 15), ivec2(1, 16), ivec2(2, 17), ivec2(3, 18), ivec2(4, 19),
    ivec2(5, 7), ivec2(6, 8), ivec2(7, 9), ivec2(8, 5), ivec2(9, 6),
    ivec2(10, 11), ivec2(11, 12), ivec2(12, 13), ivec2(13, 14), ivec2(14, 15), 
    ivec2(15, 16), ivec2(16, 17), ivec2(17, 18), ivec2(18, 19), ivec2(19, 10)
);

const int CONN_TYPE[30] = int[30](
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

// Get node position
vec2 getNodePosition(int chainId) {
    return NODE_POSITIONS[chainId];
}

// Matrix for rotations
mat2 mm2(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Line intersection function (same as original)
bool lineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4, inout vec2 intersection) {
    vec2 dir1 = p2 - p1;
    vec2 dir2 = p4 - p3;

    float denom = dir1.x * dir2.y - dir1.y * dir2.x;
    if(abs(denom) < 0.0001) return false;

    vec2 diff = p3 - p1;
    float t1 = (diff.x * dir2.y - diff.y * dir2.x) / denom;
    float t2 = (diff.x * dir1.y - diff.y * dir1.x) / denom;

    float tolerance = 0.05;
    if(t1 > tolerance && t1 < (1.0 - tolerance) && 
       t2 > tolerance && t2 < (1.0 - tolerance)) {
        intersection = p1 + t1 * dir1;
        
        for(int nodeId = 0; nodeId < 20; nodeId++) {
            vec2 nodePos = getNodePosition(nodeId);
            if(length(intersection - nodePos) < 0.03) {
                return false;
            }
        }
        return true;
    }
    return false;
}

// Calculate all intersection points
void calculateIntersections() {
    if(intersectionsCalculated) return;
    
    intersectionCount = 0;
    for(int i = 0; i < 30; i++) {
        for(int j = i + 1; j < 30; j++) {
            if(CONNECTIONS[i].x == CONNECTIONS[j].x || 
               CONNECTIONS[i].x == CONNECTIONS[j].y ||
               CONNECTIONS[i].y == CONNECTIONS[j].x || 
               CONNECTIONS[i].y == CONNECTIONS[j].y) {
                continue;
            }
            
            vec2 p1 = getNodePosition(CONNECTIONS[i].x);
            vec2 p2 = getNodePosition(CONNECTIONS[i].y);
            vec2 p3 = getNodePosition(CONNECTIONS[j].x);
            vec2 p4 = getNodePosition(CONNECTIONS[j].y);

            vec2 intersection = vec2(0.0);
            if(lineIntersection(p1, p2, p3, p4, intersection)) {
                if(intersectionCount < 20) {
                    intersectionPoints[intersectionCount] = intersection;

                    int type1 = CONN_TYPE[i];
                    int type2 = CONN_TYPE[j];

                    if(type1 == 3 && type2 == 3) {
                        intersectionTypes[intersectionCount] = 0; // Inner yellow
                    } else if(type1 == 4 && type2 == 4) {
                        intersectionTypes[intersectionCount] = 1; // Outer magenta
                    } else if((type1 == 4 && type2 == 1) || (type1 == 1 && type2 == 4)) {
                        intersectionTypes[intersectionCount] = 2; // Magenta-Green
                    } else if((type1 == 4 && type2 == 2) || (type1 == 2 && type2 == 4)) {
                        intersectionTypes[intersectionCount] = 3; // Magenta-Blue
                    } else {
                        intersectionTypes[intersectionCount] = 4; // Other
                    }

                    intersectionCount++;
                }
            }
        }
    }
    
    intersectionsCalculated = true;
}

// Simple digit rendering function
float drawDigit(vec2 uv, int digit, vec2 position, float size) {
    vec2 localUV = (uv - position) / size;
    
    // Normalize to [0,1] for digit drawing
    localUV = localUV * 0.5 + 0.5;
    
    // Return 0 if outside bounds
    if(localUV.x < 0.0 || localUV.x > 1.0 || localUV.y < 0.0 || localUV.y > 1.0) {
        return 0.0;
    }
    
    // Simple 7-segment style digit patterns
    float result = 0.0;
    
    // Define segments as rectangles
    float segWidth = 0.15;
    float segHeight = 0.08;
    
    // Horizontal segments
    float topSeg = step(0.2, localUV.x) * step(localUV.x, 0.8) * step(0.85, localUV.y) * step(localUV.y, 1.0);
    float midSeg = step(0.2, localUV.x) * step(localUV.x, 0.8) * step(0.45, localUV.y) * step(localUV.y, 0.55);
    float botSeg = step(0.2, localUV.x) * step(localUV.x, 0.8) * step(0.0, localUV.y) * step(localUV.y, 0.15);
    
    // Vertical segments
    float topLeftSeg = step(0.0, localUV.x) * step(localUV.x, 0.15) * step(0.55, localUV.y) * step(localUV.y, 0.85);
    float topRightSeg = step(0.85, localUV.x) * step(localUV.x, 1.0) * step(0.55, localUV.y) * step(localUV.y, 0.85);
    float botLeftSeg = step(0.0, localUV.x) * step(localUV.x, 0.15) * step(0.15, localUV.y) * step(localUV.y, 0.45);
    float botRightSeg = step(0.85, localUV.x) * step(localUV.x, 1.0) * step(0.15, localUV.y) * step(localUV.y, 0.45);
    
    // Digit patterns
    if(digit == 0) {
        result = topSeg + topLeftSeg + topRightSeg + botLeftSeg + botRightSeg + botSeg;
    } else if(digit == 1) {
        result = topRightSeg + botRightSeg;
    } else if(digit == 2) {
        result = topSeg + topRightSeg + midSeg + botLeftSeg + botSeg;
    } else if(digit == 3) {
        result = topSeg + topRightSeg + midSeg + botRightSeg + botSeg;
    } else if(digit == 4) {
        result = topLeftSeg + topRightSeg + midSeg + botRightSeg;
    } else if(digit == 5) {
        result = topSeg + topLeftSeg + midSeg + botRightSeg + botSeg;
    } else if(digit == 6) {
        result = topSeg + topLeftSeg + midSeg + botLeftSeg + botRightSeg + botSeg;
    } else if(digit == 7) {
        result = topSeg + topRightSeg + botRightSeg;
    } else if(digit == 8) {
        result = topSeg + topLeftSeg + topRightSeg + midSeg + botLeftSeg + botRightSeg + botSeg;
    } else if(digit == 9) {
        result = topSeg + topLeftSeg + topRightSeg + midSeg + botRightSeg + botSeg;
    }
    
    return clamp(result, 0.0, 1.0);
}

// Draw a number with color based on range, showing only ones digit
float drawNumber(vec2 uv, int number, vec2 position, float size) {
    // Only draw the ones digit
    int ones = number % 10;
    return drawDigit(uv, ones, position, size);
}

// Get color based on number range
vec3 getNumberColor(int number) {
    if(number >= 0 && number <= 9) {
        return vec3(1.0, 1.0, 1.0);      // 0-9: White
    } else if(number >= 10 && number <= 19) {
        return vec3(1.0, 0.3, 0.3);      // 10-19: Red
    } else if(number >= 20 && number <= 29) {
        return vec3(0.3, 0.5, 1.0);      // 20-29: Blue
    } else if(number >= 30 && number <= 39) {
        return vec3(1.0, 1.0, 0.3);      // 30-39: Yellow
    } else {
        return vec3(0.8, 0.8, 0.8);      // Others: Gray
    }
}

// Draw connection lines (simplified)
vec4 drawSimpleLine(vec2 uv, vec2 p1, vec2 p2, int connType) {
    vec2 dir = p2 - p1;
    float len = length(dir);
    if(len < 0.001) return vec4(0.0);
    
    dir = normalize(dir);
    vec2 normal = vec2(-dir.y, dir.x);
    
    vec2 uv_rel = uv - p1;
    float alongLine = dot(uv_rel, dir);
    float perpLine = abs(dot(uv_rel, normal));
    
    if(alongLine < -0.005 || alongLine > len + 0.005) return vec4(0.0);
    
    float lineWidth = 0.002;
    
    // Dim line colors for debug mode
    vec3 lineColor = vec3(0.3, 0.8, 0.3);
    float line = smoothstep(lineWidth, lineWidth * 0.5, perpLine);
    return vec4(lineColor, line * 0.3);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    calculateIntersections();

    vec4 backgroundColor = vec4(0.02, 0.02, 0.05, 1.0);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

    float globalScale = 0.7;
    uv = uv / globalScale;

    // Slower rotation for easier reading
    float rotation = iTime * 0.01;
    mat2 rotMat = mm2(rotation);

    fragColor = backgroundColor;

    // 1. Draw dim connection lines first
    for(int i = 0; i < 30; i++) {
        int fromId = CONNECTIONS[i].x;
        int toId = CONNECTIONS[i].y;
        int connType = CONN_TYPE[i];

        vec2 fromPos = getNodePosition(fromId) * rotMat;
        vec2 toPos = getNodePosition(toId) * rotMat;

        vec4 lineColor = drawSimpleLine(uv, fromPos, toPos, connType);
        fragColor.rgb = mix(fragColor.rgb, lineColor.rgb, lineColor.a);
    }

    // 2. Draw node index numbers (only ones digit, color by range)
    for(int i = 0; i < 20; i++) {
        vec2 pos = getNodePosition(i) * rotMat;

        // Color based on number range
        vec3 numberColor = getNumberColor(i);

        float number = drawNumber(uv, i, pos, 0.015);
        fragColor.rgb = mix(fragColor.rgb, numberColor, number);
    }

    // 3. Draw intersection index numbers (only ones digit, color by range)
    for(int i = 0; i < intersectionCount; i++) {
        vec2 pos = intersectionPoints[i] * rotMat;

        int displayNumber = 20 + i;

        // Color based on number range
        vec3 numberColor = getNumberColor(displayNumber);

        float number = drawNumber(uv, displayNumber, pos, 0.015);
        fragColor.rgb = mix(fragColor.rgb, numberColor, number);
    }

    fragColor.a = 1.0;
}