#pragma once

class Game
{
public:

    GLFWwindow* window;

    Game(string title, int width, int height);
    ~Game();

private:
    bool shouldClose;

    void onRenderFrame();
};

