#pragma once
#include "Texture.h";
class Material
{
public:
    Material();
    ~Material();

    glm::vec3 diffuseColor;
    glm::vec3 specularColor;
    float roughness;
    float metalness;

    Texture *diffuseTexture;
    Texture *metalnessTexture;
    Texture *normalsTexture;
    Texture *bumpTexture;
    Texture *roughnessTexture;
};

