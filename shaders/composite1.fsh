#version 120

varying vec2 TexCoords;

uniform sampler2D texture;

void main(){
    vec4 Color = texture2D(texture, TexCoords);
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = Color;
}