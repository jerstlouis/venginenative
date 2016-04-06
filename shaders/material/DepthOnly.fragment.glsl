#version 430 core

in Data {
#include InOutStageLayout.glsl
} Input;

#include Mesh3dUniforms.glsl

float toLogDepth(float depth, float far){
    float badass_depth = log2(max(1e-6, 1.0 + depth)) / (log2(far));
    return badass_depth;
}

void main(){
    float dist = distance(CameraPosition, Input.WorldPos);
    gl_FragDepth = toLogDepth(dist, 10000);
}