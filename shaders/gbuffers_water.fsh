#version 120

#include "/lib/settings.glsl"

varying vec2 TexCoords;
varying vec4 Tint;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D colortex8;
uniform float frameTimeCounter;



mat3 getTBNMatrix(vec3 normal) {
    //https://viscircle.de/which-techniques-you-can-use-for-normal-mapping/?lang=en http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/#normal-textures
    // from tangent space to model space
    vec3 randomV = vec3(0, 0, 1);
    vec3 tangent = normalize(randomV - dot(randomV, normal) * normal);//normalize(randomV - normal.z * normal); //project randomV onto a plane defined by normal
    vec3 biTangent = normalize(cross(normal, tangent));

    mat3 TBN;
    TBN[0] = vec3(tangent.x, biTangent.x, normal.x);
    TBN[1] = vec3(tangent.y, biTangent.y, normal.y);
    TBN[2] = vec3(tangent.z, biTangent.z, normal.z);

    return TBN;
}

void main() {
    // Sample the color
    vec4 albedo = texture2D(texture, TexCoords);
    vec4 color = albedo * Tint;
    #ifndef customLighting
        vec4 light = texture2D(lightmap, LightmapCoords);
        color *= light;
    #endif
    
    /* DRAWBUFFERS:012456 */
    gl_FragData[4] = vec4(Normal * 0.5 + 0.5, 1.0);
    gl_FragData[5] = vec4(BlockId, 0.0, 1.0, 1.0);

    // write non-water to tex0
    if(floor(BlockId + 0.5) != 9){
        gl_FragData[0] = color;
        gl_FragData[1] = vec4(LightmapCoords, 1.0, 1.0);
        gl_FragData[2] = vec4(Normal * 0.5 + 0.5, 1.0);
        return;
    }


    #ifdef waterSurfaceWaves
        float offset = frameTimeCounter * 0.0035 ;
        vec3 waveNormalColor = texture2D(colortex8, (TexCoords + offset) * 64).rgb;
        vec3 waveNormal = waveNormalColor * 2.0 - 1.0;
        
        mat3 TBN = getTBNMatrix(Normal);
        vec3 normal = normalize(waveNormal) * TBN;
        normal = normalize(normal);
        normal = normal * 0.5 + 0.5;
    #else
        vec3 normal = Normal * 0.5 + 0.5;
    #endif

    #ifdef waterColor
        color = vec4(albedo.rgb, color.a * defaultWaterOpacity);
    #else
        color.a *= defaultWaterOpacity;
    #endif

    gl_FragData[3] = vec4(color.rgb, 1.0);
    gl_FragData[1] = vec4(LightmapCoords, 1.0 - color.a, 1.0);
    gl_FragData[2] = vec4(normal, 1.0);
}