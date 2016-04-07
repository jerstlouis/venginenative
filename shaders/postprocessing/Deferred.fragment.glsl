#version 430 core

in vec2 UV;

out vec4 outColor;

layout(binding = 0) uniform sampler2D mrt_Albedo_Roughness_Tex;
layout(binding = 1) uniform sampler2D mrt_Normal_Metalness_Tex;
layout(binding = 2) uniform sampler2D mrt_Distance_Tex;
layout(binding = 4) uniform sampler2DShadow shadowMapSingle;

uniform vec3 CameraPosition;
uniform vec2 Resolution;
uniform vec3 FrustumConeLeftBottom;
uniform vec3 FrustumConeBottomLeftToBottomRight;
uniform vec3 FrustumConeBottomLeftToTopLeft;

uniform vec3 LightColor;
uniform vec3 LightPosition;
uniform vec4 LightOrientation;
uniform float LightAngle;
uniform int LightUseShadowMap;
uniform mat4 LightVPMatrix;
uniform float LightCutOffDistance;

#include Shade.glsl

struct PostProceessingData
{
    vec3 diffuseColor;
    vec3 normal;
    vec3 worldPos;
    vec3 cameraPos;
    float cameraDistance;
    float roughness;
    float metalness;
};

PostProceessingData currentData;

vec3 reconstructCameraSpaceDistance(vec2 uv, float dist){
    vec3 dir = normalize((FrustumConeLeftBottom + FrustumConeBottomLeftToBottomRight * uv.x + FrustumConeBottomLeftToTopLeft * uv.y));
    return dir * dist;
}

vec3 ToCameraSpace(vec3 position){
    return position + CameraPosition;
}

vec3 FromCameraSpace(vec3 position){
    return position - -CameraPosition;
}

void createData(){
    vec4 albedo_roughness = texture(mrt_Albedo_Roughness_Tex, UV).rgba;
    vec4 normal_metalness = texture(mrt_Normal_Metalness_Tex, UV).rgba;
    float dist = texture(mrt_Distance_Tex, UV).r;
    vec3 cameraSpace = reconstructCameraSpaceDistance(UV, dist);
    vec3 worldSpace = FromCameraSpace(cameraSpace);
    currentData = PostProceessingData(
    albedo_roughness.rgb,
    normal_metalness.rgb,
    worldSpace,
    cameraSpace,
    dist,
    albedo_roughness.a,
    normal_metalness.a
    );
}

#define KERNEL 6
#define PCFEDGE 1
float PCFDeferred(vec2 uvi, float comparison){

    float shadow = 0.0;
    float pixSize = 1.0 / textureSize(shadowMapSingle,0).x;
    float bound = KERNEL * 0.5 - 0.5;
    bound *= PCFEDGE;
    for (float y = -bound; y <= bound; y += PCFEDGE){
        for (float x = -bound; x <= bound; x += PCFEDGE){
            vec2 uv = vec2(uvi+ vec2(x,y)* pixSize);
            shadow += texture(shadowMapSingle, vec3(uv, comparison));
        }
    }
    return shadow / (KERNEL * KERNEL);
}

float toLogDepth(float depth, float far){
    float badass_depth = log2(max(1e-6, 1.0 + depth)) / (log2(far));
    return badass_depth;
}

vec3 shadingMetalic(PostProceessingData data){
    float fresnel = fresnel_again(data.normal, data.cameraPos, 1.0 - data.roughness);
    
    return shade(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, 1.0 - fresnel, false);
}

vec3 shadingNonMetalic(PostProceessingData data){
    float fresnel = fresnel_again(data.normal, data.cameraPos, 1.0 - data.roughness);
    
    vec3 radiance =  shade(CameraPosition, vec3(0.08), data.normal, data.worldPos, LightPosition, LightColor, 1.0 - fresnel, false);    
    
    vec3 difradiance = shadeDiffuse(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, 1.0 - fresnel, false);
    return difradiance + radiance;
}

vec3 MakeShading(PostProceessingData data){
    return mix(shadingNonMetalic(data), shadingMetalic(data), data.metalness);
}

vec3 ApplyLighting(PostProceessingData data)
{
    vec3 result = vec3(0);
    vec3 radiance = MakeShading(data);
    
    if(LightUseShadowMap == 1){
        vec4 lightClipSpace = LightVPMatrix * vec4(data.worldPos, 1.0);
        if(lightClipSpace.z > 0.0){
            vec3 lightScreenSpace = (lightClipSpace.xyz / lightClipSpace.w) * 0.5 + 0.5;   

            float percent = 0;
            if(lightScreenSpace.x >= 0.0 && lightScreenSpace.x <= 1.0 && lightScreenSpace.y >= 0.0 && lightScreenSpace.y <= 1.0) {
                percent = PCFDeferred(lightScreenSpace.xy, toLogDepth(distance(data.worldPos, LightPosition), 10000) - 0.001);
            }
            result += radiance * percent;
        }
        
    } else if(LightUseShadowMap == 0){
        result += radiance;
    }
    return result * (1.0 - smoothstep(0.0, LightCutOffDistance, distance(LightPosition, data.worldPos)));
}


void main(){
    createData();
    vec3 color = ApplyLighting(currentData);
    outColor = vec4(color, 1.0);
}