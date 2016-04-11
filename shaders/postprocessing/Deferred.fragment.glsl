#version 430 core

in vec2 UV;

out vec4 outColor;

layout(binding = 0) uniform sampler2D mrt_Albedo_Roughness_Tex;
layout(binding = 1) uniform sampler2D mrt_Normal_Metalness_Tex;
layout(binding = 2) uniform sampler2D mrt_Distance_Bump_Tex;
layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 4) uniform sampler2D shadowMapSingle;

uniform mat4 VPMatrix;
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

vec3 dfNormal;

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
    vec4 albedo_roughness = textureLod(mrt_Albedo_Roughness_Tex, UV, 0).rgba;
    vec4 normal_metalness = textureLod(mrt_Normal_Metalness_Tex, UV, 0).rgba;
    float dist = textureLod(mrt_Distance_Bump_Tex, UV, 0).r;
    vec3 cameraSpace = reconstructCameraSpaceDistance(UV, dist);
    vec3 worldSpace = FromCameraSpace(cameraSpace);
    
    dfNormal = normalize(cross(dFdx(worldSpace), dFdy(worldSpace)));
    
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

#define getBump(a) (textureLod(mrt_Distance_Bump_Tex,a,0).g)
#define getDistance(a) (textureLod(mrt_Distance_Bump_Tex,a,0).r)
#define getPDist(a) (textureLod(mrt_Distance_Bump_Tex,a,0).b)
#define getPReal(a) (textureLod(mrt_Distance_Bump_Tex,a,0).a)
#define getNormal(a) (textureLod(mrt_Normal_Metalness_Tex,a,0).rgb)

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
            shadow +=  1.0 - step(comparison + 0.0005, texture(shadowMapSingle, uv).r);
        }
    }
    return shadow / (KERNEL * KERNEL);
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
    float fresnel = fresnel_again(data.normal, data.cameraPos, 0.08);
    float fresnelR = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.r);
    float fresnelG = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.g);
    float fresnelB = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.b);
    vec3 newBase = vec3(fresnelR, fresnelG, fresnelB);
    
    vec3 radiance =  shade(CameraPosition, newBase, data.normal, data.worldPos, LightPosition, LightColor, max(MIN_ROUGHNESS_DIRECT, data.roughness), false);    
    
    vec3 difradiance = shadeDiffuse(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, data.roughness, false);
    return radiance + difradiance ;
}

vec3 MakeShading(PostProceessingData data){
    return mix(shadingNonMetalic(data), shadingMetalic(data), data.metalness);
}

float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

#define MMAL_LOD_REGULATOR 512
vec3 stupidBRDF(vec3 dir, float level, float roughness){
    vec3 aaprc = vec3(0.0);
    float xx=rand2s(UV);
    float xx2=rand2s(UV.yx);
    for(int x = 0; x < 15; x++){
        vec3 rd = vec3(
            rand2s(vec2(xx, xx2)),
            rand2s(vec2(-xx2, xx)),
            rand2s(vec2(xx2, xx))
        ) *2-1;
        vec3 displace = rd;
        vec3 prc = textureLod(skyboxTex, dir + (displace * 0.5 * roughness), level).rgb;
        aaprc += prc;
        xx += 0.01;
        xx2 -= 0.02123;
    }
    return aaprc / 15;
}

vec3 MMALSkybox(vec3 dir, float roughness){
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(skyboxTex)) - 1);
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 result = stupidBRDF(dir, mx * levels, roughness);
    
    //return pow(result * 1.2, vec3(2.0));
    return result;
}


vec3 MMAL(PostProceessingData data){
    vec3 reflected = normalize(reflect(data.cameraPos, data.normal));
    vec3 dir = normalize(mix(reflected, data.normal, data.roughness));
    
    float fresnel = fresnel_again(data.normal, data.cameraPos, 0.08);
    float fresnelR = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.r);
    float fresnelG = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.g);
    float fresnelB = fresnel_again(data.normal, data.cameraPos, data.diffuseColor.b);
    vec3 newBase = vec3(fresnelR, fresnelG, fresnelB);
    
    vec3 metallic = vec3(0);
    vec3 nonmetallic = vec3(0);
    
    metallic += MMALSkybox(dir, data.roughness) * newBase;
    
    nonmetallic += MMALSkybox(dir, data.roughness) * fresnel;
    nonmetallic += MMALSkybox(dir, 1.0) * data.diffuseColor;
    
    return mix(nonmetallic, metallic, data.metalness);
    
}

vec2 project(vec3 pos){
    vec4 tmp = (VPMatrix * vec4(pos, 1.0));
    return (tmp.xy / tmp.w) * 0.5 + 0.5;
}

float hitplane(vec3 origin, vec3 direction, vec3 normal, vec3 point){
    return dot(normal, point - origin) / dot(normal, direction);
}

float softparallaxbumpshadow(PostProceessingData data){

    return textureLod(mrt_Distance_Bump_Tex,UV,0).b;
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
                percent = PCFDeferred(lightScreenSpace.xy, 1.0 - toLogDepth(distance(data.worldPos, LightPosition), LightCutOffDistance)); 
                
            }
            result += radiance * percent;
        }
        
    } else if(LightUseShadowMap == 0){
        result += radiance;
    }
    return result; // * (1.0 - smoothstep(0.0, LightCutOffDistance, distance(LightPosition, data.worldPos)));
}


void main(){
    createData();
    vec3 color = vec3(0);
    if(currentData.cameraDistance > 0){
        color += ApplyLighting(currentData);
        color += MMAL(currentData) * 0.1;
    }
    outColor = vec4(color, 1.0);
}