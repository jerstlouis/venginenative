#include "stdafx.h"
#include "TransformationManager.h"

using namespace glm;

TransformationManager::TransformationManager()
{
    position = vec3(0);
    size = vec3(1);
    orientation = quat();
}


TransformationManager::~TransformationManager()
{
}

void TransformationManager::setPosition(vec3 value)
{
    position = value;
}

void TransformationManager::setSize(vec3 value)
{
    size = value;
}

void TransformationManager::setOrientation(quat value)
{
    orientation = value;
}

void TransformationManager::translate(vec3 value)
{
    position += value;
}

void TransformationManager::scale(vec3 value)
{
    size *= value;
}

void TransformationManager::rotate(quat value)
{
    orientation *= value;
}

mat4 TransformationManager::getWorldTransform()
{
    mat4 rotmat = glm::mat4_cast(orientation);
    mat4 transmat = glm::translate(mat4(1), position);
    mat4 scalemat = glm::scale(mat4(1), size);
    return transmat * rotmat * scalemat;
}
