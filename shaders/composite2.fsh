#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float viewWidth, viewHeight;
uniform float near, far;

/*
const int colortex0Format = RGBA32F;
*/

vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

float getFocalDistance() {
    float sum = 0.0f;
    int radius = 7;
    float spacing = 2 * texelSize.x;
    float radiusTex = radius * spacing;
    for(float x = 0.5 - radiusTex; x <= 0.5 + radiusTex; x += spacing) {
        sum += LinearDepth(texture2D(depthtex0, vec2(x, 0.5f)).r);
    }
    spacing = 2 * texelSize.y;
    radiusTex = radius * spacing;
    for(float y = 0.5 - radiusTex; y <= 0.5 + radiusTex; y += spacing) {
        sum += LinearDepth(texture2D(depthtex0, vec2(0.5f, y)).r);
    }

    return sum / (4 * radius + 2);  // TODO: use median instead of average
}

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    float depth = texture2D(depthtex0, TexCoords).r;
    //depth = max(0.003, LinearDepth(depth));
    depth = LinearDepth(depth);

    float focalDistance = getFocalDistance();
    float focusDifference = depth - focalDistance;
    float kernelScale = abs(focusDifference) / focalDistance;   // |depth - focalDistance| / focalDistance
    
    /* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(vec3(kernelScale), 1.0f);
}