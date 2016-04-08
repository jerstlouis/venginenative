#pragma once
#include "Framebuffer.h";
#include "Texture.h";
#include "CubeMapTexture.h";
#include "CubeMapFramebuffer.h";
#include "ShaderProgram.h";
#include "Object3dInfo.h";
class Renderer
{
public:
    Renderer();
    ~Renderer();
    void renderToFramebuffer(CubeMapFramebuffer *fbo);
    void renderToFramebuffer(Framebuffer *fbo);
    void recompileShaders();
private:
    Framebuffer *fbo;
    Texture *mrtAlbedoRoughnessTex;
    Texture *mrtNormalMetalnessTex;
    Texture *mrtDistanceTexture;
    Texture *depthTexture;

    Framebuffer *deferredFbo;
    Texture *deferredTexture;

    CubeMapTexture *skyboxTexture;

    ShaderProgram *deferredShader;
    ShaderProgram *outputShader;

    Object3dInfo *quad3dInfo;

    void deferred();
};

