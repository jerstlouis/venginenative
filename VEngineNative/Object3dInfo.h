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
    void drawInstanced(int instances);

private:

    void generate();

    vector<GLfloat> vbo;
    bool generated = false;
    GLuint vboHandle, vaoHandle, vertexCount;
};

