#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec3 Normal;
varying float isWater;

uniform sampler2D texture;
uniform sampler2D colortex0;
uniform sampler2D stencilMap;

void main() {
    // Sample the color
    vec4 albedo = texture2D(texture, TexCoords);

    /* DRAWBUFFERS:026 */
    gl_FragData[0] = albedo * Color;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5, 1.0f);
    gl_FragData[2] = vec4(1.0);
}