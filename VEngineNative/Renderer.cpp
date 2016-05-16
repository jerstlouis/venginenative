#include "stdafx.h"
#include "Renderer.h"
#include "Game.h"
#include "FrustumCone.h"
#include "Media.h"

Renderer::Renderer(int iwidth, int iheight)
{
    envProbesLightMultiplier = 1.0;
    width = iwidth;
    height = iheight;

    useAmbientOcclusion = true;
    useGammaCorrection = true;

    cloudsFloor = 2500;
    cloudsCeil = 6000;
    cloudsThresholdLow = 0.84;
    cloudsThresholdHigh = 0.85;
    cloudsDensityThresholdLow = 0.0;
    cloudsDensityThresholdHigh = 1.0;
    cloudsDensityScale = 1.0;
    cloudsWindSpeed = 0.4;
    cloudsScale = glm::vec3(1);
    sunDirection = glm::vec3(0, 1, 0);
    atmosphereScale = 1.0;
    waterWavesScale = 1.0;

    vector<GLfloat> ppvertices = {
        -1.0f, -1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, -1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };
    quad3dInfo = new Object3dInfo(ppvertices);
    quad3dInfo->drawMode = GL_TRIANGLE_STRIP;

    unsigned char* bytes;
    int bytescount = Media::readBinary("deferredsphere.raw", &bytes);
    GLfloat * floats = (GLfloat*)bytes;
    int floatsCount = bytescount / 4;
    vector<GLfloat> flo(floats, floats + floatsCount);

    sphere3dInfo = new Object3dInfo(flo);

    outputShader = new ShaderProgram("PostProcess.vertex.glsl", "Output.fragment.glsl");
    deferredShader = new ShaderProgram("PostProcessPerspective.vertex.glsl", "Deferred.fragment.glsl");
    envProbesShader = new ShaderProgram("PostProcess.vertex.glsl", "EnvProbes.fragment.glsl");
    ambientLightShader = new ShaderProgram("PostProcess.vertex.glsl", "AmbientLight.fragment.glsl");
    ambientOcclusionShader = new ShaderProgram("PostProcess.vertex.glsl", "AmbientOcclusion.fragment.glsl");
    fogShader = new ShaderProgram("PostProcess.vertex.glsl", "Fog.fragment.glsl");
    cloudsShader = new ShaderProgram("PostProcess.vertex.glsl", "Clouds.fragment.glsl");
    motionBlurShader = new ShaderProgram("PostProcess.vertex.glsl", "MotionBlur.fragment.glsl");
    bloomShader = new ShaderProgram("PostProcess.vertex.glsl", "Bloom.fragment.glsl");
    combineShader = new ShaderProgram("PostProcess.vertex.glsl", "Combine.fragment.glsl");
    fxaaTonemapShader = new ShaderProgram("PostProcess.vertex.glsl", "FxaaTonemap.fragment.glsl");

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
    mrtAlbedoRoughnessTex = new Texture(width, height, GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE);
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

    cloudsTexture = new Texture(width / 1, height / 1, GL_RG16F, GL_RG, GL_FLOAT);
    cloudsFbo = new Framebuffer();
    cloudsFbo->attachTexture(cloudsTexture, GL_COLOR_ATTACHMENT0);

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
        currentCamera = cam;
        cam->transformation->setPosition(position);
        draw(cam);
        fboout->use();
        fxaaTonemap();
    }
}

void Renderer::renderToFramebuffer(Camera *camera, Framebuffer * fboout)
{
    currentCamera = camera;
    draw(camera);
    fboout->use(true);
    fxaaTonemap();
}

void Renderer::draw(Camera *camera)
{
    mrtFbo->use(true);
    Game::instance->world->setUniforms(Game::instance->shaders->materialGeometryShader, camera);
    Game::instance->world->setUniforms(Game::instance->shaders->materialShader, camera);
    Game::instance->world->setSceneUniforms();
    Game::instance->world->draw(Game::instance->shaders->materialShader, camera);
    if (useAmbientOcclusion) {
        ambientOcclusion();
    }
    deferred();
    ambientLight();
    clouds();
    combine();
}

void Renderer::bloom()
{
}

