#version 120

#include "/lib/settings.glsl"
#include "algorithms.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform vec3 skyColor;
uniform float sunAngle;
uniform float near, far;
uniform int isEyeInWater;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;


float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 toView(vec3 pos) {
   vec4 result = vec4(pos, 1.0) * 2.0 - 1.0;
   result = (gbufferProjectionInverse * result);
   result /= result.w;
   return result.xyz;
}

vec3 toScreen(vec3 pos) {
   vec4 result = gbufferProjection * vec4(pos, 1.0);
   result /= result.w;
   return vec3(result * 0.5 + 0.5);
}

vec3 viewToScreen(vec3 viewPos) {
  vec3 data = mat3(gbufferProjection) * viewPos;
  data += gbufferProjection[3].xyz;
  return ((data.xyz / -viewPos.z) * 0.5 + 0.5).xyz;
}

float distFromScreen(vec2 point) {
   float dx = max(0 - point.x, point.x - 1);
   float dy = max(0 - point.y, point.y - 1);
   return max(dx, dy + 0.2);
}

float LinearDepth(float z) {
   return 1.0 / ((1 - far / near) * z + (far / near));
}


void main() {
   vec3 color = texture2D(colortex0, TexCoords).rgb;
   float blockId = texture2D(colortex3, TexCoords).r;
   float waterAlpha = texture2D(colortex1, TexCoords).b;

   if(waterAlpha > 0.99) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   
   /*---- 0. declare variables ----*/
   float depth = texture2D(depthtex0, TexCoords).r;
   vec3 fragPos = vec3(TexCoords, depth);
   vec3 fragPosView = toView(fragPos);
   vec3 normal = normalize(texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0);

   // float depthDeep = texture2D(depthtex1, TexCoords).r;
   // vec3 originalNormal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
   // vec3 normal = texture2D(colortex5, TexCoords).rgb * 2.0 - 1.0;
   // vec3 fragPosDeep = vec3(TexCoords, depthDeep);
   // // fragPos = fragPos * 2 - 1;
   // vec3 fragPosDeepView = toView(fragPosDeep);
   // vec3 projection = dot(fragPosView, normal) * normal;
   // vec3 c = fragPosView - projection;


   
   /*---- 1. calculate refraction ----*/
   // #ifdef waterRefraction
   //    // 1/1.333 * sin(a) = sin(b); 0.75 * sin(a) = sin(b)
   //    vec3 b = fragPosDeepView - fragPosView;
   //    float c2Length = 0.75 * (length(c) * length(b)) / length(fragPosView);
   //    vec3 refracted = fragPosView + dot(b, normal) * normal + c2Length * normalize(c);
   //    refracted = viewToScreen(refracted);

   //    // save refracted pixel color
   //    float refractedBlockId = texture2D(colortex3, refracted.xy).r;
   //    if(floor(refractedBlockId + 0.5) != 9){
   //       refracted.xy = TexCoords.xy;
   //    } else {
   //       refractionColor = texture2D(colortex0, refracted.xy).rgb;
      
   //       // update depth sample pos
   //       depth = texture2D(depthtex0, refracted.xy).r;
   //       depthDeep = texture2D(depthtex1, refracted.xy).r;
   //    }
      
   // #endif

   /*---- 2. calculate color underwater ----*/
   // #ifdef WATER_COLOR
   //    if(floor(blockId + 0.5) == 9) {
   //       // float lightAlbedo = isEyeInWater == 1 ? 1.0 : texture2D(colortex1, TexCoords).b;
   //       float depthWater = LinearDepth(depthDeep) - LinearDepth(depth);
   //       float LightIntensity = texture2D(colortex1, TexCoords).b;
   //       refractionColor = isEyeInWater == 1 ? color : getWaterColor(refractionColor, toMeters(depthWater), LightIntensity);
   //    }
   // #endif

   /*---- 3. calculate reflection -----*/
   #ifdef waterReflection
      vec2 ref = texture2D(colortex1, TexCoords).xy;

      float refDepth = texture2D(depthtex0, ref.xy).r;

      blockId = texture2D(colortex3, ref.xy).r;

      /*---- 4. combine reflextion and refraction ----*/
      vec3 reflectionColor = texture2D(colortex0, ref.xy).rgb;
      float fresnel = clamp(dot(-normalize(fragPosView), normal), 0, 1);
      float distFromScreen = distFromScreen(ref.xy);
      float edgeTransiton = 0;

      vec3 reflectionDefaultColor = isEyeInWater == 1 ? color : mix(color, skyColor, 0.2);
      if(refDepth < depth)
         reflectionColor = sunAngle > 0.0 && sunAngle < 0.45 ? reflectionDefaultColor : vec3(0.0);
      
      if(distFromScreen > 0)
         edgeTransiton = clamp(distFromScreen * 4, 0, 1);
      reflectionColor = mix(reflectionDefaultColor, reflectionColor, (1 - edgeTransiton));
      

      color = mix(reflectionColor, color, pow(fresnel, 0.5));
   #endif

   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(color, 1.0);
}