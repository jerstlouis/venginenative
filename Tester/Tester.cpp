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

int main()
{
    Media::loadFileMap("../../media");
    Media::loadFileMap("../../shaders");
    Game *game = new Game(1366, 768);
    game->start();
    game->invoke([]() {
        printf("abc");
    });

    Material *mat = new Material();
    mat->diffuseTexture = new Texture("1a.jpg");

    unsigned char* teapotBytes;
    int teapotBytesCount = Media::readBinary("sponza.raw", &teapotBytes);
    GLfloat * floats = (GLfloat*)teapotBytes;
    int floatsCount = teapotBytesCount / 4;
    vector<GLfloat> flo(floats, floats + floatsCount);

    Object3dInfo *o3i = new Object3dInfo(flo);

    Mesh3d *teapot = Mesh3d::create(o3i, mat);

    game->invoke([teapot]() {
        teapot->updateBuffers();
    });
    

    Camera *cam = new Camera();
    cam->createProjectionPerspective(deg2rad(90.0), 1366.0 / 768.0, 0.01, 1000);
    cam->transformation->translate(glm::vec3(0, 0, 4));
    glm::quat rot = glm::quat_cast(glm::lookAt(cam->transformation->position, glm::vec3(0), glm::vec3(0, 1, 0)));
    cam->transformation->setOrientation(rot);

    game->addOnRenderFrame([]() {
       // teapot->getInstance(0)->transformation->rotate(glm::angleAxis(0.01f, glm::vec3(0, 1, 0)));
        //cam->transformation->rotate(glm::angleAxis(0.01f, glm::vec3(0, 1, 0)));

    });
    
    game->world->scene->addMesh(teapot);
    game->world->mainDisplayCamera = cam;
    game->world->currentCamera = cam;

    float yaw = 0.0f, pitch = 0.0f;
    float lastcx = 0.0f, lastcy = 0.0;
    bool intializedCameraSystem = false;

    game->setCursorMode(GLFW_CURSOR_DISABLED);

    while (!game->shouldClose) {

        // process logic - on another thread
        if (game->getKeyStatus(GLFW_KEY_W) == GLFW_PRESS) {
            glm::vec3 dir = cam->transformation->orientation * glm::vec3(0, 0, -1);
            cam->transformation->translate(dir * 0.0001f);
        }
        if (game->getKeyStatus(GLFW_KEY_S) == GLFW_PRESS) {
            glm::vec3 dir = cam->transformation->orientation * glm::vec3(0, 0, 1);
            cam->transformation->translate(dir * 0.0001f);
        }
        if (game->getKeyStatus(GLFW_KEY_A) == GLFW_PRESS) {
            glm::vec3 dir = cam->transformation->orientation * glm::vec3(-1, 0, 0);
            cam->transformation->translate(dir * 0.0001f);
        }
        if (game->getKeyStatus(GLFW_KEY_D) == GLFW_PRESS) {
            glm::vec3 dir = cam->transformation->orientation * glm::vec3(1, 0, 0);
            cam->transformation->translate(dir * 0.0001f);
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
        float dx = lastcx - cursor.x;
        float dy = lastcy - cursor.y;
        lastcx = cursor.x;
        lastcy = cursor.y;
        yaw += dy * 0.1f;
        pitch += dx * 0.1f;
        if (yaw < -90.0) yaw = -90;
        if (yaw > 90.0) yaw = 90;
        if (pitch < -360.0) pitch += 360.0;
        if (pitch > 360.0) pitch -= 360.0;
        glm::quat newrot = glm::angleAxis(deg2rad(pitch), glm::vec3(0, 1, 0)) * glm::angleAxis(deg2rad(yaw), glm::vec3(1, 0, 0));
        cam->transformation->setOrientation(newrot);
    }
    return 0;
}
