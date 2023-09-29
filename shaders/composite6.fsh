#version 120

#include "/lib/settings.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform float viewWidth, viewHeight;


vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    #ifdef DOF
        float kernel = viewHeight;

        float kernelScale = texture2D(colortex4, TexCoords).r;
        float temp = kernelScale * kernel / 2.0;
        int kernelRadius = int(temp);
        float partialKernel = mod(temp, 1.0);
        // Vertical Blur
        vec3 sum = vec3(0);
        vec3 accumulation = vec3(0);
        for (int i = -kernelRadius; i <= kernelRadius; i++){
            accumulation += texture2D(colortex5, TexCoords + vec2(0.0, i) * texelSize).rgb;
        }

        accumulation += partialKernel * texture2D(colortex0, TexCoords + vec2(0.0, kernelRadius + 1) * texelSize).rgb;

        sum = accumulation / (2 * kernelRadius + 1 + partialKernel);

        /* DRAWBUFFERS:0 */
        gl_FragColor = vec4(sum, 1.0);
    #else
        /* DRAWBUFFERS:0 */
        vec3 color = texture2D(colortex0, TexCoords).rgb;
        gl_FragColor = vec4(color, 1.0);
    #endif
}