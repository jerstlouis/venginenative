#version 430 core

#define INSTANCES 4

layout(invocations = INSTANCES) in;

layout(triangles) in;
layout(triangle_strip, max_vertices = 32) out;

#include Mesh3dUniforms.glsl

in Data {
#include InOutStageLayout.glsl
} gs_in[];

out Data {
#include InOutStageLayout.glsl
} Output;

#define ParallaxHeightMultiplier 0.03

void GeometryProcessParallaxDraw(){
    float inter = float(gl_InvocationID) / float(INSTANCES);
    
    float precises = mix(6.0, 2.0, max(0, dot(normalize(CameraPosition - gs_in[0].WorldPos), normalize(gs_in[0].Normal))));
    int steps = int(floor(precises));
    float icount = INSTANCES * steps;
    float stepsize = 1.0 / float(INSTANCES);
    float midstep = stepsize / floor(precises);
    for(int a=0;a<steps;a++){
       // inter += stepsize;
        
        for(int l=0;l<3;l++){
            Output.instanceId = gs_in[l].instanceId;
            float maxwpos = 0.11 * ParallaxHeightMultiplier;
            Output.WorldPos = gs_in[l].WorldPos - gs_in[l].Normal * (inter) * 0.11 * ParallaxHeightMultiplier;
            Output.TexCoord =  gs_in[l].TexCoord;
            Output.Normal =  gs_in[l].Normal;
            Output.Tangent =  gs_in[l].Tangent;
            Output.Data = vec2(clamp(inter, 0.0, 1.0), maxwpos);
            gl_Position = VPMatrix * vec4(Output.WorldPos, 1);
            EmitVertex();
            inter += midstep;
        }
        EndPrimitive();
    }
}

void main()
{
    GeometryProcessParallaxDraw();
}
