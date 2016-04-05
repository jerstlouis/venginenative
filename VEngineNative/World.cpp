#include "stdafx.h"
#include "Game.h"
#include "World.h"


World::World()
{
    mainDisplayCamera = nullptr;
    currentCamera = nullptr;
    scene = new Scene();
}


World::~World()
{
}

void World::draw()
{
    if (mainDisplayCamera != nullptr && currentCamera != nullptr) {
        ShaderProgram *shader = Game::instance->shaders->materialShader;
        shader->use();
        shader->setUniform("VPMatrix", currentCamera->projectionMatrix * currentCamera->transformation->getInverseWorldTransform());
        shader->setUniform("Resolution", glm::vec2(Game::instance->width, Game::instance->height));
        shader->setUniform("CameraPosition", currentCamera->transformation->position);
        scene->draw();
    }
}
