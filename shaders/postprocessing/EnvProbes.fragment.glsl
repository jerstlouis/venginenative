#version 430 core

#include PostProcessEffectBase.glsl
#include Shade.glsl

layout(binding = 10) uniform samplerCube probeTex;

float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

#define MMAL_LOD_REGULATOR 1024
vec3 stupidBRDF(vec3 dir, float level, float roughness){
    vec3 aaprc = vec3(0.0);
    float xx=rand2s(UV);
    float xx2=rand2s(UV.yx);
    for(int x = 0; x < 4; x++){
        vec3 rd = vec3(
            rand2s(vec2(xx, xx2)),
            rand2s(vec2(-xx2, xx)),
            rand2s(vec2(xx2, xx))
        ) *2-1;
        vec3 displace = rd;
        vec3 prc = textureLod(probeTex, dir , level).rgb;
        aaprc += prc;
        xx += 0.01;
        xx2 -= 0.02123;
    }
    return aaprc / 4.0;
}

vec3 MMALSkybox(vec3 dir, float roughness){
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(probeTex)));
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 result = stupidBRDF(dir, mx * levels, roughness);
    
    //return pow(result * 1.2, vec3(2.0));
    return result;
}

uniform vec3 EnvProbePosition;
uniform int EnvProbePlanesCount;
#define MAX_ENV_PROBE_PLANES 20
uniform vec3 EnvProbePlanesPoints[MAX_ENV_PROBE_PLANES];
uniform vec3 EnvProbePlanesNormals[MAX_ENV_PROBE_PLANES];
uniform float EnvProbesLightMultiplier;

float intersectPlane(vec3 origin, vec3 direction, vec3 point,vec3 normal)
{
    return dot(point - origin, normal) / dot(direction, normal);
}

float currentFalloff = 0.0;
vec3 ENVMMAL(PostProceessingData data, vec3 dir){
    
    float fresnel = fresnel_again(data.normal, data.cameraPos, 0.08);
    float fresnelR = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.r);
    float fresnelG = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.g);
    float fresnelB = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.b);
    vec3 newBase = vec3(fresnelR, fresnelG, fresnelB);
    
    vec3 metallic = vec3(0);
    vec3 nonmetallic = vec3(0);
    
    metallic += MMALSkybox(dir, data.roughness) * newBase * mix(1.0, currentFalloff, data.roughness);
    
    nonmetallic += MMALSkybox(dir, data.roughness) * fresnel * mix(1.0, currentFalloff, data.roughness);
    nonmetallic += MMALSkybox(dir, 1.0) * data.diffuseColor * currentFalloff;
    
    return mix(nonmetallic, metallic, data.metalness);
    
}
vec3 raytracePlanes(vec3 origin, vec3 direction){
    float mindist = 999999.0;
    for(int i=0;i<EnvProbePlanesCount;i++){
        float inter = intersectPlane(origin, direction, EnvProbePlanesPoints[i], EnvProbePlanesNormals[i]);
        if(dot(direction, -EnvProbePlanesNormals[i]) > 0) mindist = min(mindist, inter);
    }
    vec3 c = vec3(0);
    if(mindist < 999990.0){
        vec3 newpos = (origin + direction * mindist);
        vec3 newdir = -normalize(EnvProbePosition - newpos);
      //  currentData.roughness = currentData.roughness * (distance(newpos, currentData.worldPos));
        currentFalloff = 1;//CalculateFallof(0.01*distance(newpos, currentData.worldPos));
        c = ENVMMAL(currentData, newdir);
    } else {
        c = ENVMMAL(currentData, direction);
    }
    return c * EnvProbesLightMultiplier;
}


uniform float Time;

vec4 shade(){
    vec4 color = vec4(0);
    if(currentData.cameraDistance > 0){
        vec3 reflected = normalize(reflect(currentData.cameraPos, currentData.normal));
        vec3 dir = normalize(mix(reflected, currentData.normal, currentData.roughness));
        color.rgb += raytracePlanes(currentData.worldPos, dir) *1;
    }
    return color.rgbb;
}