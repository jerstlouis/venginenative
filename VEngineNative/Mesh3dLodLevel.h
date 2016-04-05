#pragma once
#include "ShaderStorageBuffer.h"
#include "Material.h"
#include "Object3dInfo.h"
#include "Mesh3dInstance.h"
class Mesh3dLodLevel
{
public:
    Mesh3dLodLevel(Object3dInfo *info, Material *imaterial, float distancestart, float distanceend);
    Mesh3dLodLevel(Object3dInfo *info, Material *imaterial);
    Mesh3dLodLevel();
    ~Mesh3dLodLevel();
    Material *material;
    Object3dInfo *info3d;
    float distanceStart;
    float distanceEnd;
    void draw();
    void updateBuffer(const vector<Mesh3dInstance*> &instances);
private:
    ShaderStorageBuffer *modelInfosBuffer;
    unsigned int instancesFiltered;
};

