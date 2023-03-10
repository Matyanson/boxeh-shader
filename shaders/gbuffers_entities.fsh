#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec2 LightmapCoords;
varying vec3 Normal;

uniform sampler2D texture;

void main() {
    // Sample the color
   vec4 albedo = texture2D(texture, TexCoords);
   
   /* DRAWBUFFERS:012 */
   gl_FragData[0] = albedo * Color;
   gl_FragData[1] = vec4(LightmapCoords, 0.0f, 1.0f);
   gl_FragData[2] = vec4(Normal * 0.5f + 0.5, 1.0f);
}