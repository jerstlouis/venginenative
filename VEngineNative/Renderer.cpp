#include "stdafx.h"
#include "Renderer.h"
#include "Game.h"
#include "FrustumCone.h"


Renderer::Renderer(int iwidth, int iheight)
{
    width = iwidth;
    height = iheight;
    vector<GLfloat> ppvertices = {
        -1.0f, -1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, -1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };
    quad3dInfo = new Object3dInfo(ppvertices);
    quad3dInfo->drawMode = GL_TRIANGLE_STRIP;

    outputShader = new ShaderProgram("PostProcess.vertex.glsl", "Output.fragment.glsl");
    deferredShader = new ShaderProgram("PostProcess.vertex.glsl", "Deferred.fragment.glsl");
    ambientLightShader = new ShaderProgram("PostProcess.vertex.glsl", "AmbientLight.fragment.glsl");
    ambientOcclusionShader = new ShaderProgram("PostProcess.vertex.glsl", "AmbientOcclusion.fragment.glsl");
    fogShader = new ShaderProgram("PostProcess.vertex.glsl", "Fog.fragment.glsl");
    motionBlurShader = new ShaderProgram("PostProcess.vertex.glsl", "MotionBlur.fragment.glsl");
    bloomShader = new ShaderProgram("PostProcess.vertex.glsl", "Bloom.fragment.glsl");
    combineShader = new ShaderProgram("PostProcess.vertex.glsl", "Combine.fragment.glsl");

    skyboxTexture = new CubeMapTexture("posx.jpg", "posy.jpg", "posz.jpg", "negx.jpg", "negy.jpg", "negz.jpg");
    initializeFbos();
}

void Renderer::resize(int width, int height)
{
    destroyFbos();
    initializeFbos();
}

void Renderer::initializeFbos()
{
    mrtAlbedoRoughnessTex = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    mrtNormalMetalnessTex = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    mrtDistanceTexture = new Texture(width, height, GL_R32F, GL_RED, GL_FLOAT);
    depthTexture = new Texture(width, height, GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, GL_FLOAT); // most probably overkill

    mrtFbo = new Framebuffer();
    mrtFbo->attachTexture(mrtAlbedoRoughnessTex, GL_COLOR_ATTACHMENT0);
    mrtFbo->attachTexture(mrtNormalMetalnessTex, GL_COLOR_ATTACHMENT1);
    mrtFbo->attachTexture(mrtDistanceTexture, GL_COLOR_ATTACHMENT2);
    mrtFbo->attachTexture(depthTexture, GL_DEPTH_ATTACHMENT);

    deferredTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    deferredFbo = new Framebuffer();
    deferredFbo->attachTexture(deferredTexture, GL_COLOR_ATTACHMENT0);

    ambientLightTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    ambientLightFbo = new Framebuffer();
    ambientLightFbo->attachTexture(ambientLightTexture, GL_COLOR_ATTACHMENT0);

    ambientOcclusionTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    ambientOcclusionFbo = new Framebuffer();
    ambientOcclusionFbo->attachTexture(ambientOcclusionTexture, GL_COLOR_ATTACHMENT0);

    fogTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    fogFbo = new Framebuffer();
    fogFbo->attachTexture(fogTexture, GL_COLOR_ATTACHMENT0);

    motionBlurTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    motionBlurFbo = new Framebuffer();
    motionBlurFbo->attachTexture(motionBlurTexture, GL_COLOR_ATTACHMENT0);

    bloomXTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    bloomYTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    bloomFbo = new Framebuffer();
    bloomFbo->attachTexture(bloomXTexture, GL_COLOR_ATTACHMENT0);
    bloomFbo->attachTexture(bloomYTexture, GL_COLOR_ATTACHMENT1);

    combineTexture = new Texture(width, height, GL_RGBA16F, GL_RGBA, GL_HALF_FLOAT);
    combineFbo = new Framebuffer();
    combineFbo->attachTexture(combineTexture, GL_COLOR_ATTACHMENT0);
}

void Renderer::destroyFbos()
{
    delete mrtAlbedoRoughnessTex;
    delete mrtNormalMetalnessTex;
    delete mrtDistanceTexture;
    delete depthTexture;

    delete deferredFbo;
    delete deferredTexture;

    delete ambientLightFbo;
    delete ambientLightTexture;

    delete ambientOcclusionFbo;
    delete ambientOcclusionTexture;

    delete fogFbo;
    delete fogTexture;

    delete motionBlurFbo;
    delete motionBlurTexture;

    delete bloomFbo;
    delete bloomXTexture;
    delete bloomYTexture;

    delete combineFbo;
    delete combineTexture;
}

Renderer::~Renderer()
{
    destroyFbos();
    delete quad3dInfo;
    delete skyboxTexture;
    delete deferredShader;
    delete ambientLightShader;
    delete ambientOcclusionShader;
    delete fogShader;
    delete motionBlurShader;
    delete bloomShader;
    delete combineShader;
    delete outputShader;
}

void Renderer::renderToFramebuffer(glm::vec3 position, CubeMapFramebuffer * fboout)
{
    for (int i = 0; i < 6; i++) {
        fboout->use();
        Camera *cam = fboout->switchFace(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, true);
        cam->transformation->setPosition(position);
        draw(cam);
        fboout->use();
    }
}

void Renderer::renderToFramebuffer(Camera *camera, Framebuffer * fboout)
{
    draw(camera);
    fboout->use(true);
    output();
}

void Renderer::draw(Camera *camera)
{
    mrtFbo->use(true);
    Game::instance->world->draw(Game::instance->shaders->materialShader, camera);
    deferred();
}

void Renderer::bloom()
{
}

void Renderer::combine()
{
}

void Renderer::output()
{
    outputShader->use();
    mrtDistanceTexture->use(2);
    skyboxTexture->use(3);
    deferredTexture->use(5);
    FrustumCone *cone = Game::instance->world->mainDisplayCamera->cone;
    outputShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    outputShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    outputShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
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
    glm::mat4 vpmatrix = Game::instance->world->mainDisplayCamera->projectionMatrix * Game::instance->world->mainDisplayCamera->transformation->getInverseWorldTransform();
    deferredShader->setUniform("VPMatrix", vpmatrix);
    deferredShader->setUniform("Resolution", glm::vec2(Game::instance->width, Game::instance->height));
    deferredShader->setUniform("CameraPosition", Game::instance->world->mainDisplayCamera->transformation->position);
    deferredShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);
    skyboxTexture->use(3);
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

void Renderer::ambientLight()
{
}

void Renderer::ambientOcclusion()
{
}

void Renderer::fog()
{
}

void Renderer::motionBlur()
{
}


