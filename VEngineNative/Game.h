#pragma once
#include "glfw.h";
#include "World.h";
#include "GenericShaders.h";

class Game
{
public:

    GLFWwindow *window;
    World *world;
    GenericShaders *shaders;
    static Game *instance;

    int width;
    int height;

    Game(int windowwidth, int windowheight);
    ~Game();
    void start();
    void invoke(const function<void(void)> &func);
    void addOnRenderFrame(const function<void(void)> &func);
    bool shouldClose;

    int getKeyStatus(int key);
    void setCursorMode(int mode);
    glm::dvec2 getCursorPosition();

private:

    queue<function<void(void)>> invokeQueue;
    vector<function<void(void)>> onRenderFrame;
    void renderThread();
    void onRenderFrameFunc();
};

