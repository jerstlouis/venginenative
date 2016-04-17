#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D directTex;
layout(binding = 6) uniform sampler2D alTex;
layout(binding = 16) uniform sampler2D aoxTex;

uniform int UseAO;
uniform int UseGamma;

#include FXAA.glsl

const float SRGB_ALPHA = 0.055;
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
    return 12.92 * channel;
    else
    return (1.0 + SRGB_ALPHA) * pow(channel, 1.0/2.4) - SRGB_ALPHA;
}
vec3 rgb_to_srgb(vec3 rgb) {
    return UseGamma == 0 ? rgb : vec3(
    linear_to_srgb(rgb.r),
    linear_to_srgb(rgb.g),
    linear_to_srgb(rgb.b)
    );
}


vec4 shade(){    
    vec3 color = fxaa(directTex, UV).rgb + fxaa(alTex, UV).rgb * (UseAO ==1 ? fxaa(aoxTex, UV).r : 1.0);
    return vec4(rgb_to_srgb(color), textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
}