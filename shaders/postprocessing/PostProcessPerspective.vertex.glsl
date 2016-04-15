#version 430 core

layout(location = 0) in vec3 in_position;
uniform mat4 VPMatrix;
uniform mat4 LightMMatrix;

void main(){
    gl_Position =  VPMatrix * (LightMMatrix * vec4(in_position.xyz,1));
}