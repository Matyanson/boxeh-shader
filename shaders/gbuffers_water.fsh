#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

uniform sampler2D texture;
/*
const int colortex6Format = RGB16F;
*/

void main() {
    // Sample the color
    vec4 albedo = texture2D(texture, TexCoords);

    /* DRAWBUFFERS:0126 */
    // gl_FragData[0] = vec4(albedo.rgb, 1) * vec4(Color.rgb, 0.5);
    gl_FragData[0] = vec4(albedo.rgb, 0.5);
    gl_FragData[1] = vec4(LightmapCoords, 0.0, 1.0);
    gl_FragData[2] = vec4(Normal * 0.5 + 0.5, 1.0);
    gl_FragData[3] = ivec4(BlockId, 1, 1, 1);
}