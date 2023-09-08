#version 120

varying vec2 TexCoords;
varying vec4 Tint;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D colortex7;
uniform float frameTimeCounter;

/*
const int colortex5Format = RGBA32F;
const int colortex6Format = RGB16F;
*/

#define waterSurfaceWaves
#define waterColor
#define defaultWaterOpacity 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]


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
    
    /* DRAWBUFFERS:01256 */
    gl_FragData[1] = vec4(LightmapCoords, 0.0, 1.0);
    gl_FragData[2] = vec4(Normal * 0.5 + 0.5, 1.0);
    gl_FragData[4] = ivec4(BlockId, 1, 1, 1);

    if(floor(BlockId + 0.5) != 9){
        gl_FragData[0] = color;
        gl_FragData[3] = vec4(Normal * 0.5 + 0.5, 1.0);
        return;
    }

    #ifdef waterSurfaceWaves
        float offset = frameTimeCounter * 0.0035 ;
        vec3 waveNormalColor = texture2D(colortex7, (TexCoords + offset) * 64).rgb;
        vec3 waveNormal = waveNormalColor * 2.0 - 1.0;
        
        mat3 TBN = getTBNMatrix(Normal);
        vec3 normal = normalize(waveNormal) * TBN;
        normal = normalize(normal);
        normal = normal * 0.5 + 0.5;
    #else
        vec3 normal = Normal * 0.5 + 0.5;
    #endif

    #ifdef waterColor
        gl_FragData[0] = vec4(albedo.rgb, defaultWaterOpacity);
    #else
        color.a *= defaultWaterOpacity;
        gl_FragData[0] = color;
    #endif
    gl_FragData[3] = vec4(normal, 1.0);
}