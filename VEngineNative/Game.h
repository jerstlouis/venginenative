#pragma once
#include "glfw.h";
#include "World.h";
#include "Renderer.h";
#include "GenericShaders.h";
#include "EventHandler.h";

class Game
{
public:

    GLFWwindow *window;
    World *world;
    GenericShaders *shaders;
    Renderer *renderer;
    Framebuffer *screenFbo;
    static Game *instance;

    int width;
    int height;

    Game(int windowwidth, int windowheight);
    ~Game();
    void start();
    void invoke(const function<void(void)> &func);
    bool shouldClose;

    int getKeyStatus(int key);
    void setCursorMode(int mode);
    glm::dvec2 getCursorPosition();

    EventHandler<int> *onRenderFrame;
    EventHandler<int> *onKeyPress;
    EventHandler<int> *onKeyRelease;
    EventHandler<int> *onKeyRepeat;

private:

    queue<function<void(void)>> invokeQueue;
    void renderThread();
    void onRenderFrameFunc();
};

