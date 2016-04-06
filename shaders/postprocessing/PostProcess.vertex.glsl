#version 430 core

layout(location = 0) in vec3 in_position;
out vec2 UV;

void main(){
    gl_Position =  vec4(in_position.xy, 0 ,1);
    UV = (in_position.xy + 1.0) / 2.0;
}