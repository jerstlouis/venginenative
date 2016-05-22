#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D directTex;
layout(binding = 6) uniform sampler2D alTex;
layout(binding = 16) uniform sampler2D aoxTex;

uniform int UseAO;

#define CLOUD_SAMPLES 18
#define CLOUDCOVERAGE_DENSITY 50
#include Atmosphere.glsl

vec4 shade(){    
    vec3 color = texture(directTex, UV).rgb + texture(alTex, UV).rgb * (UseAO == 1 ? texture(aoxTex, UV).r : 1.0);

    color = ApplyAtmosphere(color, texture(cloudsCloudsTex, UV).rg);
    
    return vec4(color, 1.0);
}