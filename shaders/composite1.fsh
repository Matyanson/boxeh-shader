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
    float factor = viewDistance * (density / sqrt(log(2.0)));
    return exp2(-factor * factor);
}

float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth, float lightAlbedo) {
   float viewDistance = toMeters(waterDepth);
   vec3 sunColor = vec3(1.0);
   
   // https://web.pdx.edu/~sytsmam/limno/Limno09.7.Light.pdf; https://omlc.org/spectra/water/abs/
   // RGB(700nm, 550nm, 450nm), absorption: 0.056, 0.024, 0.017; Attenuation: 0.106, 0.050, 0.035
   //vec3(0.601, 0.0558, 0.0226); //ocean water: vec3(0.6, 0.035, 0.003); //vec3(0.5722, 0.0588, 0.0114); //vec3(0.624, 0.0565, 0.00922); //plankton: vec3(0.003, 0.008, 0.0371)
   vec3 absorptionCoefficient = vec3(0.5722, 0.0588, 0.0114);
   vec3 scatterCoefficient = vec3(0.004, 0.01, 0.024);
   vec3 attenuationCoefficient = absorptionCoefficient + scatterCoefficient; //vec3(0.106, 0.050, 0.035);

   //beers law: Intensity(d) = 1 * e^(-k*d)
   // vec3 absorbFilter = exp(-absorptionCoefficient * viewDistance);
   vec3 scatterFilter = exp(-scatterCoefficient * viewDistance);
   vec3 scatterIntensity = (vec3(1.0) - scatterFilter);
   // vec3 attenuationFilter = absorbFilter * scatterFilter;
   vec3 attenuationFilter = exp(-attenuationCoefficient * viewDistance);
   
   
   // vec3 penetratedColor = originalColor * absorbFilter;
   vec3 scatteredColor = sunColor * scatterIntensity;
   
   /*
       color = color - (absorbed + scattered) + light * (scattered - absorbed)
       (originalColor * attenuationFilter) + (scatteredColor * attenuationFilter)
       = (originalColor + scatteredColor) * attenuationFilter
   */
   
   return (originalColor + scatteredColor) * attenuationFilter;
}

const float contrast = 1.25;
const float brightness = 0.25;

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;

    float depth = texture2D(colortex3, TexCoords).r;

    if(isEyeInWater == 1) {
        
        color = getWaterColor(color, depth * 0.5);
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