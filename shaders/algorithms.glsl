

float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth) {
   float viewDistance = toMeters(waterDepth);
   vec3 sunColor = vec3(1.0);
   
   // https://s.campbellsci.com/documents/es/technical-papers/obs_light_absorption.pdf
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