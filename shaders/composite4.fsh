#version 120

#include "/lib/settings.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex2;
uniform float viewWidth, viewHeight;
uniform float near, far;


#ifdef DOF
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

    float getFocalDistance(sampler2D tex) {

        insert(texture2D(tex, vec2(0.5, 0.5)).r, 0);
        insert(texture2D(tex, vec2(0.515, 0.5)).r, 1);
        insert(texture2D(tex, vec2(0.5, 0.515)).r, 2);
        insert(texture2D(tex, vec2(0.485, 0.5)).r, 3);
        insert(texture2D(tex, vec2(0.5, 0.485)).r, 4);
        insert(texture2D(tex, vec2(0.515, 0.515)).r, 5);
        insert(texture2D(tex, vec2(0.485, 0.485)).r, 6);
        insert(texture2D(tex, vec2(0.485, 0.515)).r, 7);
        insert(texture2D(tex, vec2(0.515, 0.485)).r, 8);

        return samples[5];

        // float sum = 0.0;
        // int radius = 7;
        // float spacing = 2 * texelSize.x;
        // float radiusTex = radius * spacing;
        // for(float x = 0.5 - radiusTex; x <= 0.5 + radiusTex; x += spacing) {
        //     sum += texture2D(colortex3, vec2(x, 0.5).r);
        // }
        // spacing = 2 * texelSize.y;
        // radiusTex = radius * spacing;
        // for(float y = 0.5 - radiusTex; y <= 0.5 + radiusTex; y += spacing) {
        //     sum += texture2D(colortex3, vec2(0.5, y).r);
        // }

        // return sum / (4 * radius + 2);  // TODO: use median instead of average
    }

    float LinearDepth(float z) {
        return 1.0 / ((1 - far / near) * z + (far / near));
    }
#endif

void main() {
    #ifdef DOF
        float itemlessDepth = getFocalDistance(depthtex2);
        float depth = texture2D(colortex3, TexCoords).r;
        float focalDistance = getFocalDistance(colortex3);
        focalDistance = max(focalDistance, LinearDepth(itemlessDepth));
        
        // convert distance to blocks(m)
        depth =         near + depth * (far - near);
        focalDistance = near + focalDistance * (far - near);

        if(depth < 0.17) {
            gl_FragData[0] = vec4(vec3(0.01), 1.0);
            return;
        }

        // don't focus too close (on items in hand)
        // depth = max(depth, 1);

        // eye focal length = 17mm = 0.017m, 1 / 0.017 = 58.82;
        depth = depth * 58.82;
        focalDistance = focalDistance * 58.82;
        
        float dist1 = 1.0 / (focalDistance - 1.0) + 1.0;
        float dist2 = 1.0 / (depth - 1.0) + 1.0;
        float focusDifference = dist2 - dist1;
        float kernelScale = min(abs(focusDifference) / dist1, 1);   // |depth - focalDistance| / focalDistance
        
        /* DRAWBUFFERS:4 */
        gl_FragData[0] = vec4(vec3(kernelScale), 1);
    #endif
}