#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 14) uniform sampler2DShadow shadowMapSingle;
layout(binding = 15) uniform samplerCubeShadow shadowMapCube;

#define LIGHT_SPOT 0
#define LIGHT_POINT 1

uniform vec3 LightColor;
uniform vec3 LightPosition;
uniform vec4 LightOrientation;
uniform float LightAngle;
uniform int LightType;
uniform int LightUseShadowMap;
uniform mat4 LightVPMatrix;
uniform float LightCutOffDistance;

#include Shade.glsl
#include Quaternions.glsl

#define KERNEL 6
#define PCFEDGE 1
float PCFDeferred(vec2 uvi, float comparison){

    float shadow = 0.0;
    float pixSize = 1.0 / textureSize(shadowMapSingle,0).x;
    float bound = KERNEL * 0.5 - 0.5;
    bound *= PCFEDGE;
    for (float y = -bound; y <= bound; y += PCFEDGE){
        for (float x = -bound; x <= bound; x += PCFEDGE){
            vec3 uv = vec3(uvi+ vec2(x,y)* pixSize, comparison + 0.001);
            shadow += texture(shadowMapSingle, uv);
        }
    }
    return 1.0 - shadow / (KERNEL * KERNEL);
}

float toLogDepth(float depth, float far){
    float badass_depth = log2(max(1e-6, 1.0 + depth)) / (log2(far));
    return badass_depth;
}

#define MIN_ROUGHNESS_DIRECT 0.04

vec3 shadingMetalic(PostProceessingData data){
    float fresnelR = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.r);
    float fresnelG = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.g);
    float fresnelB = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.b);
    vec3 newBase = vec3(fresnelR, fresnelG, fresnelB);
    return shade(CameraPosition, newBase, data.normal, data.worldPos, LightPosition, LightColor,  max(MIN_ROUGHNESS_DIRECT, data.roughness), false);
}

vec3 shadingNonMetalic(PostProceessingData data){
    float fresnel = fresnel_again(data.normal, data.cameraPos, 0.08) * (1.0 - data.roughness * 0.9);
    
    vec3 radiance = shade(CameraPosition, vec3(fresnel), data.normal, data.worldPos, LightPosition, LightColor, max(MIN_ROUGHNESS_DIRECT, data.roughness), false);    
    
    vec3 difradiance = shadeDiffuse(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, data.roughness, false);
    return radiance + difradiance ;
}

vec3 MakeShading(PostProceessingData data){
    return mix(shadingNonMetalic(data), shadingMetalic(data), data.metalness);
}

vec3 ApplyLighting(PostProceessingData data)
{
    vec3 result = vec3(0);
    vec3 radiance = MakeShading(data);
    
    if(LightUseShadowMap == 1){
        if(LightType == LIGHT_SPOT){
            vec4 lightClipSpace = LightVPMatrix * vec4(data.worldPos, 1.0);
            if(lightClipSpace.z > 0.0){
                vec3 lightScreenSpace = (lightClipSpace.xyz / lightClipSpace.w) * 0.5 + 0.5;   

                float percent = 0;
                if(lightScreenSpace.x >= 0.0 && lightScreenSpace.x <= 1.0 && lightScreenSpace.y >= 0.0 && lightScreenSpace.y <= 1.0) {
                    percent = PCFDeferred(lightScreenSpace.xy, 1.0 - toLogDepth(distance(data.worldPos, LightPosition), LightCutOffDistance));
                }
                result += radiance * (percent);
            }
        } else if(LightType == LIGHT_POINT){
            float target = 1.0 - toLogDepth(distance(data.worldPos, LightPosition), LightCutOffDistance);
            float percent = texture(shadowMapCube, vec4(normalize(data.worldPos - LightPosition), target));
            result += radiance * percent;
        }
        
    } else if(LightUseShadowMap == 0){
        

        result += radiance;
    }
    if(LightType == LIGHT_SPOT) {
        float percent = 1.0;
        vec3 ldir = -quat_mul_vec(LightOrientation, vec3(0,0,-1));
        float dt = -dot(normalize(data.worldPos - LightPosition), ldir);
        float angle =  (cos(LightAngle / 1.41) * 0.5 + 0.5);
        percent = smoothstep(angle, angle + (angle * 0.006), dt);
        result *= percent;
    }    
    return result; // * (1.0 - smoothstep(0.0, LightCutOffDistance, distance(LightPosition, data.worldPos)));
}


vec4 shade(){
    vec4 c = vec4(0);
    if(currentData.cameraDistance > 0){
        c.rgb += ApplyLighting(currentData);
    }
    return c;
}