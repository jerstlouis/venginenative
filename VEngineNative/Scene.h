#pragma once
#include "EnvProbe.h"
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
    void addEnvProbe(EnvProbe *env);
    vector<Mesh3d*>& getMeshes();
    vector<Light*>& getLights();
    vector<EnvProbe*>& getEnvProbes();
private:
    vector<Mesh3d*> meshes;
    vector<Light*> lights;
    vector<EnvProbe*> envProbes;
};
