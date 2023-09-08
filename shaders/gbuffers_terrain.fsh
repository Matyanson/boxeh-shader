#version 120

varying vec2 TexCoords;
varying vec4 Tint;
varying vec2 LightmapCoords;
varying vec3 Normal;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
    // Sample the color
   vec4 albedo = texture2D(texture, TexCoords);
   vec4 color = albedo * Tint;
    #ifndef customLighting
        vec4 light = texture2D(lightmap, LightmapCoords);
        color *= light;
    #endif
   
   /* DRAWBUFFERS:012 */
   gl_FragData[0] = color;
   gl_FragData[1] = vec4(LightmapCoords, 0.0, 1.0);
   gl_FragData[2] = vec4(Normal * 0.5 + 0.5, 1.0);
}