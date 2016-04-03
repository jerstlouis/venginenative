#pragma once
#include "glfw.h";

class Game
{
public:

    GLFWwindow *window;


    int width;
    int height;

    Game(int windowwidth, int windowheight);
    ~Game();
    void start();
    void invoke(const function<void(void)> &func);
    bool shouldClose;

private:

    queue<function<void(void)>> invokeQueue;
    void renderThread();
    void onRenderFrame();
};

