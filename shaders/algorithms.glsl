vec3 getWaterColor(vec3 originalColor, float viewDistance, float lightIntensity, vec3 absorptionCoefficient, vec3 scatterCoefficient) {
   //beers law: Intensity(d) = 1 * e^(-k*d)
   vec3 absorbFilter = exp(-absorptionCoefficient * viewDistance);
   
   /*
      S = scatterCoefficient
      A = absorptionCoefficient
      a(x) = absorbFilter
      x = viewDistance

      // integral from 0 to x
      g = integral(a(x)) / integral(1)
      g = -((a(x) - 1) / A) / x

      // AbsorbedScatterCoefficient = gS
      = -(((a(x) - 1) / A) / x) * S
      // scatteredColor = 1 - e^-gSx
      -gSx = --(((a(x) - 1) / A) / x)Sx
      -gSx =   ((a(x) - 1) * S) / A
   */
   vec3 AbsorbedScatterCoefficient = absorptionCoefficient == 0 ?
      -scatterCoefficient * viewDistance :
      ((absorbFilter - 1) * scatterCoefficient) / absorptionCoefficient;
   vec3 sunColor = vec3(0.5);//vec3(lightIntensity);

   vec3 scatteredColor = sunColor * (1-exp(AbsorbedScatterCoefficient));
   vec3 attenuationFilter = exp(-absorptionCoefficient * viewDistance + AbsorbedScatterCoefficient);

   return originalColor * attenuationFilter + scatteredColor;
   
   // ae^k + 1 -e^k = F, a = e^(-Ax), k = S(a - 1) / A, F > a
   // e^k(ca - l) + l
   // return exp(AbsorbedScatterCoefficient) * (originalColor * absorbFilter - sunColor) + sunColor;
}

vec2 adjustCoefs(float scatterCoef, float absorptionCoef, float desiredWaterI, float originalWhite) {
   float dist = 24;
   float color = 1;

   float desiredWhite = desiredWaterI; // 0.3*color + 0.7 * desiredWaterI;
   float desiredBlack = 0.0*color + 0.7 * desiredWaterI;
   desiredWhite = pow(desiredWhite, 2.2);
   desiredBlack = pow(desiredBlack, 2.2);

   // more absorption
   if(desiredWhite < originalWhite) {
      absorptionCoef = -log(desiredWhite) / dist;
   }
   else { // more scattering
      // S = (Alog((F - 1)/(a - 1)))/(a - 1)
      float absorbFilter = exp(-absorptionCoef * dist);
      scatterCoef = (absorptionCoef * log((desiredWhite - 1)/(absorbFilter - 1))) / (absorbFilter - 1);
   }

   // scatterCoef = -log(1.0 - 0.7 * desiredWaterI) / dist;
   // absorptionCoef = -log(0.3) / dist - scatterCoef;
   
   return vec2(scatterCoef, absorptionCoef);
}

vec3 getWaterColorAdaptive(vec3 originalColor, float viewDistance, float lightIntensity, vec3 waterColor, vec3 waterOpacity) {
   /*
      color (white bg):
      w-texture: 0.502, 0.651, 0.929
      water(5): 0.057211520130039606, 0.7452764914432886, 0.9445940693665233
      water(5, c=0.5): 3.0646962766458474e-7, 0.11496274259336194, 0.3760071271596913
      water(25): 6.129392553291695e-7, 0.22992548518672387, 0.7520142543193826
      water(24): 0.0000010862273631843187, 0.24385048692652467, 0.7606362689256634

      absorption:
      default texture blue(5): 0.3032282700877795, 0.18886808018036982, 0.032404477674051343
      water: 0.5722, 0.0588, 0.0114
   */
   vec3 originalWaterColor = vec3(0.0000010862273631843187, 0.24385048692652467, 0.7606362689256634);
   originalWaterColor = pow(originalWaterColor, vec3(2.2));

   vec3 absorptionCoefficient = vec3(0.5722, 0.0588, 0.0114);
   vec3 scatterCoefficient = vec3(0); //vec3(0.0007, 0.0019, 0.0045);
   
   mat3x2 newASCoefs;
   newASCoefs[0] = adjustCoefs(scatterCoefficient.r, absorptionCoefficient.r, waterColor.r, originalWaterColor.r);
   newASCoefs[1] = adjustCoefs(scatterCoefficient.g, absorptionCoefficient.g, waterColor.g, originalWaterColor.g);
   newASCoefs[2] = adjustCoefs(scatterCoefficient.b, absorptionCoefficient.b, waterColor.b, originalWaterColor.b);

   scatterCoefficient = vec3(newASCoefs[0].x, newASCoefs[1].x, newASCoefs[2].x);
   absorptionCoefficient = vec3(newASCoefs[0].y, newASCoefs[1].y, newASCoefs[2].y);

   return getWaterColor(originalColor, viewDistance, lightIntensity, absorptionCoefficient, scatterCoefficient);
}

vec3 getWaterColor(vec3 originalColor, float viewDistance, float lightIntensity) {
   // https://misclab.umeoce.maine.edu/boss/classes/RT_Weizmann/Chapter3.pdf
   // https://web.pdx.edu/~sytsmam/limno/Limno09.7.Light.pdf; https://omlc.org/spectra/water/abs/
   // RGB(700nm, 550nm, 450nm)
   // absorbtion: vec3(0.338675, 0.0493852, 0.00218174); vec3(0.650, 0.0638, 0.0145); vec3(0.5722, 0.0588, 0.0114); vec3(0.601, 0.0558, 0.0226); //ocean water: vec3(0.6, 0.035, 0.003); //vec3(0.624, 0.0565, 0.00922); //plankton: vec3(0.003, 0.008, 0.0371)
   // scatter:    vec3(0.0007, 0.0019, 0.0045); vec3(0.0005, 0.0014, 0.0033); 0.004, 0.01, 0.024 (1/(wl^4)); milk: vec3(51000, 50000, 49000); https://pubmed.ncbi.nlm.nih.gov/7755493/#:~:text=The%20scattering%20coefficients%20for%20undiluted,6%20mm%2D1%2C%20respectively.
   vec3 absorptionCoefficient = vec3(0.5722, 0.0588, 0.0114);
   vec3 scatterCoefficient = vec3(0.0007, 0.0019, 0.0045);
   
   return getWaterColor(originalColor, viewDistance, lightIntensity, absorptionCoefficient, scatterCoefficient);
}