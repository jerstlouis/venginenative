#include "stdafx.h"
#include "Material.h"

using namespace glm;

Material::Material()
{
    diffuseColor = vec3(1);
    specularColor = vec3(1);
    roughness = 1.0;
    metalness = 0.0;
    diffuseTexture = nullptr;
    metalnessTexture = nullptr;
    normalsTexture = nullptr;
    bumpTexture = nullptr;
    roughnessTexture = nullptr;
}


Material::~Material()
{
}
