#include "stdafx.h"
#include "Camera.h"

using namespace glm;

Camera::Camera()
{
    initTransformation();
    brightness = 1.0;
    projectionMatrix = mat4(1);
    farplane = 1000.0;
    cone = new FrustumCone();
}

Camera::~Camera()
{
}

void Camera::createProjectionPerspective(float fov, float aspectRatio, float nearpl, float farpl)
{
    farplane = farpl;
    projectionMatrix = perspective(fov, aspectRatio, nearpl, farpl);
}
