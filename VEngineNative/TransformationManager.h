#pragma once
class TransformationManager
{
public:
    TransformationManager();
    ~TransformationManager();

    glm::vec3 position;
    glm::vec3 size;
    glm::quat orientation;

    void setPosition(glm::vec3 value);
    void setSize(glm::vec3 value);
    void setOrientation(glm::quat value);

    void translate(glm::vec3 value);
    void scale(glm::vec3 value);
    void rotate(glm::quat value);

    glm::mat4 getWorldTransform();
};

