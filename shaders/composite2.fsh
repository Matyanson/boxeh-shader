#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;

uniform float viewWidth, viewHeight;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float near, far;
uniform mat4 gbufferProjection;

/*
const int colortex0Format = RGBA32F;
*/

#define NUM_SAMPLES 100

float luminance(vec3 color) {
    return dot(color, vec3(0.2125, 0.7153, 0.0721));
}

void main() {
   vec3 albedo = texture2D(colortex0, TexCoords).rgb;
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
      gl_FragColor = vec4(albedo, 1.0);
      return;
   }

	float blurStart = 0.05;
   float blurWidth = 1;

    
	vec2 uv = TexCoords;
    
   uv -= center;
   float precompute = blurWidth / float(NUM_SAMPLES - 1);
   
   vec3 color = vec3(0.0);
   // float dist = sqrt(pow(TexCoords.x - center.x, 2) + pow(TexCoords.y - center.y, 2));
   for(int i = 0; i < NUM_SAMPLES; i++)
   {
      float scale = blurStart + (float(i) * precompute);
      vec2 coords = uv * scale  + center;
      vec3 samCol = texture2D(colortex0, coords).rgb;
      float lum = pow(max(luminance(samCol) - 0.6, 0), LUM_POW);
      color += samCol * lum;// * (1-(dist));
   }

   color /= float(NUM_SAMPLES);

   color = vec3(pow(color.r, 1.2), pow(color.g, 1.2), pow(color.b, 1.2));
   color *= FILTER;
   albedo += color;

   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(albedo, 1.0);
}