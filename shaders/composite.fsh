#version 120
#include "distort.glsl"
#include "algorithms.glsl"
#include "vec_component_operations.glsl"

#define SHADOW_SAMPLES 1

varying vec2 TexCoords;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform int moonPhase;
uniform float near, far;
uniform int isEyeInWater;

// The color textures which we wrote to
uniform sampler2D colortex0;    // non-water color
uniform sampler2D colortex1;    // lightmap, water alpha
uniform sampler2D colortex2;    // normal
uniform sampler2D colortex3;    // terrain color
uniform sampler2D colortex4;    // water color
uniform sampler2D colortex5;    // original normal -> dof color blur
uniform sampler2D colortex6;    // blockId
uniform sampler2D colortex7;    // isEntity
uniform sampler2D depthtex0;    // depth
uniform sampler2D depthtex2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

/*
const int colortex0Format = RGB16F;
const int colortex1Format = RGB16F;
const int colortex2Format = RGB16F;
const int colortex3Format = RGB16F;
const int colortex4Format = RGB16F;
const int colortex5Format = RGB16F;
const int colortex6Format = R16F;
const int colortex7Format = R16F;
*/

const int ShadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;
const float sunPathRotation = 37.7;
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;

const float Ambient = 0.025;

#define ambientLight 0.0005 // [0 0.0005 0.001 0.002 0.003 0.004 0.005]
#define waterColor
#define waterRefraction
#define waterReflection
#define customLighting
#define shadows

vec3 viewToScreen(vec3 viewPos) {
  vec3 data = mat3(gbufferProjection) * viewPos;
  data += gbufferProjection[3].xyz;
  return ((data.xyz / -viewPos.z) * 0.5 + 0.5).xyz;
}

vec3 toView(vec3 pos) {
   vec4 result = vec4(pos, 1.0) * 2.0 - 1.0;
   result = (gbufferProjectionInverse * result);
   result /= result.w;
   return result.xyz;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.0004, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0 - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0), ShadowVisibility0);
}

vec3 getShadow(float depth){
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0 - 1.0;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5 + 0.5;
    // out of bounds fix
    if(SampleCoords.z > 0.9999 || SampleCoords.x > 1 || SampleCoords.x < 0 || SampleCoords.y > 1 || SampleCoords.y < 0)
        return vec3(1.0);
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    SampleCoords = ShadowSpace.xyz * 0.5 + 0.5;

    // blur
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0).r * 100.0;
    float cosTheta = cos(RandomAngle);
    float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;
    vec3 ShadowAccum = vec3(0.0);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 Offset = vec2(x, y) * Rotation;
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
}

float toMeters(float depth) {
   return near + depth * (far - near);
}

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

float AdjustLightmapTorch(in float torch) {
    /*
        default:    fx = 1 - x
        mine:       e(fx), ex = 1/(x^2), normalize => ((1+k) / (k + x^2) - 1) * k
    */
    const float k = 0.01;
    float percentage = (1.0 + k) / (k + pow(1 - torch, 2.0)) - 1;
    return percentage * k;
}

float AdjustLightmapSky(in float sky){
    // fix: don't accept negative values
    sky = max(sky, 0.0);
    const float K = 1.2;
    const float P = 2.4;
    return K * pow(sky, P);
}

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

vec3 GetLightmapColor(in vec2 Lightmap, float torchIntensity, float skyIntensity){
    // Transform Lightmap into the [0, 1] range; fix: previous - Lightmap = (Lightmap * 33.05 / 32.0) - (1.05f / 32.0);
    Lightmap = (Lightmap * 37f / 32.0) - (1.05f / 32.0);
    // Adjust the lightmap
    Lightmap = AdjustLightmap(Lightmap);

    const vec3 TorchColor = vec3(1.0, 0.6, 0.2);
    const vec3 SkyColor = vec3(0.9, 0.9, 1.0);   // slightly blue

    vec3 TorchLighting = torchIntensity * Lightmap.x * TorchColor;
    vec3 SkyLighting = skyIntensity * Lightmap.y * SkyColor;
    vec3 LightmapLighting = TorchLighting + SkyLighting;

    return LightmapLighting;
}

vec3 getLight(vec2 Lightmap, float NdotL, float depth) {
    vec3 noonColor = vec3(1.0, 1.0, 0.9);    // slightly yellow
    vec3 sunsetColor = vec3(1.0, 0.42, 0.0); //vec3(1.0, 0.78, 0.62);    // orange - represented by rgb wavelength
    float sunDayAngle = abs(4 * sunAngle - 2) - 1;
    vec3 sunColor = mix(noonColor, sunsetColor, sunDayAngle * sunDayAngle);
    #ifdef shadows
        vec3 shadow = getShadow(depth);
        vec3 RayColor = 2.0 * shadow * sunColor;
    #else
        vec3 RayColor = 2.0 * sunColor;
    #endif
    float moonIntensity = (8  - moonPhase) / 8 * 0.12;
    float sunIntensity = 1.0;
    if(abs(sunDayAngle) > 0.75) {
        float t = (4*(abs(sunDayAngle)-0.75));
        sunIntensity = moonIntensity * t + 1-t;
        NdotL *= (1-t);
    }

    vec3 light = sunAngle < 0.5 ?
        NdotL * RayColor + GetLightmapColor(Lightmap, 0.7, sunIntensity * 0.3) :
        moonIntensity * NdotL * RayColor + GetLightmapColor(Lightmap, 0.7, moonIntensity * 0.3);

    light += ambientLight;
    
    //return RayColor;
    return scaleMaxTreshold(light, 1.15);
}

