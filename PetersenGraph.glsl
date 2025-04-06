// PetersenGraph.glsl - Dynamic visualization of PetersenGraph
// Based on ChainWeb Petersen Graph specification with clean mathematical visualization

// Angles for node positioning (in radians)
const float ANGLES[20] = float[20](
    // Middle circle (chainId 0-4)
5.0265, 0.0, 1.2566, 2.5133, 3.7699,
    // Inner circle (chainId 5-9)
5.0265, 0.0, 1.2566, 2.5133, 3.7699,
    // Outer circle (chainId 10-19)
4.8521, 0.1745, 1.0821, 2.6878, 3.5954, 5.2009, 6.1087, 1.4312, 2.3387, 3.9444);

// Circle radii
const float INNER_RADIUS = 0.15;
const float MIDDLE_RADIUS = 0.3;
const float OUTER_RADIUS = 0.43;

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

// Draw a node with a highlight
vec4 drawNode(vec2 uv, vec2 pos, int chainId) {
    float dist = length(uv - pos);

    // Node size based on circle position
    float nodeSize = 0.01;

    // Base node
    vec4 color = vec4(0.0);

    // Different colors for different circles
    vec4 nodeColor;
    if(chainId < 5) {
        nodeColor = vec4(0.9, 0.3, 0.2, 1.0); // Middle circle (red)
    } else if(chainId < 10) {
        nodeColor = vec4(0.2, 0.7, 0.9, 1.0); // Inner circle (blue)
    } else {
        nodeColor = vec4(0.8, 0.8, 0.2, 1.0); // Outer circle (yellow)
    }

    // Main node
    color += nodeColor * smoothstep(nodeSize, 0.0, dist);

    // Node outline glow
    float outlineSize = nodeSize * 1.5;
    color += nodeColor * 0.5 * smoothstep(outlineSize, outlineSize * 0.7, dist) *
        (1.0 - smoothstep(nodeSize, nodeSize * 0.7, dist));

    return color;
}

// Draw a connection between two nodes
vec4 drawConnection(vec2 uv, vec2 p1, vec2 p2, int connType) {
    vec2 dir = p2 - p1;
    float len = length(dir);
    dir = normalize(dir);

    // Line from p1 to p2
    vec2 lineVector = p2 - p1;
    vec2 perpendicular = normalize(vec2(-dir.y, dir.x));

    // Calculate distance from point to line
    vec2 uv_line = uv - p1;
    float proj = dot(uv_line, dir);
    float dist = abs(dot(uv_line, perpendicular));

    // Connection types have different colors
    vec4 connColor;
    switch(connType) {
        case 0:
            connColor = vec4(0.9, 0.3, 0.2, 1.0) * 0.7;
            break;  // Red (middle to inner)
        case 1:
            connColor = vec4(0.7, 0.5, 0.2, 1.0) * 0.7;
            break;  // Orange (middle to outer+10)
        case 2:
            connColor = vec4(0.2, 0.5, 0.7, 1.0) * 0.7;
            break;  // Blue (middle to outer+15)
        case 3:
            connColor = vec4(0.2, 0.7, 0.9, 1.0) * 0.7;
            break;  // Light blue (inner circle)
        case 4:
            connColor = vec4(0.8, 0.8, 0.2, 1.0) * 0.7;
            break;  // Yellow (outer circle)
        default:
            connColor = vec4(0.5, 0.5, 0.5, 1.0) * 0.7;        // Default gray
    }

    // Thickness is uniform but with slight highlighting near nodes
    float baseThickness = 0.0035;
    float edgeHighlight = smoothstep(0.0, 0.1, proj / len) * smoothstep(1.0, 0.9, proj / len);
    float thickness = baseThickness * (1.0 + edgeHighlight * 0.5);

    // Draw line only within bounds
    float line = smoothstep(thickness, thickness * 0.5, dist) *
        step(0.0, proj) * step(proj, len);

    return connColor * line;
}

