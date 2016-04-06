#pragma once
#include "Framebuffer.h";
#include "Texture.h";
#include "ShaderProgram.h";
#include "Object3dInfo.h";
class Renderer
{
public:
    Renderer();
    ~Renderer();
    void renderToFramebuffer(Framebuffer *fbo);
private:
    Texture *mrtAlbedoRoughnessTex;
    Texture *mrtNormalMetalnessTex;
    Texture *mrtDistanceTexture;
    Texture *depthTexture;

    Framebuffer *fbo;

    Framebuffer *deferredFbo;
    Texture *deferredTexture;
    ShaderProgram *deferredShader;

    ShaderProgram *outputShader;

    Object3dInfo *quad3dInfo;

    void deferred();
};

