#version 120
#include "algorithms.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform vec3 skyColor;
uniform float near, far;
uniform int isEyeInWater;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

/*
const int colortex0Format = RGBA32F;
*/

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
   float dx = max(0 -point.x, point.x - 1);
   float dy = max(0 - point.y, point.y - 1);
   return max(dx, dy);
}

float LinearDepth(float z) {
   return 1.0 / ((1 - far / near) * z + (far / near));
}

float FogExp2(float viewDistance, float density) {
   float factor = viewDistance * (density / sqrt(log(2.0)));
   return exp2(-factor * factor);
}



vec3 screenBlend(vec3 base, vec3 blend) {
   return vec3(1) - ((vec3(1)-base) * (vec3(1)-blend));
}


void main() {
   vec3 color = texture2D(colortex0, TexCoords).rgb;
   float isReflective = texture2D(colortex6, TexCoords).g;

   if(
      // true || 
      isReflective < 0.9) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   
   float blockId = texture2D(colortex6, TexCoords).r;
   float depth = texture2D(depthtex0, TexCoords).r;
   float depthDeep = texture2D(depthtex1, TexCoords).r;
   vec3 normal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
   vec3 fragPos = vec3(TexCoords, depth);
   vec3 fragPosDeep = vec3(TexCoords, depthDeep);
   vec3 fragPosView = toView(fragPos);
   // fragPos = fragPos * 2 - 1;
   vec3 fragPosDeepView = toView(fragPosDeep);
   vec3 projection = dot(fragPosView, normal) * normal;
   vec3 c = fragPosView - projection;
   vec3 horizon = normalize(c);
   horizon *= (far + 16);
   horizon = normalize(horizon + projection);


   
   // calculate refraction
   // 1/1.333 * sin(a) = sin(b); 0.75 * sin(a) = sin(b)
   vec3 b = fragPosDeepView - fragPosView;
   float c2Length = 0.75 * (length(c) * length(b)) / length(fragPosView);
   vec3 refracted = fragPosView + dot(b, normal) * normal + c2Length * normalize(c);
   refracted = viewToScreen(refracted);
   blockId = texture2D(colortex6, refracted.xy).r;
   if(floor(blockId + 0.5) != 9){
      refracted.xy = TexCoords.xy;
   }
   vec3 refractionColor = texture2D(colortex0, refracted.xy).rgb;
   
   // update depth sample pos
   depth = texture2D(depthtex0, refracted.xy).r;
   depthDeep = texture2D(depthtex1, refracted.xy).r;


   float lightAlbedo = isEyeInWater == 1 ? 1.0 : texture2D(colortex1, TexCoords).b;
   float depthWater = LinearDepth(depthDeep) - LinearDepth(depth);
   refractionColor = isEyeInWater == 1 ? color : getWaterColor(refractionColor, toMeters(depthWater));
   // gl_FragColor = vec4(refractionColor, 1.0);
   // return;

   vec3 ref = reflect(fragPosView, normalize(horizon));
   float angle = dot(normalize(ref), vec3(0, 0, 1));
   ref = viewToScreen(ref);
   float refDepth = texture2D(depthtex0, ref.xy).r;

   blockId = texture2D(colortex6, ref.xy).r;
   if(angle < 0 || refDepth < depth || floor(blockId + 0.5) == 9){
      gl_FragColor = vec4(refractionColor, 1.0);
      return;
   }

   /*horizon = viewToScreen(horizon);
   horizon = horizon * 2.0 - 1.0;
   // horizon -= vec3(0,0.1,0);

   vec2 toHorizon = -fragPos.xy + horizon.xy;
   // project toHorizon on horizon direction
   vec2 horizonNorm = normalize(horizon.xy);
   toHorizon = dot(toHorizon, horizonNorm) * horizonNorm;

   vec2 reflection = fragPos.xy + 2 * toHorizon;
   reflection = fragPos.xy + 2 * toHorizon.xy;
   reflection = reflection * 0.5 + 0.5;*/

   float fresnel = clamp(dot(-normalize(fragPosView), normal), 0, 1);
   vec3 reflectionColor = texture2D(colortex0, ref.xy).rgb;
   float distFromScreen = 0.2 + distFromScreen(ref.xy);
   float edgeTransiton = 0;
   
   if(distFromScreen > 0)
      edgeTransiton = clamp(distFromScreen * 4, 0, 1);
   reflectionColor = mix(refractionColor, reflectionColor, (1 - edgeTransiton));
   
   color = mix(reflectionColor, refractionColor, pow(fresnel, 0.5));
   // color = refractionColor;
   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(color, 1.0);
}