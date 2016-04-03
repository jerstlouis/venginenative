#include "stdafx.h"
#include "Game.h"


Game::Game(int windowwidth, int windowheight)
{
    width = windowwidth;
    height = windowheight;
}


Game::~Game()
{
}

void Game::start()
{
    thread renderthread (bind(&Game::renderThread, this));
    renderthread.detach();
}

void Game::invoke(const function<void(void)> &func)
{
    invokeQueue.push(func);
}

void Game::renderThread()
{
    if (!glfwInit()) {
        printf("ERROR: Cannot initialize GLFW!\n");
        return;
    }
    window = glfwCreateWindow(width, height, "VENGINE", NULL, NULL);
    if (!window)
    {
        printf("ERROR: Cannot create window or context!\n");
        glfwTerminate();
        return;
    }

    glfwMakeContextCurrent(window);

    if (!gladLoadGL())
    {
        printf("ERROR: Cannot initialize GLAD!\n");
        return;
    }
    shouldClose = false;
    while (!glfwWindowShouldClose(window) && !shouldClose)
    {
        onRenderFrame();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    shouldClose = true;
}

void Game::onRenderFrame()
{
    while (invokeQueue.size() > 0) {
        invokeQueue.front()();
        invokeQueue.pop();
    }

}
