#include "stdafx.h"
#include "Scene.h"


Scene::Scene()
{
    meshes = {};
}


Scene::~Scene()
{
}

void Scene::draw()
{
    for (int i = 0; i < meshes.size(); i++) {
        meshes[i]->draw();
    }
}

void Scene::addMesh(Mesh3d * mesh)
{
    meshes.push_back(mesh);
}

void Scene::addLight(Light * light)
{
    lights.push_back(light);
}

vector<Mesh3d*>& Scene::getMeshes()
{
    return meshes;
}

vector<Light*>& Scene::getLights()
{
    return lights;
}