void Renderer::combine()
{
    combineFbo->use(true);
    combineShader->use();
    mrtDistanceTexture->use(2);
    skyboxTexture->use(3);
    deferredTexture->use(5);
    ambientLightTexture->use(6);
    ambientOcclusionTexture->use(16);
    cloudsTexture->use(18);
    FrustumCone *cone = currentCamera->cone;
    //   outputShader->setUniform("VPMatrix", vpmatrix);
    combineShader->setUniform("UseAO", useAmbientOcclusion);
    combineShader->setUniform("UseGamma", useGammaCorrection);
    combineShader->setUniform("Resolution", glm::vec2(width, height));
    combineShader->setUniform("CameraPosition", currentCamera->transformation->position);
    combineShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    combineShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    combineShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    combineShader->setUniform("Time", Game::instance->time);
    combineShader->setUniform("CloudsFloor", cloudsFloor);
    combineShader->setUniform("CloudsCeil", cloudsCeil);
    combineShader->setUniform("CloudsThresholdLow", cloudsThresholdLow);
    combineShader->setUniform("CloudsThresholdHigh", cloudsThresholdHigh);
    combineShader->setUniform("CloudsWindSpeed", cloudsWindSpeed);
    combineShader->setUniform("CloudsScale", cloudsScale);
    combineShader->setUniform("SunDirection", sunDirection);
    combineShader->setUniform("AtmosphereScale", atmosphereScale);
    combineShader->setUniform("CloudsDensityScale", cloudsDensityScale);
    combineShader->setUniform("CloudsDensityThresholdLow", cloudsDensityThresholdLow);
    combineShader->setUniform("CloudsDensityThresholdHigh", cloudsDensityThresholdHigh);
    combineShader->setUniform("WaterWavesScale", waterWavesScale);
    quad3dInfo->draw();
}
void Renderer::fxaaTonemap()
{
    fxaaTonemapShader->use();
    combineTexture->use(16);
    FrustumCone *cone = currentCamera->cone;
    fxaaTonemapShader->setUniform("Resolution", glm::vec2(width, height));
    fxaaTonemapShader->setUniform("CameraPosition", currentCamera->transformation->position);
    fxaaTonemapShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    fxaaTonemapShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    fxaaTonemapShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    fxaaTonemapShader->setUniform("Time", Game::instance->time);

    quad3dInfo->draw();

    Game::instance->firstFullDrawFinished = true;
}

void Renderer::output()
{

}

void Renderer::recompileShaders()
{
    deferredShader->recompile();
    ambientLightShader->recompile();
    ambientOcclusionShader->recompile();
    envProbesShader->recompile();
    cloudsShader->recompile();
    combineShader->recompile();
    fxaaTonemapShader->recompile();
}

void Renderer::deferred()
{
    vector<Light*> lights = Game::instance->world->scene->getLights();

    deferredFbo->use(true);
    FrustumCone *cone = currentCamera->cone;
    glm::mat4 vpmatrix = currentCamera->projectionMatrix * currentCamera->transformation->getInverseWorldTransform();
    deferredShader->use();
    deferredShader->setUniform("UseAO", useAmbientOcclusion);
    deferredShader->setUniform("VPMatrix", vpmatrix);
    deferredShader->setUniform("Resolution", glm::vec2(width, height));
    deferredShader->setUniform("CameraPosition", currentCamera->transformation->position);
    deferredShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    deferredShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);
    ambientOcclusionTexture->use(16);
    glCullFace(GL_FRONT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);

    for (int i = 0; i < lights.size(); i++) {
        deferredShader->setUniform("LightColor", lights[i]->color);
        deferredShader->setUniform("LightPosition", lights[i]->transformation->position);
        deferredShader->setUniform("LightOrientation", glm::inverse(lights[i]->transformation->orientation));
        deferredShader->setUniform("LightAngle", lights[i]->angle);
        deferredShader->setUniform("LightType", lights[i]->type);
        deferredShader->setUniform("LightCutOffDistance", lights[i]->cutOffDistance);
        deferredShader->setUniform("LightUseShadowMap", lights[i]->shadowMappingEnabled);
        lights[i]->transformation->setSize(glm::vec3(lights[i]->cutOffDistance));
        deferredShader->setUniform("LightMMatrix", lights[i]->transformation->getWorldTransform());
        if (lights[i]->shadowMappingEnabled) {
            deferredShader->setUniform("LightVPMatrix", lights[i]->lightCamera->projectionMatrix
                * lights[i]->transformation->getInverseWorldTransform());
            lights[i]->bindShadowMap(14, 15);
        }
        sphere3dInfo->draw();
    }

    vector<EnvProbe*> probes = Game::instance->world->scene->getEnvProbes();

    glCullFace(GL_BACK);
    envProbesShader->use();
    envProbesShader->setUniform("UseAO", useAmbientOcclusion);
    envProbesShader->setUniform("VPMatrix", vpmatrix);
    envProbesShader->setUniform("Resolution", glm::vec2(width, height));
    envProbesShader->setUniform("EnvProbesLightMultiplier", envProbesLightMultiplier);
    envProbesShader->setUniform("CameraPosition", currentCamera->transformation->position);
    envProbesShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    envProbesShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    envProbesShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    for (int i = 0; i < probes.size(); i++) {
        probes[i]->texture->use(10);
        probes[i]->setUniforms();
        quad3dInfo->draw();
    }

    glDisable(GL_BLEND);
}

