#pragma once
#include "AbsTransformable.h"
#include "FrustumCone.h"
class Camera : AbsTransformable
{
public:
    Camera();
    ~Camera();

    static Camera *current;
    float brightness;
    float farplane;
    FrustumCone *cone;
    glm::mat4 projectionMatrix;

    void createProjectionPerspective(float fov, float aspectRatio, float nearpl, float farpl);

};

