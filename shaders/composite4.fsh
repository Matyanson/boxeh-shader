#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform float viewWidth, viewHeight;

/*
const int colortex0Format = RGBA32F;
const int colortex5Format = RGBA32F;
*/

const float kernel = 40.0;//3.7;
vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    float kernelScale = texture2D(colortex4, TexCoords).r;
    float temp = kernelScale * viewHeight/*kernel*/ / 2.0;
    int kernelRadius = int(temp);
    float partialKernel = mod(temp, 1.0);
    // Vertical Blur
    vec3 sum = vec3(0);
    vec3 accumulation = vec3(0);
    for (int i = -kernelRadius; i <= kernelRadius; i++){
        accumulation += texture2D(colortex5, TexCoords + vec2(0.0, i) * texelSize).rgb;
    }

    accumulation += partialKernel * texture2D(colortex0, TexCoords + vec2(0.0, kernelRadius) * texelSize).rgb;

    // Leak from other blurred areas
    // int weightSum = 0;
    // for(int i = -int(kernel / 2); i <= int(kernel / 2); i++) {
    //     float foreignKernelScale = texture2D(colortex4, TexCoords + vec2(0.0, i)).r;
    //     if(foreignKernelScale * kernel >= abs(i)) {
    //         accumulation += texture2D(colortex0, TexCoords + vec2(0.0, i) * texelSize).rgb;
    //         weightSum++;
    //     }
    // }

    // sum = accumulation / (2 * kernelRadius + 1 + weightSum);
    sum = accumulation / (2 * kernelRadius + 1 + partialKernel);

    /* DRAWBUFFERS:0 */
    gl_FragColor = vec4(sum, 1.0f);
    // gl_FragColor = vec4(vec3(kernelScale), 1.0f);
}