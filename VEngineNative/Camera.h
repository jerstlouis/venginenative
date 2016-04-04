#pragma once
#include "AbsTransformable.h"
#include "FrustumCone.h"
using namespace glm;
class Camera : AbsTransformable
{
public:
    Camera();
    ~Camera();

    static Camera *current;
    float brightness;
    float farplane;
    FrustumCone *cone;
    mat4 projectionMatrix;

};