void Renderer::ambientLight()
{
    ambientLightFbo->use(true);
    ambientLightShader->use();
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);
    skyboxTexture->use(3);
    FrustumCone *cone = currentCamera->cone;
    glm::mat4 vpmatrix = currentCamera->projectionMatrix * currentCamera->transformation->getInverseWorldTransform();
    ambientLightShader->setUniform("VPMatrix", vpmatrix);
    ambientLightShader->setUniform("Resolution", glm::vec2(width, height));
    ambientLightShader->setUniform("CameraPosition", currentCamera->transformation->position);
    ambientLightShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    ambientLightShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    ambientLightShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    ambientLightShader->setUniform("Time", Game::instance->time);
    quad3dInfo->draw();
}

void Renderer::ambientOcclusion()
{
    ambientOcclusionFbo->use(true);
    ambientOcclusionShader->use();    
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);
    FrustumCone *cone = currentCamera->cone;
    glm::mat4 vpmatrix = currentCamera->projectionMatrix * currentCamera->transformation->getInverseWorldTransform();
    ambientOcclusionShader->setUniform("VPMatrix", vpmatrix);
    ambientOcclusionShader->setUniform("Resolution", glm::vec2(width, height));
    ambientOcclusionShader->setUniform("CameraPosition", currentCamera->transformation->position);
    ambientOcclusionShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    ambientOcclusionShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    ambientOcclusionShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    quad3dInfo->draw();
}

void Renderer::fog()
{
}

void Renderer::clouds()
{
    glDisable(GL_BLEND);
    FrustumCone *cone = currentCamera->cone;
    glm::mat4 vpmatrix = currentCamera->projectionMatrix * currentCamera->transformation->getInverseWorldTransform();
    mrtAlbedoRoughnessTex->use(0);
    mrtNormalMetalnessTex->use(1);
    mrtDistanceTexture->use(2);

    cloudsShader->use();
    cloudsShader->setUniform("VPMatrix", vpmatrix);
    cloudsShader->setUniform("Resolution", glm::vec2(width, height));
    cloudsShader->setUniform("CameraPosition", currentCamera->transformation->position);
    cloudsShader->setUniform("FrustumConeLeftBottom", cone->leftBottom);
    cloudsShader->setUniform("FrustumConeBottomLeftToBottomRight", cone->rightBottom - cone->leftBottom);
    cloudsShader->setUniform("FrustumConeBottomLeftToTopLeft", cone->leftTop - cone->leftBottom);
    cloudsShader->setUniform("Time", Game::instance->time);

    cloudsShader->setUniform("CloudsFloor", cloudsFloor);
    cloudsShader->setUniform("CloudsCeil", cloudsCeil);
    cloudsShader->setUniform("CloudsThresholdLow", cloudsThresholdLow);
    cloudsShader->setUniform("CloudsThresholdHigh", cloudsThresholdHigh);
    cloudsShader->setUniform("CloudsWindSpeed", cloudsWindSpeed);
    cloudsShader->setUniform("CloudsScale", cloudsScale);
    cloudsShader->setUniform("SunDirection", sunDirection);
    cloudsShader->setUniform("AtmosphereScale", atmosphereScale);
    cloudsShader->setUniform("CloudsDensityScale", cloudsDensityScale);
    cloudsShader->setUniform("CloudsDensityThresholdLow", cloudsDensityThresholdLow);
    cloudsShader->setUniform("CloudsDensityThresholdHigh", cloudsDensityThresholdHigh);
    cloudsShader->setUniform("WaterWavesScale", waterWavesScale);

    cloudsFbo->use(true);
    quad3dInfo->draw();
}

void Renderer::motionBlur()
{
}