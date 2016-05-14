#version 430 core

#include PostProcessEffectBase.glsl

#define CLOUD_SAMPLES 96
#define CLOUDCOVERAGE_DENSITY 90
#include Atmosphere.glsl

vec4 shade(){    
    vec2 val = CloudsGetCloudsCoverageShadow();
    return vec4(val.r, val.g, 0, 0);
}