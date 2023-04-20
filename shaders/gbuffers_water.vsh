#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

attribute vec4 mc_Entity;

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;

    Color = gl_Color;
    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LightmapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05 / 32.0) - (1.05 / 32.0);
    Normal = normalize(gl_NormalMatrix * gl_Normal);
    BlockId = int(mc_Entity.x);
}