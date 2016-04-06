#pragma once
class FrustumCone
{
public:
    FrustumCone();
    ~FrustumCone();
    glm::vec3 origin;
    glm::vec3 leftBottom;
    glm::vec3 leftTop;
    glm::vec3 rightBottom;
    glm::vec3 rightTop;
    void update(glm::vec3 iorigin, glm::mat4 viewprojmatrix);
private:
    glm::vec3 getDir(glm::vec3 origin, glm::vec2 uv, glm::mat4 inv);
};

