#version 120
#include "distort.glsl"
#include "vec_component_operations.glsl"

#define SHADOW_SAMPLES 1

varying vec2 TexCoords;
out vec3 sunColor;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform int moonPhase;
uniform float near, far;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
const int colortex3Format = R32F;
*/

const int ShadowSamplesPerSize = 1 * SHADOW_SAMPLES + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;
const float sunPathRotation = 37.7f;
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;

const float Ambient = 0.025f;

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.0001f, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0f - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

vec3 getShadow(float depth){
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    // out of bounds fix
    if(SampleCoords.z > 0.9999 || SampleCoords.x > 1 || SampleCoords.x < 0 || SampleCoords.y > 1 || SampleCoords.y < 0)
        return vec3(1.0);
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;

    // blur
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
    float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;
    vec3 ShadowAccum = vec3(0.0f);
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

float LinearDepth(float z) {
    return 1.0 / ((1 - far / near) * z + (far / near));
}

float AdjustLightmapTorch(in float torch) {
    /*
        default:    fx = 1 - x
        mine:       e(fx), ex = 1/(x^2), normalize => ((1+k) / (k + x^2) - 1) * k
    */
    const float k = 0.1;
    float percentage = (1.0f + k) / (k + pow(1f - torch, 2.0f)) - 1;
    return percentage * k;
}

float AdjustLightmapSky(in float sky){
    const float K = 1.2f;
    const float P = 2.4f;
    return K * pow(sky, P);
}

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

vec3 GetLightmapColor(in vec2 Lightmap, float torchIntensity, float skyIntensity){
    // First adjust the lightmap
    Lightmap = AdjustLightmap(Lightmap);

    const vec3 TorchColor = vec3(1.0f, 0.6f, 0.2f);
    const vec3 SkyColor = vec3(0.9f, 0.9f, 1.0f);   // slightly blue

    vec3 TorchLighting = torchIntensity * Lightmap.x * TorchColor;
    vec3 SkyLighting = skyIntensity * Lightmap.y * SkyColor;
    vec3 LightmapLighting = TorchLighting + SkyLighting;

    return LightmapLighting;
}

vec3 getLight(vec2 Lightmap, float NdotL, float depth) {
    vec3 noonColor = vec3(1.0f, 1.0f, 0.9f);    // slightly yellow
    vec3 sunsetColor = vec3(1.0f, 0.42f, 0.0f); //vec3(1.0f, 0.78f, 0.62f);    // orange - represented by rgb wavelength
    float sunDayAngle = abs(4 * sunAngle - 2) - 1;
    sunColor = mix(noonColor, sunsetColor, sunDayAngle * sunDayAngle);
    vec3 RayColor = 1.5f * getShadow(depth) * sunColor;
    float moonIntensity = (8  - moonPhase) / 8f * 0.12f;
    float sunIntensity = 1;
    if(abs(sunDayAngle) > 0.75) {
        float t = (4*(abs(sunDayAngle)-0.75));
        sunIntensity = moonIntensity * t + 1-t;
        NdotL *= (1-t);
    }

    vec3 light = sunAngle < 0.5f ?
        NdotL * RayColor + GetLightmapColor(Lightmap, 0.7, sunIntensity * 0.1) :
        moonIntensity * NdotL * RayColor + GetLightmapColor(Lightmap, 0.7, moonIntensity * 0.1);
    //return RayColor;
    return scaleMaxTreshold(light, 1.15);
}

void main(){
    // Account for gamma correction
    vec3 Color = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2f));
        sunColor = vec3(0.0);
    // ignore sky
    float depth = texture2D(depthtex0, TexCoords).r;
    gl_FragData[1] = vec4(LinearDepth(depth));
    if(depth == 1.0f){
        gl_FragData[0] = vec4(Color, 1.0f);
        return;
    }
    // Get the normal
    vec3 Normal = normalize(texture2D(colortex2, TexCoords).rgb * 2.0f - 1.0f);
    // Get the lightmap
    vec2 Lightmap = texture2D(colortex1, TexCoords).rg;
    // Compute cos theta between the normal and sun directions
    float NdotL = sunAngle > 0.5f ?
        max(dot(Normal, normalize(moonPosition)), 0.0f) :
        max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Do the lighting calculations
    vec3 light = getLight(Lightmap, NdotL, depth);
    vec3 Diffuse = Color * light;
    /* DRAWBUFFERS:03 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}