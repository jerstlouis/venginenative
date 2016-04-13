#pragma once
#include "Texture.h";
#include "MaterialNode.h";
class Material
{
public:
    Material();
    ~Material();

    glm::vec3 diffuseColor;
    float roughness;
    float metalness;

    vector<MaterialNode*> nodes;

    void addNode(MaterialNode *node);
};
