#version 430 core

#include PostProcessEffectBase.glsl

#define CLOUD_SAMPLES 256
#define CLOUDCOVERAGE_DENSITY 90
#include Atmosphere.glsl

vec4 shade(){    
    vec3 val = AtmScatt();
    return vec4(val.r, val.g, val.b, 0);
    //return vec4(0);
}