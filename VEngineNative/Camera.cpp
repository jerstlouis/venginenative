#include "stdafx.h"
#include "Camera.h"


Camera::Camera()
{
    initTransformation();
    brightness = 1.0;
    projectionMatrix = mat4(1);
    farplane = 1000.0;
}


Camera::~Camera()
{
}
