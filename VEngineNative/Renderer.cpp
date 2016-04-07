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

    deferredTexture = new Texture(Game::instance->width, Game::instance->height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    deferredFbo = new Framebuffer();
    deferredFbo->attachTexture(deferredTexture, GL_COLOR_ATTACHMENT0);
    deferredShader = new ShaderProgram("PostProcess.vertex.glsl", "Deferred.fragment.glsl");
}


Renderer::~Renderer()
{
}

void Renderer::renderToFramebuffer(Framebuffer * fboout)
{
    fbo->use(true);
    Game::instance->world->draw(Game::instance->shaders->materialShader, Game::instance->world->mainDisplayCamera);

    deferred();


    fboout->use(true);
    outputShader->use();
    deferredTexture->use(5);
    quad3dInfo->draw();
}

void Renderer::recompileShaders()
{
    deferredShader->recompile();
    outputShader->recompile();
}

void Renderer::deferred()
{
    vector<Light*> lights = Game::instance->world->scene->getLights();

    for (int i = 0; i < lights.size(); i++) {
        lights[i]->refreshShadowMap();
    }
    
    deferredFbo->use(true);
    deferredShader->use();
    FrustumCone *cone = Game::instance->world->mainDisplayCamera->cone;
    deferredShader->setUniform("Resolution", glm::vec2(Game::instance->width, Game::instance->height));
    deferredShader->setUniform("CameraPosition", Game::instance->world->mainDisplayCamera->transformation->position);
    deferredShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);

    for (int i = 0; i < lights.size(); i++) {

        deferredShader->setUniform("LightColor", lights[i]->color);
        deferredShader->setUniform("LightPosition", lights[i]->transformation->position);
        deferredShader->setUniform("LightOrientation", lights[i]->transformation->orientation);
        deferredShader->setUniform("LightAngle", lights[i]->angle);
        deferredShader->setUniform("LightCutOffDistance", lights[i]->cutOffDistance);
        deferredShader->setUniform("LightUseShadowMap", lights[i]->shadowMappingEnabled);
        if (lights[i]->shadowMappingEnabled) {
            deferredShader->setUniform("LightVPMatrix", lights[i]->lightCamera->projectionMatrix
                * lights[i]->lightCamera->transformation->getInverseWorldTransform());
        }
        lights[i]->bindShadowMap(4);
        quad3dInfo->draw();
    }

    glDisable(GL_BLEND);
}
