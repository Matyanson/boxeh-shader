#version 120

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

float toMeters(float depth) {
   return near + depth * (far - near);
}

vec3 getWaterColor(vec3 originalColor, float waterDepth, float lightAlbedo) {
   float viewDistance = toMeters(waterDepth);
   vec3 sunColor = vec3(1.0);
   
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


void main() {
   vec3 color = texture2D(colortex0, TexCoords).rgb;
   float isReflective = texture2D(colortex6, TexCoords).g;
   float depth = texture2D(depthtex0, TexCoords).r;

   if(isReflective < 0.9) {
      gl_FragColor = vec4(color, 1.0);
      return;
   }
   
   float blockId = texture2D(colortex6, TexCoords).r;
   vec3 normal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
   vec3 fragPos = vec3(TexCoords, depth);
   vec3 fragPosView = toView(fragPos);
   fragPos = fragPos * 2 - 1;
   vec3 projection = dot(fragPosView, normal) * normal;
   vec3 horizon = normalize(fragPosView - projection);
   horizon *= (far + 16);
   horizon = horizon + projection;


   float lightAlbedo = isEyeInWater == 1 ? 1.0 : texture2D(colortex1, TexCoords).b;
   float depthDeep = texture2D(depthtex1, TexCoords).r;
   float depthWater = LinearDepth(depthDeep) - LinearDepth(depth);
   vec3 refractionColor = isEyeInWater == 1 ? color : getWaterColor(color, depthWater, lightAlbedo);
   gl_FragColor = vec4(refractionColor, 1.0);
   return;

   vec3 ref = reflect(fragPosView, normalize(horizon));
   float angle = dot(normalize(ref), vec3(0, 0, 1));
   ref = viewToScreen(ref);
   float refDepth = texture2D(depthtex0, ref.xy).r;

   if(floor(blockId + 0.5) != 9)
      refractionColor = color;

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