// Use cosmic halo effect to draw connection lines
vec4 drawCosmicConnection(vec2 uv, vec2 p1, vec2 p2, int connType, float timeOffset) {
    vec2 dir = normalize(p2 - p1);
    float len = length(p2 - p1);
    vec2 perpendicular = vec2(-dir.y, dir.x);

    // Calculate coordinates relative to the line segment
    vec2 uv_line = uv - p1;
    float along = dot(uv_line, dir);     // Distance along the line direction
    float perp = dot(uv_line, perpendicular); // Distance perpendicular to the line

    // Within the line segment range
    if(along < 0.0 || along > len)
        return vec4(0.0);

    // Cosmic halo effect parameters
    float intensity = 0.6;  // Control light intensity
    float speed = 1.5;     // Control animation speed

    // Type-specific parameters
    float hueOffset;
    float arcDensity;

    // Set different parameters based on connection type
    switch(connType) {
        case 0:
            hueOffset = 0.0;     // Red region
            arcDensity = 6.0;    // Sparse light arcs
            break;
        case 1:
            hueOffset = 0.1;     // Yellow region
            arcDensity = 8.0;    // Medium density
            break;
        case 2:
            hueOffset = 0.3;     // Green region
            arcDensity = 7.0;    // Medium density
            break;
        case 3:
            hueOffset = 0.5;     // Cyan region
            arcDensity = 5.0;    // Sparse
            break;
        case 4:
            hueOffset = 0.7;     // Blue-purple region
            arcDensity = 9.0;    // Dense
            break;
        default:
            hueOffset = 0.0;
            arcDensity = 6.0;
    }

    vec4 color = vec4(0.0);

    // Base line - semi-transparent thin line
    float baseThickness = 0.004;
    float baseLine = smoothstep(baseThickness, 0.0, abs(perp));

    // Base line color changes slowly over time
    float baseHue = fract(iTime * 0.01 + hueOffset);
    vec3 baseColor = 0.5 + 0.5 * cos(6.28 * (baseHue + vec3(0.0, 0.33, 0.67)));

    // Add base line
    color.rgb += baseColor * baseLine * 0.3;
    color.a += baseLine * 0.3;

    // Light arc effect
    // Normalize connection line length to [0,1]
    float normAlong = along / len;

    // Create 5-10 light arcs, number determined by connection type
    for(float i = 0.0; i < arcDensity; i++) {
        // Light arc center position
        float arcPos = fract((i + iTime * speed * 0.2) / arcDensity + timeOffset * 0.1);

        // Map position to connection line length
        float arcCenter = arcPos * len;

        // Distance to light arc center
        float distToArc = abs(along - arcCenter);

        // Light arc width
        float arcWidth = len * 0.05;

        if(distToArc < arcWidth) {
            // Light arc intensity - Gaussian distribution for natural effect
            float arcIntensity = exp(-(distToArc * distToArc) / (2.0 * arcWidth * arcWidth * 0.3));

            // Perpendicular line direction light arc attenuation
            float thickness = 0.002 + 0.001 * arcIntensity;
            float perpIntensity = smoothstep(thickness, 0.0, abs(perp));

            // Light arc angle calculation - for rainbow colors and animation
            float arcAngle = normAlong * arcDensity + iTime * speed * sin(i + float(connType)) + i * 0.7 + timeOffset;

            // Use cosine to create intermittent light arcs
            float arc = clamp(cos(arcAngle * 2.0), 0.1, 0.7);

            // Generate rainbow colors
            vec4 arcColor = (cos(arcAngle - i * 0.1 + hueOffset + vec4(0, 1, 2, 0)) + 1.0) * 0.5;

            // Apply light arc effect
            color += arcColor * arcIntensity * perpIntensity * arc * intensity;
        }
    }

    return color;
}

