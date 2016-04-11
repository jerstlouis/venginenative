#pragma once
#include "Mesh3d.h"
#include "Material.h"
#include "MaterialNode.h"
#include "Object3dInfo.h"
class AssetLoader
{
public:
    AssetLoader();
    ~AssetLoader();

    Material *LoadMaterialString(string source);
    Material *LoadMaterialFile(string source);

    Mesh3d *LoadMeshString(string source);
    Mesh3d *LoadMeshFile(string source);

private:
    void splitByLines(vector<string>& output, string src);
    void splitBySpaces(vector<string>& output, string src);
    int replaceEnum(string enumstr);
};

