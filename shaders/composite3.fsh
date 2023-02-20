#version 120

varying vec2 TexCoords;
uniform sampler2D colortex3;
uniform float viewWidth, viewHeight;

/*
const int colortex0Format = RGBA32F;
*/

const float kernel = 5.0;
vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    float alpha = texture2D(colortex3, TexCoords).a;
    // Horizontal Blur
    vec4 sum = vec4(0);
    vec4 accumulation = vec4(0);
    for (float i = -kernel; i <= kernel; i++){
        accumulation += texture2D(colortex3, TexCoords + vec2(i, 0.0) * texelSize).rgba;
    }

    sum = accumulation / (2 * kernel + 1);

    /* DRAWBUFFERS:3 */
    gl_FragColor = vec4(sum);
}