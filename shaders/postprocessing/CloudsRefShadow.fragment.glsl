#version 430 core

#include PostProcessEffectBase.glsl

#define CLOUD_SAMPLES 0
#define CLOUDCOVERAGE_DENSITY 50
#include Atmosphere.glsl

vec4 shade(){    
    //vec4 val = CloudsRefShadow();
    //return val;
    return vec4(0);
}