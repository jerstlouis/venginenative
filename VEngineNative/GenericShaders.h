#pragma once
#include "ShaderProgram.h"
class GenericShaders
{
public:
    GenericShaders();
    ~GenericShaders();
    ShaderProgram *materialShader;
    ShaderProgram *materialGeometryShader;
    ShaderProgram *depthOnlyGeometryShader;
    ShaderProgram *depthOnlyShader;
};
