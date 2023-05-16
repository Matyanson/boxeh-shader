#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

uniform sampler2D texture;
uniform sampler2D colortex7;

/*
const int colortex6Format = RGB16F;
*/

vec3 applyNormalMapOnSurface(vec3 surface, vec3 normal) {
    // https://math.stackexchange.com/a/476311
    float x = normal.x;
    float y = normal.y;
    float z = normal.z;
    float x2 = x * x;
    float y2 = y * y;
    float xy = x * y;
    float z1 = z + 1.0;

    mat3 rotation;
    rotation[0] = vec3(1.0 - x2/z1, -xy/z1,         x);
    rotation[1] = vec3(-xy/z1,      1.0 - y2/z1,    y);
    rotation[2] = vec3(-x,          -y,             1.0 - (x2 + y2)/z1);

    return surface * rotation;
}

void main() {
    // Sample the color
    vec4 albedo = texture2D(texture, TexCoords);

    vec3 waveNormalColor = texture2D(colortex7, TexCoords * 64).rgb;
    vec3 waveNormal = waveNormalColor * 2.0 - 1.0;
    
    vec3 normal = applyNormalMapOnSurface(Normal, normalize(waveNormal));
    normal = normalize(normal) * 0.5 + 0.5;

    /* DRAWBUFFERS:0126 */
    // gl_FragData[0] = vec4(albedo.rgb, 1) * vec4(Color.rgb, 0.5);
    gl_FragData[0] = vec4(albedo.rgb, 0.5);
    gl_FragData[1] = vec4(LightmapCoords, 0.0, 1.0);
    gl_FragData[2] = vec4(normal, 1.0);
    gl_FragData[3] = ivec4(BlockId, 1, 1, 1);
}