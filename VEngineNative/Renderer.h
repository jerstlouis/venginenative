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
    Texture *bufferTexture;
    Texture *depthTexture;
    Framebuffer *fbo;
    ShaderProgram *outputShader;
    Object3dInfo *quad3dInfo;
};
