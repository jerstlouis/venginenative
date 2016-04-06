#include "stdafx.h"
#include "Game.h"
#include "Mesh3dLodLevel.h"

using namespace glm;

Mesh3dLodLevel::Mesh3dLodLevel(Object3dInfo *info, Material *imaterial, float distancestart, float distanceend)
{
    info3d = info;
    material = imaterial;
    distanceStart = distancestart;
    distanceEnd = distanceend;
    instancesFiltered = 0;
    modelInfosBuffer = new ShaderStorageBuffer();
}

Mesh3dLodLevel::Mesh3dLodLevel(Object3dInfo *info, Material *imaterial)
{
    info3d = info;
    material = imaterial;
    distanceStart = 0;
    distanceEnd = 99999.0;
    instancesFiltered = 0;
    modelInfosBuffer = new ShaderStorageBuffer();
}

Mesh3dLodLevel::Mesh3dLodLevel()
{
    info3d = nullptr;
    material = nullptr;
    distanceStart = 0;
    distanceEnd = 99999.0;
    instancesFiltered = 0;
    modelInfosBuffer = new ShaderStorageBuffer();
}


Mesh3dLodLevel::~Mesh3dLodLevel()
{
}

void Mesh3dLodLevel::draw()
{
    ShaderProgram *shader = Game::instance->shaders->materialShader;
    shader->setUniform("Roughness", material->roughness);
    shader->setUniform("Metalness", material->metalness);
    shader->setUniform("DiffuseColor", material->diffuseColor);
    shader->setUniform("SpecularColor", material->specularColor);

    shader->setUniform("NormalTexEnabled", material->normalsTexture != nullptr);
    shader->setUniform("BumpTexEnabled", material->bumpTexture != nullptr);
    shader->setUniform("RoughnessTexEnabled", material->roughnessTexture != nullptr);
    shader->setUniform("DiffuseTexEnabled", material->diffuseTexture != nullptr);
    shader->setUniform("MetalnessTexEnabled", material->metalnessTexture != nullptr);

    if (material->normalsTexture != nullptr) material->normalsTexture->use(5);
    if (material->bumpTexture != nullptr) material->bumpTexture->use(6);
    if (material->roughnessTexture != nullptr) material->roughnessTexture->use(7);
    if (material->diffuseTexture != nullptr) material->diffuseTexture->use(8);
    if (material->metalnessTexture != nullptr) material->metalnessTexture->use(9);

    modelInfosBuffer->use(0);

    info3d->drawInstanced(instancesFiltered);
}

void Mesh3dLodLevel::updateBuffer(const vector<Mesh3dInstance*> &instances)
{
    vec3 cameraPos = Game::instance->world->currentCamera->transformation->position;
    vector<Mesh3dInstance*> filtered;
    for (int i = 0; i < instances.size(); i++) {
        float dst = distance(cameraPos, instances[i]->transformation->position);
        if (dst >= distanceStart && dst < distanceEnd) {
            filtered.push_back(instances[i]);
        }
    }
    instancesFiltered = filtered.size();
    /*layout rotation f4 translation f3+1 scale f3+1 =>> 12 floats*/
    vector<float> floats;
    floats.reserve(12 * instancesFiltered);
    for (int i = 0; i < instancesFiltered; i++) {
        TransformationManager *mgr = filtered[i]->transformation;
        floats.push_back(mgr->orientation.x);
        floats.push_back(mgr->orientation.y);
        floats.push_back(mgr->orientation.z);
        floats.push_back(mgr->orientation.w);

        floats.push_back(mgr->position.x);
        floats.push_back(mgr->position.y);
        floats.push_back(mgr->position.z);
        floats.push_back(1);

        floats.push_back(mgr->size.x);
        floats.push_back(mgr->size.y);
        floats.push_back(mgr->size.z);
        floats.push_back(1);
    }
    modelInfosBuffer->mapData(4 * floats.size(), floats.data());

}
