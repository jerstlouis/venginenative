#include "stdafx.h"
#include "GenericShaders.h"

GenericShaders::GenericShaders()
{
    materialShader = new ShaderProgram("Generic.vertex.glsl", "Material.fragment.glsl");
    materialGeometryShader = new ShaderProgram("Generic.vertex.glsl", "Material.fragment.glsl", "Parallax.geometry.glsl");
    depthOnlyShader = new ShaderProgram("Generic.vertex.glsl", "DepthOnly.fragment.glsl");
    depthOnlyGeometryShader = new ShaderProgram("Generic.vertex.glsl", "DepthOnly.fragment.glsl", "Parallax.geometry.glsl");
}

GenericShaders::~GenericShaders()
{
    delete materialShader;
    delete materialGeometryShader;
    delete depthOnlyGeometryShader;
    delete depthOnlyShader;
}