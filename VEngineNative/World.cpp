#include "stdafx.h"
#include "Game.h"
#include "World.h"


World::World()
{
    mainDisplayCamera = nullptr;
    scene = new Scene();
}

World::~World()
{
    delete scene;
    delete mainDisplayCamera;
}

void World::draw(ShaderProgram *shader, Camera *camera)
{
    shader->use();
    glm::mat4 cameraViewMatrix = camera->transformation->getInverseWorldTransform();
    glm::mat4 vpmatrix = camera->projectionMatrix * cameraViewMatrix;
    camera->cone->update(camera->transformation->position, vpmatrix);
    shader->setUniform("VPMatrix", vpmatrix);
    shader->setUniform("Resolution", glm::vec2(Game::instance->width, Game::instance->height));
    shader->setUniform("CameraPosition", camera->transformation->position);
    shader->setUniform("MainCameraPosition", mainDisplayCamera->transformation->position);
    scene->draw();
}
