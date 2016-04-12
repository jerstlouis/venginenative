#include "stdafx.h"
#include "Game.h"
#include "Light.h"
#include "Camera.h"


Light::Light()
{
    initTransformation();
    shadowMappingEnabled = false;
    shadowMapWidth = 1;
    shadowMapHeight = 1;
    cutOffDistance = 10000;
    angle = deg2rad(90);
    type = LIGHT_SPOT;
    lightCamera = new Camera();
    delete lightCamera->transformation;
}

Light::~Light()
{
    destroyFbo();
}

void Light::resizeShadowMap(int width, int height)
{
    if (shadowMapWidth == width && shadowMapHeight == height) return;

    shadowMapWidth = width;
    shadowMapHeight = height; 

    recreateFbo();
}

void Light::switchShadowMapping(bool value)
{
    if (shadowMappingEnabled == value) return;
    if (value) {
        shadowMappingEnabled = true;
        recreateFbo();
    }
    else {
        shadowMappingEnabled = false;
        destroyFbo();
    }
}

void Light::bindShadowMap(int spot, int cube)
{
    if (shadowMappingEnabled) {
        depthMap->use(spot);
        depthCubeMap->use(cube);
    }
}

void Light::refreshShadowMap()
{
    if (shadowMappingEnabled) {


        if (type == LIGHT_SPOT) {
            mapper->use(true);

            lightCamera->transformation = transformation;
            lightCamera->createProjectionPerspective(angle, (float)shadowMapWidth / (float)shadowMapHeight, 0.1f, cutOffDistance);

            ShaderProgram *shader = Game::instance->shaders->depthOnlyShader;
            shader->use();
            shader->setUniform("CutOffDistance", cutOffDistance);
            Game::instance->world->setUniforms(shader, lightCamera);

            shader = Game::instance->shaders->depthOnlyGeometryShader;
            shader->use();
            shader->setUniform("CutOffDistance", cutOffDistance);
            Game::instance->world->setUniforms(shader, lightCamera);
            Game::instance->world->draw(shader, lightCamera);
        }
        else if (type == LIGHT_POINT) {
            for (int i = 0; i < 6; i++) {
                cubeMapper->use();
                Camera *cam = cubeMapper->switchFace(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, true);
                cam->transformation->setPosition(transformation->position);

                ShaderProgram *shader = Game::instance->shaders->depthOnlyShader;
                shader->use();
                shader->setUniform("CutOffDistance", cutOffDistance);
                Game::instance->world->setUniforms(shader, cam);

                shader = Game::instance->shaders->depthOnlyGeometryShader;
                shader->use();
                shader->setUniform("CutOffDistance", cutOffDistance);
                Game::instance->world->setUniforms(shader, cam);

                Game::instance->world->draw(shader, cam);
            }
        }
    }
}

void Light::recreateFbo()
{
    destroyFbo();
    Texture* helperDepthBuffer = new Texture(shadowMapWidth, shadowMapHeight,
        GL_DEPTH_COMPONENT32, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT);
    depthMap = new Texture(shadowMapWidth, shadowMapHeight,
        GL_R32F, GL_RED, GL_FLOAT);
    mapper = new Framebuffer();
    mapper->attachTexture(helperDepthBuffer, GL_DEPTH_ATTACHMENT);
    mapper->attachTexture(depthMap, GL_COLOR_ATTACHMENT0);

    CubeMapTexture* helperCubeDepthBuffer = new CubeMapTexture(shadowMapWidth, shadowMapHeight,
        GL_DEPTH_COMPONENT32, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT);
    depthCubeMap = new CubeMapTexture(shadowMapWidth, shadowMapHeight,
        GL_R32F, GL_RED, GL_FLOAT);
    cubeMapper = new CubeMapFramebuffer();
    cubeMapper->attachTexture(helperCubeDepthBuffer, GL_DEPTH_ATTACHMENT);
    cubeMapper->attachTexture(depthCubeMap, GL_COLOR_ATTACHMENT0);
}

void Light::destroyFbo()
{
    if (mapper != nullptr) {
        delete mapper;
        delete depthMap;
        delete cubeMapper;
        delete depthCubeMap;
    }
}
