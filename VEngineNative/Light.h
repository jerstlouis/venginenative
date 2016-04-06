#pragma once
#include "AbsTransformable.h"
#include "Texture.h"
#include "Framebuffer.h"
class Light : public AbsTransformable
{
public:
    Light();
    ~Light();
    float cutOffDistance;
    float angle;
    glm::vec3 color;
    void resizeShadowMap(int width, int height);
    void switchShadowMapping(bool value);
    void bindShadowMap(int index);
    void refreshShadowMap();
private:
    bool shadowMappingEnabled;
    int shadowMapWidth;
    int shadowMapHeight;
    Texture *depthMap;
    Framebuffer *mapper;
    void recreateFbo();
    void destroyFbo();
    Camera *lightCamera;
};

