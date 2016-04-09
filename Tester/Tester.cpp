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
    cam->createProjectionPerspective(deg2rad(90.0f), (float)game->width / (float)game->height, 0.01f, 1000);
    cam->transformation->translate(glm::vec3(0, 0, 4));
    glm::quat rot = glm::quat_cast(glm::lookAt(cam->transformation->position, glm::vec3(0), glm::vec3(0, 1, 0)));
    cam->transformation->setOrientation(rot);
    game->world->mainDisplayCamera = cam;

    // mesh loading

    Mesh3d * sponza = loadRawMesh("sponza.raw");

    Material *sponzamat = sponza->getLodLevel(0)->material;
    sponzamat->diffuseColor = glm::vec3(0.8f, 0.1f, 0.0f);
    sponzamat->roughness = 1.0;
    sponzamat->metalness = 0.0;

    MaterialNode *color = new MaterialNode(new Texture("KAMEN.JPG"), glm::vec2(1), NODE_MODE_REPLACE, NODE_TARGET_DIFFUSE);
    Texture* normalstones = new Texture("mrkbasestoneb01_n.jpg");
    MaterialNode *normal2 = new MaterialNode(normalstones, glm::vec2(30), NODE_MODE_ADD, NODE_TARGET_NORMAL);
    MaterialNode *normal3 = new MaterialNode(normalstones, glm::vec2(10), NODE_MODE_ADD, NODE_TARGET_NORMAL);
    MaterialNode *normal4 = new MaterialNode(normalstones, glm::vec2(1), NODE_MODE_ADD, NODE_TARGET_NORMAL);

    sponzamat->addNode(color);
    sponzamat->addNode(normal2);
    sponzamat->addNode(normal3);
    sponzamat->addNode(normal4);


    //-----------------------//
    // now a sphere

    Mesh3d * sphere = loadRawMesh("sphere.raw");
    sphere->getInstance(0)->transformation->translate(glm::vec3(0, 2, 0));
    Material * spheremat = sphere->getLodLevel(0)->material;
    spheremat->diffuseColor = glm::vec3(1.0);
    spheremat->roughness = 0.0;
    spheremat->metalness = 0.0;
    Texture *coltt = new Texture("stonew_a.jpg");
    Texture *normtt = new Texture("stonew_n.jpg");
    spheremat->addNode(new MaterialNode(coltt, glm::vec2(10), NODE_MODE_REPLACE, NODE_TARGET_DIFFUSE));
    spheremat->addNode(new MaterialNode(coltt, glm::vec2(20), NODE_MODE_MUL, NODE_TARGET_DIFFUSE));
    spheremat->addNode(new MaterialNode(coltt, glm::vec2(30), NODE_MODE_MUL, NODE_TARGET_DIFFUSE));
    spheremat->addNode(new MaterialNode(normtt, glm::vec2(10), NODE_MODE_REPLACE, NODE_TARGET_NORMAL));
    spheremat->addNode(new MaterialNode(normtt, glm::vec2(20), NODE_MODE_ADD, NODE_TARGET_NORMAL));
    spheremat->addNode(new MaterialNode(normtt, glm::vec2(30), NODE_MODE_ADD, NODE_TARGET_NORMAL));

    //-----------------------//

    game->invoke([&]() {
        sponza->updateBuffers();
        sphere->updateBuffers();
    });

    game->world->scene->addMesh(sponza);
    game->world->scene->addMesh(sphere);

    Light* light = new Light();
    light->switchShadowMapping(true);
    light->cutOffDistance = 100.0;
    light->color = glm::vec3(1);
    light->angle = deg2rad(90.0f);
    light->resizeShadowMap(2048, 2048);
    light->transformation->translate(glm::vec3(0, 2, 0));

    game->world->scene->addLight(light);


    bool cursorFree = false;
    game->onKeyPress->add([&game, &cursorFree](int key) {
        if (key == GLFW_KEY_PAUSE) {
            game->shaders->materialShader->recompile();
            game->shaders->depthOnlyShader->recompile();
            game->renderer->recompileShaders();
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
