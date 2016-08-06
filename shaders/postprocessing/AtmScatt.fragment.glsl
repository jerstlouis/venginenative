#version 430 core

#include PostProcessEffectBase.glsl

#define CLOUD_SAMPLES 256
#define CLOUDCOVERAGE_DENSITY 90
#include Atmosphere.glsl

vec4 shade(){    
    vec3 val = AtmScatt(vec3(0,1,0), getViewDir2());
    return vec4(val.r, val.g, val.b, 0);
    //return vec4(0);
}