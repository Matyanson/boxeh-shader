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
   vec3 AbsorbedScatterCoefficient = ((absorbFilter - 1) * scatterCoefficient) / absorptionCoefficient;

   vec3 scatteredColor = sunColor * (1-exp(AbsorbedScatterCoefficient));
   /* LIGHT SCATTER
   https://patapom.com/topics/Revision2013/Revision%202013%20-%20Real-time%20Volumetric%20Rendering%20Course%20Notes.pdf
   https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering
   https://web.gps.caltech.edu/~vijay/Papers/Rayleigh_Scattering/Bodhaine-etal-99.pdf
   https://www.sciencedirect.com/science/article/pii/S0958694620301138
   I(θ) = I0 (R^6 / r^2) (1 + cos^2(θ)) (λ^-4)

   Where:

      I0 is the intensity of the incident light,
      R denotes the size of the scattering particles,
      r is the distance between the scattering particle and the observer,
      θ is the angle between the incident light and the scattered light, and
      λ stands for the wavelength of the incident light.
   */
   // float particleSize = 50; // protein: 40 - 300, fat: 1000
   // float ParticlesPerM = 10;
   // vec3 ILightWave = vec3(700, 550, 450);
   // scatterCoefficient = 1 / pow(ILightWave, vec3(4));
   // vec3 scatteredColor = vec3(1.0) * (pow(particleSize, 6) / pow(viewDistance, 2)) * (2 / pow(ILightWave, vec3(4)));
   // vec3 scatteredColor = vec3(1.0) * (ParticlesPerM*viewDistance) * 2 * pow(particleSize, 6) / (pow(viewDistance*0.5, 2) * pow(ILightWave, vec3(4)));


   /*
      --FORMULA--
      Lo = (Lgnd * at) + (Lsun * (1-s))

      Lo = at*c + s*l
      Lo = 0.3*c + 0.7*w

      More Absorption:
      at*c > 0.3*c + 0.7*w
      at > 0.3 + 0.7*w
      e^(-Ad) * c = 0.3c + 0.7w
      A = -log(0.3 + 0.7w/c) / d

      More Scattering:
      at < 0.3 + 0.7*w
      at + s = 0.3 + 0.7*w
      s = 0.3 + 0.7*w - at
      1 - e^((a - 1) * S) / A = 0.3 + 0.7*w - e^(-Ad)
      S = A*log(0.7 - 0.7w + a) / (a - 1)

      C0, CD, CF
      0|-------------C0------CF-----------|1
      CD = CF - C0

      c * e^-Ad = C0
      c * a = C0
      c * e^-(A+S)d + 1 - s = CF
      c * e^-(Ad+Sd) + 1 - s = CF
      c * e^(-Ad-Sd) + 1 - s = CF
      c * e^-Ad * e^-Sd + 1 - s = CF
      c * a * e^-Sd + 1 - s = CF
      a * e^-Sd + 1 - e^((a-1)S / A) = CF
      a * e^-Sd - e^((a-1)S / A) + 1 = CF

      a = B
      a * e^-Sd - e^((a-1)S / A) + 1 = F
      log(a * e^-Sd - e^((a-1)S / A) + 1) = log(F)


      a(e^-Sd - e^((a-1)S / A)/a + 1/a) = F
      e^-Sd - e^((aS-S+A^2d)/A) + 1/a = F/a

      a * e^-Sxd - e^((a-1)Sx / A) + 1
      -(a * e^-Sd - e^((a-1)S / A) + 1)
      = CD
      a * e^-Sxd - e^((a-1)Sx / A) + 1
      -a * e^-Sd + e^((a-1)S / A) - 1
      = CD
      a * e^-Sxd - a * e^-Sd + e^((a-1)S / A) - e^((a-1)Sx / A)
      = CD


      xk + l = cf
      x = c0
      cf = c0 + cd
      cd = ?
      c0k + l = c0 + cd
      cd = kc0 + l - c0
      cd = (k - 1)c0 + l

      CD = a(e^-Sd - 1) + 1 - e^((a-1)S / A)



      Absorbtion:
      c [0-1], w=0.9
      a*c = 0.3c + 0.7w
      [0-c] = 0.3c + 0.63
      [0-1] = [0.63-0.93]
      c = 0.3*c + 0.7w
      0.7c = 0.7w
      c = w ...c < w

      c=0.5
      0.5a = 0.15 + 0.7w
      w=0.5
      0.5a = 0.15 + 0.35 => a=1
      c < w
      ac = 0.3c + 0.7w
      (a-0.3)c = 0.7w => a=1
      0.7c + s = 0.7w
      s = 0.7w - 0.7c => scattering=0.7w-0.7c

      c=0.5
      if c > w
         ac = 0.3c + 0.7w
         e^(-A*d)) * c = 0.3c + 0.7w
         A = -log(0.3 + 0.7w/c) / d
      if c <= w
         a = 1
         A = 0
         s = 0.7w - 0.7c
         1-e^(-Sd) = 0.7w - 0.7c
         S = -log(0.7c - 0.7w + 1) / d

      Scattering:
      c=0
      0a = 0 + 0.7w
      s = 0.7w


      at*c + s*l = 0.3*c + 0.7*w
      at=0.3, s=0.7*w


      1-e^(-Sd) = 0.7*w
      S = -log(1-0.7w) / d

      e^(-(A+S)d)) = 0.3
      A = -log(0.3) / d - S


      at = e^(-At*d) [0-1]
      a = e^(-A*d) [0-1]
      s = e^(-S*d) [0-1]
      s = e^(((a - 1) * S) / A) [0-1]

      At = A + S


      --ADAPT S, A BY Lo--
      knowns:
         Lo, Lgnd, Lsun=1, d=25 hue // d=40 value
      unknowns:
         S, A
      
      Lo=1  //green
      (Lgnd * at) + (Lsun * 1-s) = 0.24 //green
      0.24 < 1 => at-- or s++
         at++: what if Lgnd.g < 1 ? ... impossible
         s--: Lsun is generally white ... Lsun.g = 1

      Lo=0.01  //green
      (Lgnd * at) + (Lsun * 1-s) = 0.24 //green
      0.24 > 0.01 => at++ or s--
         at--: what if Lgnd.g < 0.01 ? ... ok
         s++: what if (Lgnd * at) > 0.01 ? ... impossible

      Conclusion:
         if((Lgnd * at) + (Lsun * 1-s) < Lo)
            s++;
         else
            at++;
      
      --Increase by how much?--
      assume: Lgnd=1, Lsun=1

      opacity (light unafected by absorption & scattering)
      = a
      (1 * at) + (1 * (1-s))
      at + 1-s
      at - s + 1 = Lo
      e^(-At*25) - e^(-S*25) = Lo - 1

      s++:
      (0 * at) + (1 * (1-s))     // black bg
      (1 * (1-s))
      1-s = L
      -s = L - 1
      -e^(((a - 1) * S) / A) = Lo - 1
      S = (A * ln(1 - L)) / (a - 1)

      a++:
      e^(-At*25) = Lo
      e^(-A*25) = Lo
      A = -(1/25) * ln(L)


      
      (1 * e^(-(a + s)*25)) + (1 * (1-e^(-s*25)))
      e^(-(a + s)*25) + (1-e^(-s*25))
      e^(-(a + s)) + (1-e^(-s))
      e^(-a - s) + 1 - e^(-s)
      1 + e^(-a - s) - e^(-s)
      1 + e^(-s) / e^a - e^(-s)
      1 + e^(-s) / e^a - e^(-s) / 1
      1 + e^(-s) / e^a - (e^(-s) * e^a) / e^a
      1 + (e^(-s) - e^(-s) * e^a) / e^a
   */
}