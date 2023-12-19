#version 120

#include "/lib/settings.glsl"
#include "vec_component_operations.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform float viewWidth, viewHeight;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float near, far;
uniform mat4 gbufferProjection;


float luminance(vec3 color) {
    return dot(color, vec3(0.2125, 0.7153, 0.0721));
}

void main() {
      vec3 color = texture2D(colortex0, TexCoords).rgb;
   #if godRay == 0
      gl_FragColor = vec4(color, 1.0);
      return;
   #endif

   vec3 skyObjectPos = sunPosition;
   float FILTER = 0.015;
   float LUM_POW = 2;

   if(sunAngle > 0.5){
      skyObjectPos = moonPosition;
      FILTER = 0.15;
      LUM_POW = 1;
   }
   vec4 tpos = vec4(skyObjectPos, 1.0) * gbufferProjection;
   tpos = tpos / tpos.w;
   vec2 center = tpos.xy / tpos.z * 0.5 + 0.5;
   if(skyObjectPos.z > 0) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }

   float blurStart = 0.1;
   float blurWidth = 1;
   vec2 uv = TexCoords;

   #if godRay == 1
      vec2 diffV = uv - center;
      vec2 distV = diffV * vec2(viewWidth / viewHeight, 1);
      float dist = length(distV);
      float rayIntensity = max(0.8 - (dist), 0);
      float sunRadius = 0.06;

      vec2 sampleStep = dist < sunRadius ?
      diffV / NUM_SAMPLES :
      normalize(distV) * (sunRadius * vec2(viewHeight / viewWidth, 1)) / NUM_SAMPLES;
      vec2 sampleCoords = center;
      vec3 rayColor = vec3(0);
      
      for(int i = 0; i < NUM_SAMPLES; i++) {
         float sampleDepth = texture2D(depthtex0, sampleCoords).r;
         // test if pixel is sun
         #ifdef SAMPLE_COLOR
            vec3 sampleColor = texture2D(colortex0, sampleCoords).rgb;
            if(sampleDepth == 1.0 &&
               sampleColor.r + sampleColor.g + sampleColor.b > 2.5)
               rayColor += sampleColor;
         #else
            if(sampleDepth == 1.0)
               rayColor += vec3(1.0);
         #endif

         sampleCoords += sampleStep;
      }

      rayColor /= NUM_SAMPLES;
      color += scaleMaxTreshold(rayColor, 1.0) * rayIntensity*rayIntensity;

      #ifdef DEBUG_SUN_RADIUS
         //visualize sun radius
         if(dist > sunRadius && dist < sunRadius + 0.001)
            color *= 0.1;
      #endif
   #elif godRay == 2
      uv -= center;
      float precompute = blurWidth / float(NUM_SAMPLES - 1);

      vec3 rayColor = vec3(0.0);
      for(int i = 0; i < NUM_SAMPLES; i++)
      {
         float scale = blurStart + (float(i) * precompute);
         vec2 coords = uv * scale  + center;
         vec3 samCol = texture2D(colortex0, coords).rgb;
         float lum = pow(max(luminance(samCol) - 0.6, 0), LUM_POW);
         rayColor += samCol * lum;
      }

      rayColor /= float(NUM_SAMPLES);

      rayColor = vec3(pow(rayColor.r, 1.2), pow(rayColor.g, 1.2), pow(rayColor.b, 1.2));
      rayColor *= FILTER;
      color += rayColor;
   #endif

   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(color, 1.0);
}