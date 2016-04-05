#pragma once
#include "Camera.h"
#include "Scene.h"
class World
{
public:
    World();
    ~World();
    Camera *mainDisplayCamera;
    Camera *currentCamera;
    Scene *scene;
    void draw();
};

