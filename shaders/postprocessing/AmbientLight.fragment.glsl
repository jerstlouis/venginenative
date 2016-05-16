#version 430 core

#include PostProcessEffectBase.glsl
#include Shade.glsl

layout(binding = 3) uniform samplerCube skyboxTex;

float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

#define MMAL_LOD_REGULATOR 1024
vec3 stupidBRDF(vec3 dir, float level, float roughness){
    vec3 aaprc = vec3(0.0);
    float xx=rand2s(UV);
    float xx2=rand2s(UV.yx);
    for(int x = 0; x < 14; x++){
        vec3 rd = vec3(
            rand2s(vec2(xx, xx2)),
            rand2s(vec2(-xx2, xx)),
            rand2s(vec2(xx2, xx))
        ) *2-1;
        vec3 displace = rd;
        vec3 prc = textureLod(skyboxTex, dir + (displace * 0.1 * roughness), level).rgb * 5.0;
        aaprc += prc;
        xx += 0.01;
        xx2 -= 0.02123;
    }
    return pow(aaprc / 14.0, vec3(2.4));
}

vec3 MMALSkybox(vec3 dir, float roughness){
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(skyboxTex)) - 1);
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 result = pow(textureLod(skyboxTex, dir, mx * levels).rgb, vec3(2.4)) * 5;
    
    //return pow(result * 1.2, vec3(2.0));
    return result;
}


vec3 MMAL(PostProceessingData data){
    vec3 reflected = normalize(reflect(data.cameraPos, data.normal));
    vec3 dir = normalize(mix(reflected, data.normal, data.roughness));
    
    float fresnel = fresnel_again(vec3(0.04), data.normal, data.cameraPos, data.roughness);
    float fresnelR = fresnel_again(vec3(data.diffuseColor.r), data.normal, data.cameraPos, data.roughness);
    float fresnelG = fresnel_again(vec3(data.diffuseColor.g), data.normal, data.cameraPos, data.roughness);
    float fresnelB = fresnel_again(vec3(data.diffuseColor.b), data.normal, data.cameraPos, data.roughness);
    vec3 newBase = vec3(fresnelR, fresnelG, fresnelB);
    
    vec3 metallic = vec3(0);
    vec3 nonmetallic = vec3(0);
    
    metallic += MMALSkybox(dir, data.roughness) * newBase;
    
    nonmetallic += MMALSkybox(dir, data.roughness) * fresnel;
    nonmetallic += MMALSkybox(dir, 1.0) *  data.diffuseColor * (1.0 - fresnel);
    
    return mix(nonmetallic, metallic, data.metalness);
    
}

uniform float Time;

vec4 shade(){
    vec4 color = vec4(0);
    if(currentData.cameraDistance > 0){
     //   color.rgb += MMAL(currentData) *0.03;
    }
    //color.rgb += (1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r)) * pow(textureLod(skyboxTex, reconstructCameraSpaceDistance(UV, 1.0), 0.0).rgb, vec3(2.4)) * 5.0;
    return clamp(color, 0.0, 1.0);
}