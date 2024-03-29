#define customLighting
#define ambientLight 0.0005 // [0 0.0005 0.001 0.002 0.003 0.004 0.005]

#define shadows
#define SHADOW_SAMPLES 1

#define atmosphericFog
#define FOG_DENSITY 0.003//0.008
#define RAIN_MODIFIER 0.012;

#define customWater
#ifdef customWater
    #define WATER_COLOR 1 // [0 1 2]
    #define waterRefraction
    #define waterReflection
    #define waterSurfaceWaves
    #define defaultWaterOpacity 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#else
    #define defaultWaterOpacity 1.0
#endif

#define godRay 1 //[0 1 2]
#define RAY_RADIUS 0.8 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define RAY_INTENSITY 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SAMPLE_COLOR
#define DEBUG_SUN_RADIUS 0 //[0 1]
#define NUM_SAMPLES 1 //[1 5 10 25 50 100]

#define DOF



