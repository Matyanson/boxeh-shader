#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform float viewWidth, viewHeight;

/*
const int colortex0Format = RGBA32F;
*/

const float kernel = 5.0;
vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    // Vertical Blur
    vec4 sum = vec4(0);
    vec4 accumulation = vec4(0);
    for (float i = -kernel; i <= kernel; i++){
        accumulation += texture2D(colortex3, TexCoords + vec2(0.0, i) * texelSize).rgba;
    }

    sum = accumulation / (2 * kernel + 1);
    albedo = mix(albedo, sum.rgb, sum.a);
    /* DRAWBUFFERS:0 */
    gl_FragColor = vec4(albedo, 1.0f);
}