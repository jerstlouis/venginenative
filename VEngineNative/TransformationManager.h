#pragma once
using namespace glm;
class TransformationManager
{
public:
    TransformationManager();
    ~TransformationManager();

    vec3 position;
    vec3 size;
    quat orientation;

    void setPosition(vec3 value);
    void setSize(vec3 value);
    void setOrientation(quat value);

    void translate(vec3 value);
    void scale(vec3 value);
    void rotate(quat value);

    mat4 getWorldTransform();
};

