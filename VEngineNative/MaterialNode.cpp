#include "stdafx.h"
#include "MaterialNode.h"


MaterialNode::MaterialNode(glm::vec4 icolor, glm::vec2 uvScaling, int mixMode, int nodeTarget)
{
    source = NODE_SOURCE_COLOR;
    modifierflags = NODE_MODIFIER_ORIGINAL;
    color = icolor;
    data = glm::vec4(1);
    texture = nullptr;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(Texture * tex, glm::vec2 uvScaling, int mixMode, int nodeTarget)
{
    source = NODE_SOURCE_TEXTURE;
    modifierflags = NODE_MODIFIER_ORIGINAL;
    color = glm::vec4(1);
    data = glm::vec4(1);
    texture = tex;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(glm::vec4 icolor, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier)
{
    source = NODE_SOURCE_COLOR;
    modifierflags = modifier;
    color = icolor;
    data = glm::vec4(1);
    texture = nullptr;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(Texture * tex, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier)
{
    source = NODE_SOURCE_TEXTURE;
    modifierflags = modifier;
    color = glm::vec4(1);
    data = glm::vec4(1);
    texture = tex;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(glm::vec4 icolor, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier, float idata)
{
    source = NODE_SOURCE_COLOR;
    modifierflags = modifier;
    color = icolor;
    data = glm::vec4(idata);
    texture = nullptr;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(Texture * tex, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier, float idata)
{
    source = NODE_SOURCE_TEXTURE;
    modifierflags = modifier;
    color = glm::vec4(1);
    data = glm::vec4(idata);
    texture = tex;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(glm::vec4 icolor, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier, glm::vec4 idata)
{
    source = NODE_SOURCE_COLOR;
    modifierflags = modifier;
    color = icolor;
    data = idata;
    texture = nullptr;
    uvScale = uvScaling;
    mixingMode = mixMode;
    target = nodeTarget;
}

MaterialNode::MaterialNode(Texture * tex, glm::vec2 uvScaling, int mixMode, int nodeTarget, int modifier, glm::vec4 idata)
{
    source = NODE_SOURCE_TEXTURE;
    modifierflags = modifier;
    color = glm::vec4(1);
    data = idata;
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
