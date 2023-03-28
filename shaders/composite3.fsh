#version 120

varying vec2 TexCoords;
varying float isWater;
uniform sampler2D colortex0;
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
   // float dx = max(0 -point.x, point.x - 1);
   float dy = max(0 - point.y, point.y - 1);
   return dy;//max(dx, dy);
}

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0f)));
    return exp2(-factor * factor);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth) {
   float viewDistance = waterDepth * far - near;
   float shallow = FogExp2(viewDistance, 0.3);
   float deep = FogExp2(viewDistance, 0.1);
   vec3 shallowColor = vec3(0, 0.5, 0.95);
   vec3 deepColor = 0.05 * vec3(0, 0.05, 0.2);
   shallowColor = originalColor * mix(shallowColor, vec3(1), shallow);
   return mix(deepColor, shallowColor, deep);
}


void main() {
   vec3 color = texture2D(colortex0, TexCoords).rgb;
   float isWater = texture2D(colortex6, TexCoords).r;
   float depth = texture2D(depthtex0, TexCoords).r;

   if(isWater < 0.9) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   
   
   vec3 normal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
   vec3 fragPos = vec3(TexCoords, depth);
   vec3 fragPosView = toView(fragPos);
   fragPos = fragPos * 2 - 1;
   vec3 projection = dot(fragPosView, normal) * normal;
   vec3 horizon = normalize(fragPosView - projection);
   horizon *= (far + 16);
   horizon = horizon + projection;


   float depthDeep = texture2D(depthtex1, TexCoords).r;
   float depthWater = LinearDepth(depthDeep) - LinearDepth(depth);
   vec3 refractionColor = getWaterColor(color, depthWater);
   

   vec3 ref = reflect(fragPosView, normalize(horizon));
   float angle = dot(normalize(ref), vec3(0, 0, 1));
   ref = viewToScreen(ref);
   float refDepth = texture2D(depthtex0, ref.xy).r;


   if(angle < 0 || refDepth < depth) {
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
   float lightAlbedo = isEyeInWater == 1 ? 1.0 : texture2D(colortex6, TexCoords).g;
   float distFromScreen = 0.2 + distFromScreen(ref.xy);
   float edgeTransiton = 0;
   
   if(distFromScreen > 0)
      edgeTransiton = clamp(distFromScreen * 4, 0, 1);
   reflectionColor = mix(refractionColor, reflectionColor, (1 - edgeTransiton) * lightAlbedo);
   
   color = mix(reflectionColor, refractionColor, pow(fresnel, 0.5));
   // color = refractionColor;
   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(color, 1.0f);
}