void main(){
    vec3 color = texture2D(colortex0, TexCoords).rgb;
    vec3 waterTextureColor = texture2D(colortex4, TexCoords).rgb;
    float waterAlpha = texture2D(colortex1, TexCoords).b;

    /*---- 0. declare variables ----*/
    float blockId = texture2D(colortex6, TexCoords).r;
    bool isWater = floor(blockId + 0.5) == 9;
    vec3 normal = texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0;
    float depth = texture2D(depthtex0, TexCoords).r;
    float depthDeep = texture2D(depthtex2, TexCoords).r;
    vec3 fragPos = vec3(TexCoords, depth);
    vec3 fragPosDeep = vec3(TexCoords, depthDeep);
    vec3 fragPosView = toView(fragPos);
    vec3 fragPosDeepView = toView(fragPosDeep);

    vec3 projection = dot(fragPosView, normal) * normal;
    vec3 c = fragPosView - projection;

    
    /*---- 1. calculate refraction ----*/
    #ifdef waterRefraction
    if(floor(blockId + 0.5) == 9){
        // 1/1.333 * sin(a) = sin(b); 0.75 * sin(a) = sin(b)
        /*
        sin(alpha) = len(c)/len(fragPosView)
        sin(beta) = len(c2)/len(b)

        0.75 * sin(alpha) = sin(beta)
        0.75 * (len(c)/len(fragPosView)) = len(c2)/len(b)
        (0.75 * (len(c)/len(fragPosView))) * len(b) = len(c2)
        0.75 * len(b) * (len(c) / len(fragPosView)) = len(c2)
        */
        vec3 b = fragPosDeepView - fragPosView;
        // temp fix
        b = 3 * normalize(b);
        float c2Length = 0.75 * length(c) * (length(b) / length(fragPosView));
        vec3 refracted = fragPosView + dot(b, normal) * normal + c2Length * normalize(c);
        refracted = viewToScreen(refracted);

        float refBlockId = texture2D(colortex6, refracted.xy).r;
        if(floor(refBlockId + 0.5) == 9) {
            color = texture2D(colortex0, refracted.xy).rgb;
            //update depth
            depth = texture2D(depthtex0, refracted.xy).r;
            depthDeep = texture2D(depthtex2, refracted.xy).r;
        } else {
            float isEntity = texture2D(colortex7, refracted.xy).r;
            if(isEntity < 0.1)
                color = texture2D(colortex3, refracted.xy).rgb;
        }
    }
    #endif

    vec3 ref = vec3(1.0);
    #ifdef waterReflection
    if(floor(blockId + 0.5) == 9){
        vec3 originalNormal = texture2D(colortex5, TexCoords).rgb * 2.0 - 1.0;

        // fix: don't reflect under horizon
        if(
            dot(originalNormal, normalize(c)) <
            dot(normal, normalize(fragPosView))
        ) {
            normal = originalNormal;
            projection = dot(fragPosView, normal) * normal;
            c = fragPosView - projection;
        }

        vec3 horizon = normalize(c);
        horizon *= (far + 16);
        horizon = normalize(horizon + projection);

        ref = reflect(fragPosView, normalize(horizon));
        ref = viewToScreen(ref);
    }
    #endif

    // combine base and water texture
    color = mix(waterTextureColor, color, waterAlpha);
    // Account for gamma correction
    color = pow(color, vec3(2.2));

    // ignore sky
    gl_FragData[2] = vec4(LinearDepth(depth));
    if(
        // true ||
         depth == 1.0){
        gl_FragData[0] = vec4(color, 1.0);
        return;
    }
    // Get the lightmap
    vec2 Lightmap = texture2D(colortex1, TexCoords).rg;
    // Compute cos theta between the normal and sun directions
    float NdotL = sunAngle > 0.5 ?
        max(dot(normal, normalize(moonPosition)), 0.0) :
        max(dot(normal, normalize(sunPosition)), 0.0);

    // Do the lighting calculations
    #ifdef customLighting
        vec3 light = getLight(Lightmap, NdotL, depth);
        /*---- 2. calculate color underwater ----*/
        #ifdef waterColor
        if(floor(blockId + 0.5) == 9){
            float depthWater = LinearDepth(depthDeep) - LinearDepth(depth);
            color = isEyeInWater == 1 ? color : getWaterColor(color, toMeters(depthWater), light.b);
        }
        #endif
        vec3 Diffuse = color * light;
    #else
        vec3 Diffuse = color;
    #endif
    /* DRAWBUFFERS:013 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0);
    gl_FragData[1] = vec4(ref.x, ref.y, waterAlpha, 1.0);
}