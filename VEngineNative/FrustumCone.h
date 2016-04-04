#pragma once
using namespace glm;
class FrustumCone
{
public:
    FrustumCone();
    ~FrustumCone();
    vec3 origin;
    vec3 leftBottom;
    vec3 leftTop;
    vec3 rightBottom;
    vec3 rightTop;
    void update(vec3 origin, mat4 viewmatrix, mat4 projmatrix);
private:
    vec3 getDir(vec3 origin, vec2 uv, mat4 inv);
};

