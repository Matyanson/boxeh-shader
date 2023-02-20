#version 120

#define FOG_DENSITY 0.003//0.008
#define RAIN_MODIFIER 0.012;

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform float near, far;
uniform float rainStrength;

/*
const int colortex0Format = RGBA32F;
*/

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0f)));
    return exp2(-factor * factor);
}

const float contrast = 1.25f;
const float brightness = 0.25f;

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;

    float depth = texture2D(depthtex0, TexCoords).r;
    if(depth == 1.0f){
        gl_FragData[0] = vec4(albedo, 1.0f);
        return;
    }

    float density = FOG_DENSITY + rainStrength * RAIN_MODIFIER;

    depth = LinearDepth(depth);
    float viewDistance = depth * far - near;
    
    vec3 lessContrast = contrast * 0.33 * (albedo - 0.5) + 0.5 + brightness;

    float contrastFactor = 1 - clamp(FogExp2(viewDistance, density), 0.0f, 1.0f);

    albedo = mix(albedo, lessContrast, contrastFactor);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(albedo, 1.0f);
}