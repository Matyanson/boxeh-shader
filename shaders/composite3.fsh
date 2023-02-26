#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform float viewWidth, viewHeight;

/*
const int colortex0Format = RGBA32F;
const int colortex5Format = RGBA32F;
*/

const float kernel = 3.7;
vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    float kernelScale = texture2D(colortex4, TexCoords).r;
    int kernelRadius = int(kernelScale * kernel / 2);
    // Horizontal Blur
    vec3 sum = vec3(0);
    vec3 accumulation = vec3(0);
    for (int i = -kernelRadius; i <= kernelRadius; i++){
        accumulation += texture2D(colortex0, TexCoords + vec2(i, 0.0) * texelSize).rgb;
    }

    // Leak from other blurred areas
    // int weightSum = 0;
    // for(int i = -int(kernel / 2); i <= int(kernel / 2); i++) {
    //     float foreignKernelScale = texture2D(colortex4, TexCoords + vec2(i, 0.0)).r;
    //     if(foreignKernelScale * kernel / 2 - 1 >= abs(i)) {
    //         accumulation += texture2D(colortex0, TexCoords + vec2(i, 0.0) * texelSize).rgb;
    //         weightSum++;
    //     }
    // }

    // sum = accumulation / (2 * kernelRadius + 1 + weightSum);
    sum = accumulation / (2 * kernelRadius + 1);

    /* DRAWBUFFERS:5 */
    gl_FragColor = vec4(sum, 1.0f);
}