#pragma once
#include "Mesh3d.h"
class Scene
{
public:
    Scene();
    ~Scene();
    void draw();
    void addMesh(Mesh3d *mesh);
private:
    vector<Mesh3d*> meshes;
};

