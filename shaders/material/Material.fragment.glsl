#version 430 core

in Data {
#include InOutStageLayout.glsl
} Input;

#include Quaternions.glsl
#include ModelBuffer.glsl
#include Mesh3dUniforms.glsl

layout(location = 0) out vec4 outAlbedoRoughness;
layout(location = 1) out vec4 outNormalsMetalness;
layout(location = 2) out float outDistance;

layout(binding = 0)  uniform sampler2D texBind0 ;
layout(binding = 1)  uniform sampler2D texBind1 ;
layout(binding = 2)  uniform sampler2D texBind2 ;
layout(binding = 3)  uniform sampler2D texBind3 ;
layout(binding = 4)  uniform sampler2D texBind4 ;
layout(binding = 5)  uniform sampler2D texBind5 ;
layout(binding = 6)  uniform sampler2D texBind6 ;
layout(binding = 7)  uniform sampler2D texBind7 ;
layout(binding = 8)  uniform sampler2D texBind8 ;
layout(binding = 9)  uniform sampler2D texBind9 ;
layout(binding = 10) uniform sampler2D texBind10;
layout(binding = 11) uniform sampler2D texBind11;
layout(binding = 12) uniform sampler2D texBind12;
layout(binding = 13) uniform sampler2D texBind13;
layout(binding = 14) uniform sampler2D texBind14;
layout(binding = 15) uniform sampler2D texBind15;
layout(binding = 16) uniform sampler2D texBind16;
layout(binding = 17) uniform sampler2D texBind17;
layout(binding = 18) uniform sampler2D texBind18;
layout(binding = 19) uniform sampler2D texBind19;

vec4 sampleNode(int i, vec2 uv){
    if(i == 0)  return texture(texBind0 , uv).rgba;
    if(i == 1)  return texture(texBind1 , uv).rgba;
    if(i == 2)  return texture(texBind2 , uv).rgba;
    if(i == 3)  return texture(texBind3 , uv).rgba;
    if(i == 4)  return texture(texBind4 , uv).rgba;
    if(i == 5)  return texture(texBind5 , uv).rgba;
    if(i == 6)  return texture(texBind6 , uv).rgba;
    if(i == 7)  return texture(texBind7 , uv).rgba;
    if(i == 8)  return texture(texBind8 , uv).rgba;
    if(i == 9)  return texture(texBind9 , uv).rgba;
    if(i == 10) return texture(texBind10, uv).rgba;
    if(i == 11) return texture(texBind11, uv).rgba;
    if(i == 12) return texture(texBind12, uv).rgba;
    if(i == 13) return texture(texBind13, uv).rgba;
    if(i == 14) return texture(texBind14, uv).rgba;
    if(i == 15) return texture(texBind15, uv).rgba;
    if(i == 16) return texture(texBind16, uv).rgba;
    if(i == 17) return texture(texBind17, uv).rgba;
    if(i == 18) return texture(texBind18, uv).rgba;
    if(i == 19) return texture(texBind19, uv).rgba;
}

uniform vec3 DiffuseColor;
uniform float Roughness;
uniform float Metalness;

#define MODMODE_ADD 0
#define MODMODE_MUL 1
#define MODMODE_AVERAGE 2
#define MODMODE_SUB 3
#define MODMODE_ALPHAMIX 4
#define MODMODE_REPLACE 5

#define MODTARGET_DIFFUSE 0
#define MODTARGET_NORMAL 1
#define MODTARGET_ROUGHNESS 2
#define MODTARGET_METALNESS 3
#define MODTARGET_BUMP 4

struct NodeImageModifier{
    int samplerIndex;
    int mode;
    int target;
    vec2 uvScale;
};
#define MAX_NODES 20
uniform int NodesCount;
uniform int SamplerIndexArray[MAX_NODES];
uniform int ModeArray[MAX_NODES];
uniform int TargetArray[MAX_NODES];
uniform vec2 UVScaleArray[MAX_NODES];

NodeImageModifier getModifier(int i){
    return NodeImageModifier(
        SamplerIndexArray[i],
        ModeArray[i],
        TargetArray[i],
        UVScaleArray[i]
    );
}

float nodeCombine(float v1, float v2, int mode, float dataAlpha){
    if(mode == MODMODE_REPLACE) v2;
    if(mode == MODMODE_ADD) return v1 + v2;
    if(mode == MODMODE_MUL) return v1 * v2;
    if(mode == MODMODE_AVERAGE) return mix(v1, v2, 0.5);
    if(mode == MODMODE_SUB) return v1 - v2;
    if(mode == MODMODE_ALPHAMIX) return mix(v1, v2, dataAlpha);
    return mix(v1, v2, 0.5);
}

vec3 nodeCombine(vec3 v1, vec3 v2, int mode, float dataAlpha){
    if(mode == MODMODE_REPLACE) v2;
    if(mode == MODMODE_ADD) return v1 + v2;
    if(mode == MODMODE_MUL) return v1 * v2;
    if(mode == MODMODE_AVERAGE) return mix(v1, v2, 0.5);
    if(mode == MODMODE_SUB) return v1 - v2;
    if(mode == MODMODE_ALPHAMIX) return mix(v1, v2, dataAlpha);
    return mix(v1, v2, 0.5);
}

void main(){
    vec3 diffuseColor = DiffuseColor;
    vec3 normal = normalize(Input.Normal);
    vec3 normalmap = vec3(0,0,1);
    float roughness = Roughness;
    float metalness = Metalness;
    float bump = 0;
    
    vec3 tangent = normalize(Input.Tangent.rgb);
    float tangentSign = Input.Tangent.w;

    mat3 TBN = mat3(
        normalize(tangent),
        normalize(cross(normal, tangent)) * tangentSign,
        normalize(normal)
    );    
    
    for(int i=0;i<NodesCount;i++){
        NodeImageModifier node = getModifier(i);
        vec4 data = sampleNode(node.samplerIndex, Input.TexCoord * node.uvScale);
        if(node.target == MODTARGET_DIFFUSE){
            diffuseColor = nodeCombine(diffuseColor, data.rgb, node.mode, data.a);
        }
        if(node.target == MODTARGET_NORMAL){
            normalmap = nodeCombine(normalmap, data.rgb * 2 - 1, node.mode, data.a);
        }
        if(node.target == MODTARGET_ROUGHNESS){
            roughness = nodeCombine(roughness, data.r, node.mode, data.a);
        }
        if(node.target == MODTARGET_METALNESS){
            metalness = nodeCombine(metalness, data.r, node.mode, data.a);
        }
        if(node.target == MODTARGET_BUMP){
            bump = nodeCombine(bump, data.r, node.mode, data.a);
        }
    }
    normalmap = normalize(normalmap);
    normalmap.r = - normalmap.r;
    normalmap.g = - normalmap.g;
    normal = TBN * normalmap;

    normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normal);

    outAlbedoRoughness = vec4(diffuseColor, roughness);
    outNormalsMetalness = vec4(normal, metalness);
    outDistance = distance(CameraPosition, Input.WorldPos);
}