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

float rdhash = 0.453451 + Time;
vec2 randpoint2(){
    float x = rand2s(UV * rdhash);
    rdhash += 2.1231255;
    float y = rand2s(UV * rdhash);
    rdhash += 1.6271255;
    return vec2(x, y) * 2.0 - 1.0;
}

float aaoo(){
    vec2 uv = reverseViewDir();
    float center = texture(cloudsCloudsTex, uv).b;
    float aoc = 0;
    for(int i=0;i<32;i++){
        vec2 rdp = randpoint2() * 0.01;
        float there = texture(cloudsCloudsTex, uv + rdp).b;
        float w = 1.0 - smoothstep(1000.0, 10000, center - there);
        aoc += w * clamp(center - there, 0.0, 1000.0) * 0.001;
    }
    return pow(1.0 - aoc / 32.0, 16.0);
}

vec4 shade(){    
    vec3 color = texture(directTex, UV).rgb + texture(alTex, UV).rgb * (UseAO == 1 ? texture(aoxTex, UV).r : 1.0);

    vec4 cdata = texture(cloudsCloudsTex, reverseViewDir()).rgba;
    vec3 scatt = AtmScatt();
    atmcolor = getAtmosphereForDirection(vec3(0), normalize(SunDirection), normalize(SunDirection));
    atmcolor1 = getAtmosphereForDirection(vec3(0), vec3(0,1,0), normalize(SunDirection));
    vec3 colorcloud = mix(atmcolor, atmcolor1 , 1.0 - aaoo());
    color = mix(scatt, colorcloud, cdata.r);
    
    return vec4( color, 1.0);
}