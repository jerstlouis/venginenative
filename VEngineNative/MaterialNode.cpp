#include "stdafx.h"
#include "MaterialNode.h"


MaterialNode::MaterialNode(Texture * tex, glm::vec2 uvScaling, int mixMode, int nodeTarget)
{
    texture = tex;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode()
{
    texture = nullptr;
    uvScale = glm::vec2(1);
    mixingMode = 0;
    target = 0;
}


MaterialNode::~MaterialNode()
{
    delete texture;
}
