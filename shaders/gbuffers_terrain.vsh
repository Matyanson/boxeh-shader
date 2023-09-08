#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec4 Tint;
varying vec3 Normal;

void main() {
   Tint = gl_Color;
   Normal = gl_NormalMatrix * gl_Normal;
   TexCoords = gl_MultiTexCoord0.st;
   // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft. Resulting in the range [1.05 / 32, 32/33.05]
   LightmapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
   gl_Position = ftransform();
}