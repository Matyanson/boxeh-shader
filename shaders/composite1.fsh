#version 120

#define FOG_DENSITY 0.003//0.008
#define RAIN_MODIFIER 0.012;

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float near, far;
uniform float rainStrength;
uniform int isEyeInWater;


/*
const int colortex0Format = RGBA32F;
*/

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0f)));
    return exp2(-factor * factor);
}

float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth) {
   waterDepth = toMeters(waterDepth);
   float viewDistance = waterDepth * far - near;
   float shallow = FogExp2(viewDistance, 0.002);
   float deep = FogExp2(viewDistance, 0.0008);
   vec3 shallowColor = vec3(0, 0.5, 0.95);
   vec3 deepColor = 0.05 * vec3(0, 0.05, 0.2);
   shallowColor = originalColor * mix(shallowColor, vec3(1), shallow);
   return mix(deepColor, shallowColor, deep);
}

const float contrast = 1.25f;
const float brightness = 0.25f;

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;

    float depth = texture2D(colortex3, TexCoords).r;

    if(isEyeInWater == 1) {
        color = getWaterColor(color, depth);
        gl_FragData[0] = vec4(color, 1.0f);
        return;
    }

    if(depth == 1.0f){
        gl_FragData[0] = vec4(color, 1.0f);
        return;
    }

    

    float density = FOG_DENSITY + rainStrength * RAIN_MODIFIER;

    float viewDistance = depth * far - near;
    
    vec3 lessContrast = contrast * 0.33 * (color - 0.5) + 0.5 + brightness;

    float contrastFactor = 1 - clamp(FogExp2(viewDistance, density), 0.5f, 1.0f);

    color = mix(color, fogColor, contrastFactor);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0f);
}