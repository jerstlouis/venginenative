#version 430 core

in vec2 UV;

out vec4 outColor;

uniform vec3 CameraPosition;
uniform vec3 FrustumConeLeftBottom;
uniform vec3 FrustumConeBottomLeftToBottomRight;
uniform vec3 FrustumConeBottomLeftToTopLeft;
    
vec3 reconstructCameraSpaceDistance(vec2 uv, float dist){
    vec3 dir = normalize((FrustumConeLeftBottom + FrustumConeBottomLeftToBottomRight * uv.x + FrustumConeBottomLeftToTopLeft * uv.y));
    return dir * dist;
}

layout(binding = 2) uniform sampler2D mrt_Distance_Tex;
layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D inTex;

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
    vec3 color = texture(inTex, UV).rgb;
    color += (1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Tex, UV, 0).r)) * textureLod(skyboxTex, reconstructCameraSpaceDistance(UV, 1.0), 0.0).rgb;
    outColor = vec4(rgb_to_srgb(color), 1.0);
}