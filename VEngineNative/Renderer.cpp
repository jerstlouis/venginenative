#include "stdafx.h"
#include "Renderer.h"
#include "Game.h"
#include "FrustumCone.h"


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

    mrtAlbedoRoughnessTex = new Texture(Game::instance->width, Game::instance->height, GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE);
    mrtNormalMetalnessTex = new Texture(Game::instance->width, Game::instance->height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    mrtDistanceTexture = new Texture(Game::instance->width, Game::instance->height, GL_R32F, GL_RED, GL_FLOAT);
    depthTexture = new Texture(Game::instance->width, Game::instance->height, GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, GL_FLOAT);

    fbo = new Framebuffer();
    fbo->attachTexture(mrtAlbedoRoughnessTex, GL_COLOR_ATTACHMENT0);
    fbo->attachTexture(mrtNormalMetalnessTex, GL_COLOR_ATTACHMENT1);
    fbo->attachTexture(mrtDistanceTexture, GL_COLOR_ATTACHMENT2);
    fbo->attachTexture(depthTexture, GL_DEPTH_ATTACHMENT);
}


Renderer::~Renderer()
{
}

void Renderer::renderToFramebuffer(Framebuffer * fboout)
{
    fbo->use(true);
    Game::instance->world->draw(Game::instance->shaders->materialShader, Game::instance->world->mainDisplayCamera);

    fboout->use(true);
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);

    outputShader->use();
    FrustumCone *cone = Game::instance->world->mainDisplayCamera->cone;
    outputShader->setUniform("Resolution", glm::vec2(Game::instance->width, Game::instance->height));
    outputShader->setUniform("CameraPosition", Game::instance->world->mainDisplayCamera->transformation->position);
    outputShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    outputShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    outputShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    quad3dInfo->draw();
}
