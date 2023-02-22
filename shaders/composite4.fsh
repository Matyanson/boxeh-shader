#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform float viewWidth, viewHeight;

/*
const int colortex0Format = RGBA32F;
const int colortex4Format = RGBA32F;
*/

const float kernel = 3.7;
vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    float kernelScale = texture2D(colortex3, TexCoords).r;
    int kernelRadius = int(kernelScale * kernel / 2);
    // Vertical Blur
    vec3 sum = vec3(0);
    vec3 accumulation = vec3(0);
    for (int i = -kernelRadius; i <= kernelRadius; i++){
        accumulation += texture2D(colortex4, TexCoords + vec2(0.0, i) * texelSize).rgb;
    }

    sum = accumulation / (2 * kernelRadius + 1);

    /* DRAWBUFFERS:0 */
    gl_FragColor = vec4(sum, 1.0f);
}