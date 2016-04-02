#include "stdafx.h"
#include "Game.h"


Game::Game(string title, int width, int height)
{
    if (!glfwInit()) {
        printf("ERROR: Cannot initialize GLFW!\n");
        return;
    }
    window = glfwCreateWindow(width, height, title.c_str(), NULL, NULL);
    if (!window)
    {
        printf("ERROR: Cannot create window or context!\n");
        glfwTerminate();
        return;
    }

    if (!gladLoadGL()) 
    {
        printf("ERROR: Cannot initialize GLAD!\n");
        return;
    }
    shouldClose = false;
    glfwMakeContextCurrent(window);
    while (!glfwWindowShouldClose(window) && !shouldClose)
    {
        onRenderFrame();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
}


Game::~Game()
{
}

void Game::onRenderFrame()
{

}
