#version 430 core

in Data {
#include InOutStageLayout.glsl
} Input;

#include Quaternions.glsl
#include ModelBuffer.glsl
#include Mesh3dUniforms.glsl
#line 10
layout(location = 0) out vec4 outAlbedoRoughness;
layout(location = 1) out vec4 outNormalsMetalness;
layout(location = 2) out float outDistance;

uniform vec3 SpecularColor;
uniform vec3 DiffuseColor;
uniform float Roughness;
uniform float Metalness;

uniform int NormalTexEnabled;
uniform int BumpTexEnabled;
uniform int RoughnessTexEnabled;
uniform int DiffuseTexEnabled;
uniform int MetalnessTexEnabled;

#define UseNormalsTex (NormalTexEnabled > 0)
#define UseBumpTex (BumpTexEnabled > 0)
#define UseRoughnessTex (RoughnessTexEnabled > 0)
#define UseDiffuseTex (DiffuseTexEnabled > 0)
#define UseMetalnessTex (MetalnessTexEnabled > 0)

layout(binding = 5) uniform sampler2D normalsTex;
layout(binding = 6) uniform sampler2D bumpTex;
layout(binding = 7) uniform sampler2D roughnessTex;
layout(binding = 8) uniform sampler2D diffuseTex;
layout(binding = 9) uniform sampler2D metalnessTex;


const float SRGB_ALPHA = 0.055;
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
        return 12.92 * channel;
    else
        return (1.0 + SRGB_ALPHA) * pow(channel, 1.0/2.4) - SRGB_ALPHA;
}
vec3 rgb_to_srgb(vec3 rgb) {
    return vec3(
        linear_to_srgb(rgb.r),
        linear_to_srgb(rgb.g),
        linear_to_srgb(rgb.b)
    );
}

void main(){
    vec3 diffuseColor = DiffuseColor;
    if(UseDiffuseTex) diffuseColor = texture(diffuseTex, Input.TexCoord).rgb;
    
    vec3 normal = normalize(Input.Normal);
    vec3 tangent = normalize(Input.Tangent.rgb);
    float tangentSign = Input.Tangent.w;
    
    if(UseNormalsTex) {
    	mat3 TBN = mat3(
            normalize(tangent),
            normalize(cross(normal, tangent)) * tangentSign,
            normalize(normal)
        );  		
        vec3 map = texture(normalsTex, Input.TexCoord).rgb;
		map = map * 2 - 1;
		map.r = - map.r;
		map.g = - map.g;
        normal = TBN * map;
    }
    normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normal);
    
    float roughness = Roughness;
    if(UseRoughnessTex) roughness = texture(roughnessTex, Input.TexCoord).r;
    
    float metalness = Metalness;
    if(UseMetalnessTex) metalness = texture(metalnessTex, Input.TexCoord).r;
    
    outAlbedoRoughness = vec4(diffuseColor, roughness);
    outNormalsMetalness = vec4(normal, metalness);
    outDistance = distance(CameraPosition, Input.WorldPos);
}