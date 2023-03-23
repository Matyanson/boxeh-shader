#version 120

varying vec2 TexCoords;
varying float isWater;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform vec3 skyColor;
uniform float near, far;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

/*
const int colortex0Format = RGBA32F;
*/

vec3 screenSpace(vec2 coord, float depth){
	vec4 pos = gbufferProjectionInverse * (vec4(coord, depth, 1.0) * 2.0 - 1.0);
	return pos.xyz/pos.w;
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
   float dx = max(0 -point.x, point.x - 1); //-0.5
   float dy = max(0 -point.y, point.y - 1); //0.1
   return max(dx, dy);
}

void main() {
   vec3 color = texture2D(colortex0, TexCoords).rgb;
   float isWater = texture2D(colortex6, TexCoords).r;

   if(isWater < 0.9) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   
   float depth = texture2D(depthtex0, TexCoords).r;
   vec3 normal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
   vec3 fragPos = vec3(TexCoords, depth);
   vec3 fragPosView = toView(fragPos);
   fragPos = fragPos * 2 - 1;
   normal = normalize(mat3(gbufferModelView) * normal);
   vec3 projection = dot(fragPosView, normal) * normal;
   vec3 horizon = normalize(fragPosView - projection);
   horizon *= (far + 16);
   horizon = horizon + projection;

   

   vec3 ref = reflect(fragPosView, normalize(horizon));
   float angle = dot(normalize(ref), vec3(0, 0, 1));
   if(angle < 0) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   ref = viewToScreen(ref);
   vec3 refractPos = refract(normalize(fragPosView), normal, 1.333);
   refractPos = viewToScreen(refractPos);

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
   refractPos = vec3(TexCoords, 0);
   vec3 refractionColor = texture2D(colortex0, refractPos.xy).rgb;
   vec3 reflectionColor = texture2D(colortex0, ref.xy).rgb;
   float edgeTransiton = 0;
   float distFromScreen = 0.5 + distFromScreen(ref.xy);
   if(distFromScreen > 0)
      edgeTransiton = clamp(pow(distFromScreen, 2) * 3, 0, 1);
   reflectionColor = mix(reflectionColor, color, edgeTransiton);
   
   color = mix(reflectionColor, refractionColor, pow(fresnel, 0.5));
   /* DRAWBUFFERS:0 */
   gl_FragColor = vec4(color, 1.0f);
}