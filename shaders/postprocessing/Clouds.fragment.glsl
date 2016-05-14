#version 430 core

#include PostProcessEffectBase.glsl

#include Atmosphere.glsl

vec4 shade(){    
    vec2 val = CloudsGetCloudsCoverageShadow();
    return vec4(val.r, val.g, 0, 0);
}