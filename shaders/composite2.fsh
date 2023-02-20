#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform float near, far;

/*
const int colortex0Format = RGBA32F;
*/

const float focalInnerRadius = 0.05f;
const float focalOuterRadius = 0.11f;

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    float depth = texture2D(depthtex0, TexCoords).r;
    
    depth = LinearDepth(depth);

    float focalPoint = LinearDepth(texture2D(depthtex0, vec2(0.5f)).r);

    float dist = abs(focalPoint - depth);
    //dist = clamp(dist, focalInnerRadius, focalOuterRadius);
    float bluriness = smoothstep(focalInnerRadius, focalOuterRadius, dist); //inverse lerp

    albedo *= bluriness;
    /* DRAWBUFFERS:3 */
    gl_FragColor = vec4(albedo, bluriness);
}