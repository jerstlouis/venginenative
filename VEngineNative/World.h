#pragma once
#include "Camera.h"
#include "Scene.h"
#include "ShaderProgram.h"
class World
{
public:
    World();
    ~World();
    Camera *mainDisplayCamera;
    Scene *scene;
    void draw(ShaderProgram *shader, Camera *camera);
    void setUniforms(ShaderProgram *shader, Camera *camera);
};

