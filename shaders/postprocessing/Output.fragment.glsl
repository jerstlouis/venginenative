#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D directTex;
layout(binding = 6) uniform sampler2D alTex;
layout(binding = 7) uniform sampler2D aoTex;

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

float lookupAO(vec2 fuv, float radius){
    float ratio = Resolution.y/Resolution.x;
    float outc = 0;
    float counter = 0;
    float depthCenter = currentData.cameraDistance;
    vec3 normalcenter = currentData.normal;
    for(float g = 0; g < 6.283; g+=0.9)
    {
        for(float g2 = 0; g2 < 1.0; g2+=0.33)
        {
            vec2 gauss = clamp(fuv + vec2(sin(g + g2*6)*ratio, cos(g + g2*6)) * (g2 * 0.012 * radius), 0.0, 1.0);
            float color = textureLod(aoTex, gauss, 0).r;
            float depthThere = texture(mrt_Distance_Bump_Tex, gauss).a;
            vec3 normalthere = texture(mrt_Normal_Metalness_Tex, gauss).rgb;
            float weight = pow(max(0, dot(normalthere, normalcenter)), 32);
            outc += color * weight;
            counter+=weight;
        }
    }
    return counter == 0 ? textureLod(aoTex, fuv, 0).r : outc / counter;
 }

vec4 shade(){    
    vec3 color = texture(directTex, UV).rgb + texture(alTex, UV).rgb * lookupAO(UV, 1.0);
    color += (1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r)) * pow(textureLod(skyboxTex, reconstructCameraSpaceDistance(UV, 1.0), 0.0).rgb, vec3(2.4));
    return vec4(rgb_to_srgb(color), 1.0);
}