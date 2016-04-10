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

#define bitcheck(input,bit) ((input & bit) != 0)

vec3 saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

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
        vec4 data = node.soureColor;
        if(node.source == MODSOURCE_TEXTURE) data = sampleNode(node.samplerIndex, UV * node.uvScale);
        
        if(bitcheck(node.modifier, MODMODIFIER_NEGATIVE))data = 1.0-data;
        if(bitcheck(node.modifier, MODMODIFIER_LINEARIZE))data = pow(data, vec4(2.2));
        if(bitcheck(node.modifier, MODMODIFIER_SATURATE))data.rgb = saturation(data.rgb, node.data.r);
        if(bitcheck(node.modifier, MODMODIFIER_HUE)){
            vec3 hsv = rgb2hsv(data.rgb);
            hsv.x = fract(hsv.x + node.data.r);
            data.rgb = hsv2rgb(hsv);
        }
        if(bitcheck(node.modifier, MODMODIFIER_BRIGHTNESS)){
            vec3 hsv = rgb2hsv(data.rgb);
            hsv.z = node.data.r;
            data.rgb = hsv2rgb(hsv);
        }
        if(bitcheck(node.modifier, MODMODIFIER_HSV)){
            vec3 hsv = rgb2hsv(data.rgb);
            hsv.x = fract(hsv.x + node.data.r);
            hsv.y *= node.data.g;
            hsv.z *= node.data.b;
        }
        if(bitcheck(node.modifier, MODMODIFIER_POWER))data = pow(data, node.data);
        
        if(node.target == MODTARGET_DIFFUSE){
            diffuseColor = nodeCombine(diffuseColor, data.rgb, node.mode, data.a);
        }
        if(node.target == MODTARGET_NORMAL){
            normalmap = nodeCombine(normalmap, node.source == MODSOURCE_TEXTURE ? data.rgb * 2 - 1 : data.rgb, node.mode, data.a);
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
