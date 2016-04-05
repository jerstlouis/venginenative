#pragma once

class Texture
{
public:
    Texture(GLuint ihandle);
    Texture(string filekey);
    Texture(int iwidth, int iheight, GLint internalFormat, GLenum format, GLenum type);
    ~Texture();



    GLuint handle;
    int components;
    unsigned char* data;
    int width, height;
    bool generated;
    void use(int unit);
    void pregenerate();
private:
    void generate();
    int genMode;
    const int genModeFromFile = 1;
    const int genModeEmptyFromDesc = 2;
    GLint internalFormatRequested;
    GLenum formatRequested;
    GLenum typeRequested;
};

