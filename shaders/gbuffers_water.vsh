#version 120

varying vec2 TexCoords;
varying vec4 Color;
varying vec2 LightmapCoords;
varying vec3 Normal;
flat varying int BlockId;

attribute vec4 mc_Entity;

#define waterWaving
float waterWaveIntensity = 0.50; //Will look broken over 1.45[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
float waterWaveSpeed = 0.40; //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// from Tea shaders
#ifdef waterWaving
	uniform int worldTime;
	uniform float frameTimeCounter;
	uniform mat4 gbufferModelView;
	uniform mat4 gbufferModelViewInverse;
	uniform vec3 cameraPosition;

	varying vec3 wpos;

	const float PI = 3.1415927;
#endif

void main() {
    TexCoords = gl_MultiTexCoord0.st;    

    Color = gl_Color;
    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LightmapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05 / 32.0) - (1.05 / 32.0);
    Normal = normalize(gl_NormalMatrix * gl_Normal);
    BlockId = int(mc_Entity.x);


    #ifndef waterWaving
		gl_Position = ftransform();
	#else
		if(floor(mc_Entity.x + 0.5) != 9) return;
		vec4 position = gl_ModelViewMatrix * gl_Vertex;

		vec4 viewpos = gbufferModelViewInverse * position;

		vec3 worldpos = viewpos.xyz + cameraPosition;
		wpos = worldpos;

		float displacement = 0.0;

        float fy = fract(worldpos.y + 0.0001);

        float wave = 0.07 * sin(2 * PI * (frameTimeCounter*waterWaveSpeed + worldpos.x /  7.0 + worldpos.z / 13.0)) +
                     0.02 * sin(2 * PI * (frameTimeCounter*(waterWaveSpeed * 0.8) + worldpos.x / 1.0 + worldpos.z /  5.0));

        displacement = clamp(wave, -fy, 1.0-fy);
        viewpos.y += displacement*waterWaveIntensity;

		viewpos = gbufferModelView * viewpos;
		gl_Position = gl_ProjectionMatrix * viewpos;
	#endif
}