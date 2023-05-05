#version 120
#include "algorithms.glsl"

#define FOG_DENSITY 0.003//0.008
#define RAIN_MODIFIER 0.012;

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float near, far;
uniform float rainStrength;
uniform int isEyeInWater;


/*
const int colortex0Format = RGBA32F;
*/

float toMeters(float depth) {
   return near + depth * (far - near);
}

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0)));
    return exp2(-factor * factor);
}

const float contrast = 1.25;
const float brightness = 0.25;

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;

    float depth = texture2D(colortex3, TexCoords).r;

    if(isEyeInWater == 1) {
        
        color = getWaterColor(color, toMeters(depth));
        gl_FragData[0] = vec4(color, 1.0);
        return;
    }

    if(true || depth == 1.0) {
        gl_FragData[0] = vec4(color, 1.0);
        return;
    }

    

    float density = FOG_DENSITY + rainStrength * RAIN_MODIFIER;

    float viewDistance = depth * far - near;
    
    vec3 lessContrast = contrast * 0.33 * (color - 0.5) + 0.5 + brightness;

    float contrastFactor = 1 - clamp(FogExp2(viewDistance, density), 0.5, 1.0);

    color = mix(color, fogColor, contrastFactor);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}