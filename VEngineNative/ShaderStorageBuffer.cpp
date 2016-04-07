#include "stdafx.h"
#include "ShaderStorageBuffer.h"


ShaderStorageBuffer::ShaderStorageBuffer()
{
    generated = false;
}

ShaderStorageBuffer::ShaderStorageBuffer(GLuint ihandle)
{
    handle = handle;
    generated = true;
}


ShaderStorageBuffer::~ShaderStorageBuffer()
{
}

void ShaderStorageBuffer::use(unsigned int index)
{
    if (!generated) generate();
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, index, handle);
}

void ShaderStorageBuffer::mapData(size_t size, const void * data)
{
    if (!generated) generate();
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, handle);
    glBufferData(GL_SHADER_STORAGE_BUFFER, size, data, GL_DYNAMIC_DRAW);
}

void ShaderStorageBuffer::generate()
{
    glGenBuffers(1, &handle);
    generated = true;
}
