#define customLighting
#define ambientLight 0.0005 // [0 0.0005 0.001 0.002 0.003 0.004 0.005]

#define shadows
#define SHADOW_SAMPLES 1

#define atmosphericFog
#define FOG_DENSITY 0.003//0.008
#define RAIN_MODIFIER 0.012;

#define customWater
#ifdef customWater
    #define waterColor
    #define waterRefraction
    #define waterReflection
    #define waterSurfaceWaves
    #define defaultWaterOpacity 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#else
    #define defaultWaterOpacity 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#endif

#define godRay
#define NUM_SAMPLES 10

#define DOF



