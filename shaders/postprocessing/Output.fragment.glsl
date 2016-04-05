#version 430 core

in vec2 UV;

out vec4 outColor;

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

layout(binding = 0) uniform sampler2D inputTex;

void main(){
    vec3 color = texture(inputTex, UV).rgb;
    outColor = vec4(rgb_to_srgb(color), 1.0);
}