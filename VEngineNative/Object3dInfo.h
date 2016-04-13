#pragma once

#include "Object3dManager.h"

class Object3dInfo
{
public:
    Object3dInfo(vector<GLfloat> &vbo);
    ~Object3dInfo();

    GLenum drawMode;
    Object3dManager *manager;

    void draw();
    void drawInstanced(size_t instances);

private:

    void generate();

    vector<GLfloat> vbo;
    bool generated = false;
    GLuint vboHandle, vaoHandle;
    GLsizei vertexCount;
};
