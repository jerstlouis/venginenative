#version 430 core

in Data {
#include InOutStageLayout.glsl
} Input;

layout(location = 0) out vec4 outAlbedoRoughness;
layout(location = 1) out vec4 outNormalsMetalness;
layout(location = 2) out float outDistance;

#include Quaternions.glsl
#include ModelBuffer.glsl
#include Mesh3dUniforms.glsl

#include Material.glsl

void main(){
    vec3 diffuseColor = DiffuseColor;
    vec3 normal = length(Input.Normal) == 0.0 ? normalize(cross(dFdx(Input.WorldPos), dFdy(Input.WorldPos))) : normalize(Input.Normal);
    vec3 normalmap = vec3(0,0,1);
    float roughness = Roughness;
    float metalness = Metalness;
    float bump = getBump(Input.TexCoord);
    if(RunParallax) UV = adjustParallaxUV(MainCameraPosition);
    
    vec3 tangent = (Input.Tangent.w < -1.0 || Input.Tangent.w > 1.0) ? normalize(cross(normal, cross(dFdx(Input.WorldPos), dFdy(Input.WorldPos)))) : normalize(Input.Tangent.rgb);
    
    float tangentSign = Input.Tangent.w == 0 ? 1.0 : Input.Tangent.w;

    mat3 TBN = mat3(
        normalize(tangent),
        normalize(cross(normal, tangent)) * tangentSign,
        normalize(normal)
    );    
    
    for(int i=0;i<NodesCount;i++){
        NodeImageModifier node = getModifier(i);
        vec4 data = sampleNode(node.samplerIndex, UV * node.uvScale);
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
        if(node.target == MODTARGET_BUMP_AS_NORMAL){
            data.rgb = examineBumpMap(retrieveSampler(node.samplerIndex), UV * node.uvScale);
            normalmap = nodeCombine(normalmap, data.rgb, node.mode, data.a);
        }
    }
    normalmap = normalize(normalmap);
    normalmap.r = - normalmap.r;
    normalmap.g = - normalmap.g;
    normal = TBN * normalmap;

    normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normal);
    
    diffuseColor *= 1.0 - newParallaxHeight;
    
    outAlbedoRoughness = vec4(diffuseColor, roughness);
    outNormalsMetalness = vec4(normal, metalness);
    outDistance = max(0.01, distance(CameraPosition, Input.WorldPos - normal * parallaxScale * newParallaxHeight));
}
