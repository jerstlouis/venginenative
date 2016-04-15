#pragma once
#include "Light.h"
#include "Mesh3d.h"
class Scene
{
public:
    Scene();
    ~Scene();
    void draw();
    void setUniforms();
    void addMesh(Mesh3d *mesh);
    void addLight(Light *light);
    vector<Mesh3d*>& getMeshes();
    vector<Light*> getLights();
private:
    vector<Mesh3d*> meshes;
    vector<Light*> lights;
};
