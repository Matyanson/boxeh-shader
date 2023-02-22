#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform float viewWidth, viewHeight;
uniform float near, far;

/*
const int colortex0Format = RGBA32F;
*/

vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
float samples[9] = float[](1, 1, 1, 1, 1, 1, 1, 1, 1);

void insert(float a, int position) {
    samples[position] = a;
    int i = position;

    while(i > 0 && samples[i] < samples[i - 1]) {
        // swap
        float temp = samples[i - 1];
        samples[i - 1] = samples[i];
        samples[i] = temp;

        i--;
    }
}

float getFocalDistance() {

    insert(texture2D(colortex3, vec2(0.5f, 0.5f)).r, 0);
    insert(texture2D(colortex3, vec2(0.515f, 0.5f)).r, 1);
    insert(texture2D(colortex3, vec2(0.5f, 0.515f)).r, 2);
    insert(texture2D(colortex3, vec2(0.485f, 0.5f)).r, 3);
    insert(texture2D(colortex3, vec2(0.5f, 0.485f)).r, 4);
    insert(texture2D(colortex3, vec2(0.515f, 0.515f)).r, 5);
    insert(texture2D(colortex3, vec2(0.485f, 0.485f)).r, 6);
    insert(texture2D(colortex3, vec2(0.485f, 0.515f)).r, 7);
    insert(texture2D(colortex3, vec2(0.515f, 0.485f)).r, 8);

    return samples[5];

    // float sum = 0.0f;
    // int radius = 7;
    // float spacing = 2 * texelSize.x;
    // float radiusTex = radius * spacing;
    // for(float x = 0.5 - radiusTex; x <= 0.5 + radiusTex; x += spacing) {
    //     sum += texture2D(colortex3, vec2(x, 0.5f).r);
    // }
    // spacing = 2 * texelSize.y;
    // radiusTex = radius * spacing;
    // for(float y = 0.5 - radiusTex; y <= 0.5 + radiusTex; y += spacing) {
    //     sum += texture2D(colortex3, vec2(0.5f, y).r);
    // }

    // return sum / (4 * radius + 2);  // TODO: use median instead of average
}

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    float depth = texture2D(colortex3, TexCoords).r;

    float focalDistance = getFocalDistance();
    float focusDifference = depth - focalDistance;
    float kernelScale = abs(focusDifference) / focalDistance;   // |depth - focalDistance| / focalDistance
    
    /* DRAWBUFFERS:4 */
    gl_FragData[0] = vec4(vec3(kernelScale), 1.0f);
}