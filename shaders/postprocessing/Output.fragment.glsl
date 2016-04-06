#version 430 core

in vec2 UV;

out vec4 outColor;

layout(binding = 0) uniform sampler2D mrt_Albedo_Roughness_Tex;
layout(binding = 1) uniform sampler2D mrt_Normal_Metalness_Tex;
layout(binding = 2) uniform sampler2D mrt_Distance_Tex;

uniform vec3 CameraPosition;
uniform vec2 Resolution;
uniform vec3 FrustumConeLeftBottom;
uniform vec3 FrustumConeBottomLeftToBottomRight;
uniform vec3 FrustumConeBottomLeftToTopLeft;

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
    return position + -CameraPosition;
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
 
void main(){
    createData();
    vec3 color = currentData.worldPos;
    outColor = vec4(rgb_to_srgb(color), 1.0);
}