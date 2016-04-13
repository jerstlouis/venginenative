#include "stdafx.h"
#include "Game.h"

Game * Game::instance = nullptr;

Game::Game(int windowwidth, int windowheight)
{
    instance = this;
    width = windowwidth;
    height = windowheight;
    invokeQueue = {};
    onRenderFrame = {};
    asset = new AssetLoader();
    world = new World();
    renderer = new Renderer(width, height);
    shaders = new GenericShaders();
    screenFbo = new Framebuffer(width, height, 0);
    onRenderFrame = new EventHandler<int>();
    onKeyPress = new EventHandler<int>();
    onKeyRelease = new EventHandler<int>();
    onKeyRepeat = new EventHandler<int>();
}

Game::~Game()
{
}

void Game::start()
{
    thread renderthread(bind(&Game::renderThread, this));
    renderthread.detach();
}

void Game::invoke(const function<void(void)> &func)
{
    invokeQueue.push(func);
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
    char debSource[160], debType[200], debSev[500];
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

void glfwKeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (action == GLFW_PRESS)
        Game::instance->onKeyPress->invoke(key);
    if (action == GLFW_RELEASE)
        Game::instance->onKeyRelease->invoke(key);
    if (action == GLFW_REPEAT)
        Game::instance->onKeyRepeat->invoke(key);
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

    glfwSetKeyCallback(window, glfwKeyCallback);

    glDebugMessageCallback(&debugCallback, NULL);

    printf("VERSION: %s\nVENDOR: %s", glGetString(GL_VERSION), glGetString(GL_VENDOR));

    glClearColor(0, 0, 0, 0);
    glClearDepth(1);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_DEPTH_CLAMP);
    glEnable(GL_CULL_FACE);
    glDepthFunc(GL_LEQUAL);
    glPatchParameteri(GL_PATCH_VERTICES, 3);
    glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

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
    onRenderFrame->invoke(0);

    if (world->mainDisplayCamera != nullptr) {
        renderer->renderToFramebuffer(world->mainDisplayCamera, screenFbo);
    }
}