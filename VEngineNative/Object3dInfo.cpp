#include "stdafx.h"
#include "Object3dInfo.h"

/*
This class expected interleaved buffer in format
pos.xyz-uv.xy-normal.xyz-tangent.xyzw
totals in 12 elements per vertex
*/

Object3dInfo::Object3dInfo(vector<GLfloat> &vboin)
{
    vbo = move(vboin);
    generated = false;
    vertexCount = vbo.size() / 12;
    drawMode = GL_TRIANGLES;
}


Object3dInfo::~Object3dInfo()
{
    vbo.clear();
    if (generated) {
        glDeleteVertexArrays(1, &vaoHandle);
        glDeleteBuffers(1, &vboHandle);
    }
}

void Object3dInfo::draw()
{
    if (!generated) 
        generate();
    glBindVertexArray(vaoHandle);
    glDrawArrays(drawMode, 0, vertexCount);
}

void Object3dInfo::drawInstanced(int instances)
{
    if (!generated) 
        generate();
    glBindVertexArray(vaoHandle);
    glDrawArraysInstanced(drawMode, 0, vertexCount, instances);
}

void Object3dInfo::generate() 
{
    glGenVertexArrays(1, &vaoHandle);
    glGenBuffers(1, &vboHandle);
    glBindVertexArray(vaoHandle);
    glBindBuffer(GL_ARRAY_BUFFER, vboHandle);

    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * vbo.size(), vbo.data(), GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glEnableVertexAttribArray(3);

    glVertexAttribPointer(0, 3, GL_FLOAT, false, sizeof(GLfloat) * 12,  (void*)(sizeof(GLfloat) * 0));
    glVertexAttribPointer(1, 2, GL_FLOAT, false, sizeof(GLfloat) * 12,  (void*)(sizeof(GLfloat) * 3));
    glVertexAttribPointer(2, 3, GL_FLOAT, false, sizeof(GLfloat) * 12,  (void*)(sizeof(GLfloat) * 5));
    glVertexAttribPointer(3, 4, GL_FLOAT, false, sizeof(GLfloat) * 12,  (void*)(sizeof(GLfloat) * 8));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    //VBO.clear(); //  this should go with fence/barrier/finish
    generated = true;
}