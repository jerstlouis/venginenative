#include "stdafx.h"
#include "Renderer.h"
#include "Game.h"


Renderer::Renderer()
{
    vector<GLfloat> ppvertices = {
        -1.0f, -1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, -1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };
    quad3dInfo = new Object3dInfo(ppvertices);
    quad3dInfo->drawMode = GL_TRIANGLE_STRIP;

    outputShader = new ShaderProgram("PostProcess.vertex.glsl", "Output.fragment.glsl");

    bufferTexture = new Texture(Game::instance->width, Game::instance->height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    depthTexture = new Texture(Game::instance->width, Game::instance->height, GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, GL_FLOAT);
    fbo = new Framebuffer();
    fbo->attachTexture(bufferTexture, GL_COLOR_ATTACHMENT0);
    fbo->attachTexture(depthTexture, GL_DEPTH_ATTACHMENT);
}


Renderer::~Renderer()
{
}

void Renderer::renderToFramebuffer(Framebuffer * fboout)
{
    fbo->use(true);
    Game::instance->world->draw();
    fboout->use(true);
    bufferTexture->use(0);
    outputShader->use();
    quad3dInfo->draw();
}
