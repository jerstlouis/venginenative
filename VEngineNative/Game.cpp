#include "stdafx.h"
#include "Game.h"

Game * Game::instance = nullptr;

Game::Game(int windowwidth, int windowheight)
{
    width = windowwidth;
    height = windowheight;
    invokeQueue = {};
    onRenderFrame = {};
    world = new World();
    shaders = new GenericShaders();
    instance = this;
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

void Game::addOnRenderFrame(const function<void(void)>& func)
{
    onRenderFrame.push_back(func);
}

int Game::getKeyStatus(int key)
{
    return glfwGetKey(window, key);
}

void Game::setCursorMode(int mode)
{
    glfwSetInputMode(window, GLFW_CURSOR, mode);
}

glm::dvec2 Game::getCursorPosition()
{
    double xpos, ypos;
    glfwGetCursorPos(window, &xpos, &ypos);
    return glm::dvec2(xpos, ypos);
}

void APIENTRY debugCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message, const void *userParam)
{
    char debSource[16], debType[20], debSev[5];
    if (source == GL_DEBUG_SOURCE_API)
        strcpy_s(debSource, "OpenGL");
    else if (source == GL_DEBUG_SOURCE_WINDOW_SYSTEM)
        strcpy_s(debSource, "Window Sys");
    else if (source == GL_DEBUG_SOURCE_SHADER_COMPILER)
        strcpy_s(debSource, "Shader Compiler");
    else if (source == GL_DEBUG_SOURCE_THIRD_PARTY)
        strcpy_s(debSource, "Third Party");
    else if (source == GL_DEBUG_SOURCE_APPLICATION)
        strcpy_s(debSource, "Application");
    else if (source == GL_DEBUG_SOURCE_OTHER)
        strcpy_s(debSource, "Other");

    if (type == GL_DEBUG_TYPE_ERROR)
        strcpy_s(debType, "Error");
    else if (type == GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR)
        strcpy_s(debType, "Deprecated behavior");
    else if (type == GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR)
        strcpy_s(debType, "Undefined behavior");
    else if (type == GL_DEBUG_TYPE_PORTABILITY)
        strcpy_s(debType, "Portability");
    else if (type == GL_DEBUG_TYPE_PERFORMANCE)
        strcpy_s(debType, "Performance");
    else if (type == GL_DEBUG_TYPE_OTHER)
        strcpy_s(debType, "Other");

    if (severity == GL_DEBUG_SEVERITY_HIGH)
        strcpy_s(debSev, "High");
    else if (severity == GL_DEBUG_SEVERITY_MEDIUM)
        strcpy_s(debSev, "Medium");
    else if (severity == GL_DEBUG_SEVERITY_LOW)
        strcpy_s(debSev, "Low");

    printf("Source:%s\nType:%s\nID:%d\nSeverity:%s\nMessage:%s\n",
        debSource, debType, id, debSev, message);
}

void Game::renderThread()
{
    if (!glfwInit()) {
        printf("ERROR: Cannot initialize GLFW!\n");
        return;
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 4);
    glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    window = glfwCreateWindow(width, height, "VENGINE", NULL, NULL);
    glfwSetInputMode(window, GLFW_STICKY_KEYS, 1);
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

    glDebugMessageCallback(&debugCallback, NULL);

    printf("VERSION: %s\nVENDOR: %s", glGetString(GL_VERSION), glGetString(GL_VENDOR));

    glClearColor(1, 1, 1, 0);
    glClearDepth(1);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    shouldClose = false;
    double lastTime = glfwGetTime();
    int nbFrames = 0;
    while (!glfwWindowShouldClose(window) && !shouldClose)
    {
        double currentTime = glfwGetTime();
        nbFrames++;
        if (currentTime - lastTime >= 1.0) {
            printf("%f ms/frame = Frames %d\n", 1.0 / double(nbFrames), nbFrames);
            nbFrames = 0;
            lastTime = currentTime;
        }
        onRenderFrameFunc();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    shouldClose = true;
}

void Game::onRenderFrameFunc()
{
    while (invokeQueue.size() > 0) {
        invokeQueue.front()();
        invokeQueue.pop();
    }
    for (int i = 0; i < onRenderFrame.size(); i++) {
        onRenderFrame[i]();
    }

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    world->draw();
}

