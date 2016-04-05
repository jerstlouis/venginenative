#pragma once
class ShaderStorageBuffer
{
public:
    ShaderStorageBuffer();
    ShaderStorageBuffer(GLuint ihandle);
    ~ShaderStorageBuffer();
    void use(unsigned int index);
    void mapData(unsigned int size, const void * data);
private:
    GLuint handle;
    bool generated;
    void generate();
};

