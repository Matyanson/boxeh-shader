#version 120

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

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0f)));
    return exp2(-factor * factor);
}

float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth) {
   vec3 result = originalColor;
   waterDepth = toMeters(waterDepth);
   float viewDistance = waterDepth * far - near;
   float red = FogExp2(viewDistance, 1 * 0.001);
   float green = FogExp2(viewDistance, 1 * 0.0003);
   float blue = FogExp2(viewDistance, 1 * 0.0002);
   // vec3 shallowColor = vec3(0, 0.5, 0.95);
   result *= vec3(red, green, blue);
   return result;
}

const float contrast = 1.25f;
const float brightness = 0.25f;

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;

    float depth = texture2D(colortex3, TexCoords).r;

    if(isEyeInWater == 1) {
        
        color = getWaterColor(color, depth * 0.5);
        gl_FragData[0] = vec4(color, 1.0f);
        return;
    }

    if(depth == 1.0f) {
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