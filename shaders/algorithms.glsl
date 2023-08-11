vec3 getWaterColor(vec3 originalColor, float viewDistance, float lightIntensity) {
   vec3 sunColor = vec3(lightIntensity*0.5);
   
   // https://misclab.umeoce.maine.edu/boss/classes/RT_Weizmann/Chapter3.pdf
   // https://web.pdx.edu/~sytsmam/limno/Limno09.7.Light.pdf; https://omlc.org/spectra/water/abs/
   // RGB(700nm, 550nm, 450nm)
   // absorbtion: vec3(0.338675, 0.0493852, 0.00218174); vec3(0.650, 0.0638, 0.0145); vec3(0.5722, 0.0588, 0.0114); vec3(0.601, 0.0558, 0.0226); //ocean water: vec3(0.6, 0.035, 0.003); //vec3(0.624, 0.0565, 0.00922); //plankton: vec3(0.003, 0.008, 0.0371)
   // scatter:    vec3(0.0007, 0.0019, 0.0045); vec3(0.0005, 0.0014, 0.0033); 0.004, 0.01, 0.024 (1/(wl^4)); 
   vec3 absorptionCoefficient = vec3(0.5722, 0.0588, 0.0114);
   vec3 scatterCoefficient = vec3(0.0007, 0.0019, 0.0045);
   vec3 attenuationCoefficient = absorptionCoefficient + scatterCoefficient; //vec3(0.106, 0.050, 0.035);

   //beers law: Intensity(d) = 1 * e^(-k*d)
   vec3 absorbFilter = exp(-absorptionCoefficient * viewDistance);
   vec3 attenuationFilter = exp(-attenuationCoefficient * viewDistance);
   vec3 scatterIntensity = absorbFilter - attenuationFilter;
   
   
   // vec3 penetratedColor = originalColor * absorbFilter;
   vec3 scatteredColor = sunColor * scatterIntensity;
   
   return (originalColor * attenuationFilter) + scatteredColor;
}