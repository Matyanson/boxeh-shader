#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec3 Normal;

uniform mat4 gbufferModelViewInverse;
attribute vec4 mc_Entity;

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;
    //Normal = gl_NormalMatrix * gl_Normal;
    Normal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);
}