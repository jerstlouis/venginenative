#version 450 core
layout( local_size_x = 32, local_size_y = 32, local_size_z = 1 ) in;

layout (binding = 0, r16f)  uniform writeonly image3D perlinImg;

uniform float Time;
#define Scale (1.0)

#include noise4D.glsl

void main(){
    uvec3 pos = gl_GlobalInvocationID;
    vec3 posf = vec3(pos) / 64.0;
    float n1 = snoise(vec4(posf * Scale, Time)) * 0.5 + 0.5;
    float n2 = snoise(vec4((1.0 - posf) * Scale, Time)) * 0.5 + 0.5;
    imageStore(perlinImg, ivec3(pos), vec4(n1 * n2));
}