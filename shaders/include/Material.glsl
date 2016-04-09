
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

vec4 sampleNodeLod0(int i, vec2 uv){
    if(i == 0)  return textureLod(texBind0 , uv, 0).rgba;
    if(i == 1)  return textureLod(texBind1 , uv, 0).rgba;
    if(i == 2)  return textureLod(texBind2 , uv, 0).rgba;
    if(i == 3)  return textureLod(texBind3 , uv, 0).rgba;
    if(i == 4)  return textureLod(texBind4 , uv, 0).rgba;
    if(i == 5)  return textureLod(texBind5 , uv, 0).rgba;
    if(i == 6)  return textureLod(texBind6 , uv, 0).rgba;
    if(i == 7)  return textureLod(texBind7 , uv, 0).rgba;
    if(i == 8)  return textureLod(texBind8 , uv, 0).rgba;
    if(i == 9)  return textureLod(texBind9 , uv, 0).rgba;
    if(i == 10) return textureLod(texBind10, uv, 0).rgba;
    if(i == 11) return textureLod(texBind11, uv, 0).rgba;
    if(i == 12) return textureLod(texBind12, uv, 0).rgba;
    if(i == 13) return textureLod(texBind13, uv, 0).rgba;
    if(i == 14) return textureLod(texBind14, uv, 0).rgba;
    if(i == 15) return textureLod(texBind15, uv, 0).rgba;
    if(i == 16) return textureLod(texBind16, uv, 0).rgba;
    if(i == 17) return textureLod(texBind17, uv, 0).rgba;
    if(i == 18) return textureLod(texBind18, uv, 0).rgba;
    if(i == 19) return textureLod(texBind19, uv, 0).rgba;
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
    if(mode == MODMODE_REPLACE) return v2;
    if(mode == MODMODE_ADD) return v1 + v2;
    if(mode == MODMODE_MUL) return v1 * v2;
    if(mode == MODMODE_AVERAGE) return mix(v1, v2, 0.5);
    if(mode == MODMODE_SUB) return v1 - v2;
    if(mode == MODMODE_ALPHAMIX) return mix(v1, v2, dataAlpha);
    return mix(v1, v2, 0.5);
}

vec3 nodeCombine(vec3 v1, vec3 v2, int mode, float dataAlpha){
    if(mode == MODMODE_REPLACE) return v2;
    if(mode == MODMODE_ADD) return v1 + v2;
    if(mode == MODMODE_MUL) return v1 * v2;
    if(mode == MODMODE_AVERAGE) return mix(v1, v2, 0.5);
    if(mode == MODMODE_SUB) return v1 - v2;
    if(mode == MODMODE_ALPHAMIX) return mix(v1, v2, dataAlpha);
    return mix(v1, v2, 0.5);
}

vec2 UV = Input.TexCoord;
bool RunParallax = false;


float getBump(vec2 uv){
    float bump = 0;
    for(int i=0;i<NodesCount;i++){
        NodeImageModifier node = getModifier(i);
        if(node.target == MODTARGET_BUMP){
            vec4 data = sampleNodeLod0(node.samplerIndex, uv * node.uvScale);
            bump = nodeCombine(bump, data.r, node.mode, data.a);
            RunParallax = true;
        }
    }
    return bump;
}

#include ParallaxOcclusion.glsl
