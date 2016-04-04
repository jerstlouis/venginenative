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
    void addOnRenderFrame(const function<void(void)> &func);
    bool shouldClose;

private:

    queue<function<void(void)>> invokeQueue;
    vector<function<void(void)>> onRenderFrame;
    void renderThread();
    void onRenderFrameFunc();
};

