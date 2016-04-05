#version 430 core

in Data {
#include InOutStageLayout.glsl
} Input;

out vec4 outColor;

#include Mesh3dUniforms.glsl
#include Quaternions.glsl
#include ModelBuffer.glsl

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
    vec3 color = DiffuseColor;
    if(UseDiffuseTex) color = texture(diffuseTex, Input.TexCoord).rgb;
    color *= max(0.05, dot(normalize(Input.Normal), vec3(0,1,0)));
    outColor = vec4(rgb_to_srgb(color), 1.0);
}