#version 430 core

#include PostProcessEffectBase.glsl
#include Shade.glsl

layout(binding = 10) uniform samplerCube probeTex;
layout(binding = 16) uniform sampler2D aoxTex;
layout(binding = 3) uniform samplerCube skyboxTex;

float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

#define MMAL_LOD_REGULATOR 1024
vec3 stupidBRDF(vec3 dir, float level, float roughness){
    return textureLod(probeTex, dir , level).rgb;
}

vec3 MMALSkybox(vec3 dir, float roughness){
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(probeTex)) - 2.0);
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

float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{ return dot(point - origin, normal) / dot(direction, normal); }

float currentFalloff = 1.0;
vec3 ENVMMAL(PostProceessingData data, vec3 dir){
    
    float fresnel = fresnel_again(data.normal, data.cameraPos, 0.04);
    float fresnelR = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.r);
    float fresnelG = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.g);
    float fresnelB = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.b);
    vec3 newBase = mix(vec3(fresnelR, fresnelG, fresnelB), data.diffuseColor, data.roughness);
    
    vec3 metallic = vec3(0);
    vec3 nonmetallic = vec3(0);
    
    metallic += MMALSkybox(dir, data.roughness) * newBase;
    
    nonmetallic += MMALSkybox(dir, data.roughness) * mix(fresnel * 1, 0.04, data.roughness);
    nonmetallic += MMALSkybox(dir, 1.0) *  data.diffuseColor;
    
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
        //float att = CalculateFallof(0.05 * abs(dst - mindist));
      //  currentData.roughness = currentData.roughness * (distance(newpos, currentData.worldPos));
        //currentFalloff = att;//CalculateFallof(0.01*distance(newpos, currentData.worldPos));
        c = ENVMMAL(currentData, newdir);
    } else {
        c = ENVMMAL(currentData, direction);
    }
    return c * EnvProbesLightMultiplier;
}

vec3 rayMarchDepth(vec3 origin, vec3 direction){
    float mindist = 999999.0;
    vec3 closest = direction;
    vec3 meter = origin;
    float vis = 1.0;
    float vvis = 1.0;
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(probeTex)) - 2.0);
    float mx = log2(currentData.roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 colo = vec3(0);
    float weight = 0.0;
    float weight2 = 1.0;
    for(int i=0;i<50;i++){
        float inter = textureLod(probeTex, normalize(meter - EnvProbePosition), 0).a;
        float dst = 1.0 / (abs(inter - distance(EnvProbePosition, meter)) + 0.1);
        
        closest = normalize(meter - EnvProbePosition);
        weight2 *= dst;
        weight += dst;
        colo += ENVMMAL(currentData, closest) * dst;
        
        meter += direction * 0.25;
        vis -= 0.02;
    }
    colo /= max(0.01, weight);

    return clamp(colo, 0.0, 1.0) * EnvProbesLightMultiplier;
}

    
uniform float Time;

vec4 shade(){
    vec4 color = vec4(0);
    if(currentData.cameraDistance > 0){
        vec3 reflected = normalize(reflect(currentData.cameraPos, currentData.normal));
        vec3 dir = normalize(mix(reflected, currentData.normal, currentData.roughness));
        float ao = EnvProbesLightMultiplier == 1.0 ? texture(aoxTex, UV).r : 1.0;
        color.rgb += ao * rayMarchDepth(currentData.worldPos, dir) *1;
    }
    color.rgb += (1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r)) * pow(textureLod(skyboxTex, reconstructCameraSpaceDistance(UV, 1.0), 0.0).rgb, vec3(2.4));
    return clamp(color.rgbb, 0.0, 11.0);
}