// Draw cosmic halo effect concentric circles
vec4 drawCosmicCircles(vec2 uv) {
    vec4 color = vec4(0.0);

    // Scaling and offset parameters - effect intensity control
    float intensity = 0.5; // Control halo intensity
    float speed = 1.5;    // Control rotation speed
    float rings = 15.0;   // Halo density

    // Calculate polar coordinates of the current pixel
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Create cosmic halo effect for three concentric circles
    for(float i = 0.0; i < 3.0; i++) {
        // Determine the radius of the current circle
        float targetRadius;
        if(i < 1.0)
            targetRadius = INNER_RADIUS;
        else if(i < 2.0)
            targetRadius = MIDDLE_RADIUS;
        else
            targetRadius = OUTER_RADIUS;

        // Add multiple light arcs to each circle
        for(float j = 0.0; j < rings; j++) {
            // Calculate distance to the target circle
            float ringDist = abs(dist - targetRadius);

            // Fine-tune distortion for a more natural halo appearance
            float distortion = 0.005 * sin(angle * (j + 1.0) + iTime * speed * (i + 1.0));

            // Halo intensity - brighter closer to the target radius
            float glow = intensity / (ringDist * 400.0 + 2.0);

            // Light arc rotation and angle limitation
            float arcAngle = angle * ceil(j * 0.3 + 1.0) +
                iTime * speed * sin((j + 1.0) * (i + 1.0)) +
                j * j * 0.1 + i * 2.0;

            // Use cosine to create intermittent light arcs instead of complete halos
            float arc = clamp(cos(arcAngle), 0.0, 0.6);

            // Generate rainbow colors - vary based on angle and circle index
            vec4 arcColor = (cos(arcAngle - j * 0.2 - i + vec4(0, 1, 2, 0)) + 1.0) * 0.5;

            // Light arc distance attenuation - exponential decay for sharper arcs
            float falloff = exp(-ringDist * 100.0);

            // Skip the central area to avoid interference with the black hole core
            if(dist > 0.1) {
                // Add effect only near the target circle
                if(ringDist < 0.03) {
                    color += glow * arc * arcColor * falloff;
                }
            }
        }
    }

    return color;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Initialization
    fragColor = vec4(0.02, 0.03, 0.05, 1.0);  // Deep blue background

    // Normalize coordinates
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

    // Graphic rotation - slower and subtle
    float rotation = iTime * 0.05;
    mat2 rotMat = mat2(cos(rotation), -sin(rotation), sin(rotation), cos(rotation));
    uv = uv * rotMat;

    // Draw cosmic halo effect concentric circles
    vec4 cosmicCircles = drawCosmicCircles(uv);
    fragColor += cosmicCircles;

    // Fade original concentric circles - no longer need original solid color circles
    float outerDist = abs(length(uv) - OUTER_RADIUS);
    float middleDist = abs(length(uv) - MIDDLE_RADIUS);
    float innerDist = abs(length(uv) - INNER_RADIUS);

    // Retain only extremely thin base circles as reference
    vec4 outerCircleColor = vec4(0.8, 0.8, 0.2, 1.0) * 0.05;  // Reduce brightness
    vec4 middleCircleColor = vec4(0.9, 0.3, 0.2, 1.0) * 0.05; // Reduce brightness
    vec4 innerCircleColor = vec4(0.2, 0.7, 0.9, 1.0) * 0.05;  // Reduce brightness

    fragColor += outerCircleColor * (1.0 - smoothstep(0.0005, 0.001, outerDist)); // Reduce width
    fragColor += middleCircleColor * (1.0 - smoothstep(0.0005, 0.001, middleDist)); // Reduce width
    fragColor += innerCircleColor * (1.0 - smoothstep(0.0005, 0.001, innerDist)); // Reduce width


    // Draw rainbow light flow connection lines
    for(int i = 0; i < 30; i++) {
        int fromId = CONNECTIONS[i].x;
        int toId = CONNECTIONS[i].y;
        int connType = CONN_TYPE[i];

        vec2 fromPos = getNodePosition(fromId);
        vec2 toPos = getNodePosition(toId);

        // Add unique time offset for each line to make arcs asynchronous
        float timeOffset = float(i) * 0.3;

        // Use cosmic halo effect for connection lines
        fragColor += drawCosmicConnection(uv, fromPos, toPos, connType, timeOffset);
    }

    // Draw nodes
    for(int chainId = 0; chainId < 20; chainId++) {
        vec2 pos = getNodePosition(chainId);
        fragColor += drawNode(uv, pos, chainId);
    }

    // Add subtle vignette effect
    float vignette = 1.0 - smoothstep(0.5, 1.5, length(fragCoord / iResolution.xy - 0.5) * 1.2);
    fragColor *= vignette * 1.2;
}