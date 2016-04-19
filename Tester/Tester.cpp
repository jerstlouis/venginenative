// Tester.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include "../VEngineNative/Camera.h";
#include "../VEngineNative/Object3dInfo.h";
#include "../VEngineNative/Object3dManager.h";
#include "../VEngineNative/Media.h";
#include "../VEngineNative/World.h";
#include "../VEngineNative/Scene.h";
#include "../VEngineNative/Material.h";
#include "../VEngineNative/Mesh3d.h";
#include "../VEngineNative/Light.h";

Mesh3d * loadRawMesh(string file) {
    Material *mat = new Material();

    unsigned char* bytes;
    int bytescount = Media::readBinary(file, &bytes);
    GLfloat * floats = (GLfloat*)bytes;
    int floatsCount = bytescount / 4;
    vector<GLfloat> flo(floats, floats + floatsCount);

    Object3dInfo *o3i = new Object3dInfo(flo);

    return Mesh3d::create(o3i, mat);
}

int main()
{
    Media::loadFileMap("../../media");
    Media::loadFileMap("../../shaders");
    Game *game = new Game(1920, 1080);
    game->start();
    volatile bool ready = false;
    game->invoke([&ready]() {
        ready = true;
    });
    while (!ready);

    Camera *cam = new Camera();
    cam->createProjectionPerspective(deg2rad(45.0f), (float)game->width / (float)game->height, 0.01f, 1000);
    cam->transformation->translate(glm::vec3(0, 0, 4));
    glm::quat rot = glm::quat_cast(glm::lookAt(cam->transformation->position, glm::vec3(0), glm::vec3(0, 1, 0)));
    cam->transformation->setOrientation(rot);
    game->world->mainDisplayCamera = cam;

    // mesh loading

    game->world->scene = game->asset->loadSceneFile("sponza.scene");
  //  game->world->scene->addMesh(game->asset->loadMeshFile("car.mesh3d"));
    /*
    for (int i = 0; i < 11; i++) {

        for (int g = 0; g < 11; g++) {
            float rough = (float)i / 11.0f;
            float met = (float)g / 11.0f;
            Mesh3d* mesh = game->asset->loadMeshFile("icosphere.mesh3d");
            mesh->getLodLevel(0)->material->roughness = rough;
            mesh->getLodLevel(0)->material->metalness = met;
            mesh->getInstance(0)->transformation->translate(glm::vec3(i, 0, g) * 8.0f);
            game->world->scene->addMesh(mesh);
        }
    }
    */
    Light* light = game->asset->loadLightFile("test.light");
    light->type = LIGHT_SPOT;
    light->angle = 90;
    game->world->scene->addLight(light);

    Renderer * envRenderer = new Renderer(512, 512);
    envRenderer->useAmbientOcclusion = false;
    envRenderer->useGammaCorrection = false;
    vector<EnvPlane*> planes = {};
   /* planes.push_back(new EnvPlane(glm::vec3(0, 0, 0), glm::vec3(0, 1, 0)));
    planes.push_back(new EnvPlane(glm::vec3(0, 90, 0), glm::vec3(0, -1, 0)));
    planes.push_back(new EnvPlane(glm::vec3(0, 0, -8), glm::vec3(0, 0, 1)));
    planes.push_back(new EnvPlane(glm::vec3(0, 0, 6), glm::vec3(0, 0, -1)));
    planes.push_back(new EnvPlane(glm::vec3(-39, 0, 0), glm::vec3(1, 0, 0)));
    planes.push_back(new EnvPlane(glm::vec3(40, 0, 0), glm::vec3(-1, 0, 0)));
    */
    EnvProbe* probe1 = new EnvProbe(envRenderer, planes);
    probe1->transformation->translate(glm::vec3(-0, 9, 0));
    game->world->scene->addEnvProbe(probe1);
    /*
    EnvProbe* probe2 = new EnvProbe(envRenderer, planes);
    probe2->transformation->translate(glm::vec3(29, 9, 0));
    game->world->scene->addEnvProbe(probe2);

    EnvProbe* probe3 = new EnvProbe(envRenderer, planes);
    probe3->transformation->translate(glm::vec3(0, 9, -29));
    game->world->scene->addEnvProbe(probe3);

    EnvProbe* probe4 = new EnvProbe(envRenderer, planes);
    probe4->transformation->translate(glm::vec3(0, 9, 29));
    game->world->scene->addEnvProbe(probe4);
    */
    bool cursorFree = false;
    bool envRefresh = true;
    game->onKeyPress->add([&game, &cursorFree, &cam, &envRefresh](int key) {
        if (key == GLFW_KEY_PAUSE) {
            game->shaders->materialShader->recompile();
            game->shaders->depthOnlyShader->recompile();
            game->shaders->depthOnlyGeometryShader->recompile();
            game->shaders->materialGeometryShader->recompile();
            game->renderer->recompileShaders();
        }
        if (key == GLFW_KEY_0) {
            game->renderer->useAmbientOcclusion = !game->renderer->useAmbientOcclusion;
        }
        if (key == GLFW_KEY_F2) {
            Light* ca = game->asset->loadLightFile("candle.light");
            ca->transformation->position = cam->transformation->position;
            ca->transformation->orientation = cam->transformation->orientation;
            game->world->scene->addLight(ca);
        }
        if (key == GLFW_KEY_F3) {
            Light* ca = game->asset->loadLightFile("corrector.light");
            ca->transformation->position = cam->transformation->position;
            ca->transformation->orientation = cam->transformation->orientation;
            game->world->scene->addLight(ca);
        }
        if (key == GLFW_KEY_F4) {
            envRefresh = true;
        }
        if (key == GLFW_KEY_TAB) {
            if (!cursorFree) {
                cursorFree = true;
                game->setCursorMode(GLFW_CURSOR_NORMAL);
            }
            else {
                cursorFree = false;
                game->setCursorMode(GLFW_CURSOR_DISABLED);
            }
        }
    });

    float yaw = 0.0f, pitch = 0.0f;
    double lastcx = 0.0f, lastcy = 0.0f;
    bool intializedCameraSystem = false;

    game->setCursorMode(GLFW_CURSOR_DISABLED);

    game->onRenderFrame->add([&](int i) {
       // if (envRefresh) {
            probe1->refresh();
           // probe2->refresh();
          //  probe3->refresh();
          //  probe4->refresh();
            envRefresh = false;
       // }
        if (!cursorFree) {
            float speed = 0.1f;
            if (game->getKeyStatus(GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS) {
                speed *= 0.1f;
            }
            if (game->getKeyStatus(GLFW_KEY_LEFT_ALT) == GLFW_PRESS) {
                speed *= 10.0f;
            }
            if (game->getKeyStatus(GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS) {
                speed *= 3.0f;
            }
            if (game->getKeyStatus(GLFW_KEY_F1) == GLFW_PRESS) {
                light->transformation->position = cam->transformation->position;
                light->transformation->orientation = cam->transformation->orientation;
            }
            if (game->getKeyStatus(GLFW_KEY_W) == GLFW_PRESS) {
                glm::vec3 dir = cam->transformation->orientation * glm::vec3(0, 0, -1);
                cam->transformation->translate(dir * speed);
            }
            if (game->getKeyStatus(GLFW_KEY_S) == GLFW_PRESS) {
                glm::vec3 dir = cam->transformation->orientation * glm::vec3(0, 0, 1);
                cam->transformation->translate(dir * speed);
            }
            if (game->getKeyStatus(GLFW_KEY_A) == GLFW_PRESS) {
                glm::vec3 dir = cam->transformation->orientation * glm::vec3(-1, 0, 0);
                cam->transformation->translate(dir * speed);
            }
            if (game->getKeyStatus(GLFW_KEY_D) == GLFW_PRESS) {
                glm::vec3 dir = cam->transformation->orientation * glm::vec3(1, 0, 0);
                cam->transformation->translate(dir * speed);
            }
            if (game->getKeyStatus(GLFW_KEY_ESCAPE) == GLFW_PRESS) {
                game->shouldClose = true;
            }
            glm::dvec2 cursor = game->getCursorPosition();
            if (!intializedCameraSystem) {
                lastcx = cursor.x;
                lastcy = cursor.y;
                intializedCameraSystem = true;
            }
            float dx = (float)(lastcx - cursor.x);
            float dy = (float)(lastcy - cursor.y);
            lastcx = cursor.x;
            lastcy = cursor.y;
            yaw += dy * 0.2f;
            pitch += dx * 0.2f;
            if (yaw < -90.0) yaw = -90;
            if (yaw > 90.0) yaw = 90;
            if (pitch < -360.0f) pitch += 360.0f;
            if (pitch > 360.0f) pitch -= 360.0f;
            glm::quat newrot = glm::angleAxis(deg2rad(pitch), glm::vec3(0, 1, 0)) * glm::angleAxis(deg2rad(yaw), glm::vec3(1, 0, 0));
            cam->transformation->setOrientation(newrot);
        }
    });

    while (!game->shouldClose) {
    }
    return 0;
}