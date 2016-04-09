#pragma once
#include "Texture.h";

#define NODE_MODE_ADD 0
#define NODE_MODE_MUL 1
#define NODE_MODE_AVERAGE 2
#define NODE_MODE_SUB 3
#define NODE_MODE_ALPHAMIX 4
#define NODE_MODE_REPLACE 5

#define NODE_TARGET_DIFFUSE 0
#define NODE_TARGET_NORMAL 1
#define NODE_TARGET_ROUGHNESS 2
#define NODE_TARGET_METALNESS 3
#define NODE_TARGET_BUMP 4
#define NODE_TARGET_BUMP_AS_NORMAL 5

class MaterialNode
{
public:
    MaterialNode(Texture *tex, glm::vec2 uvScaling, int mixMode, int nodeTarget);
    MaterialNode();
    ~MaterialNode();
    Texture *texture;
    glm::vec2 uvScale;
    int mixingMode;
    int target;
};

