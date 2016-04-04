#pragma once
class Texture
{
public:
    Texture(GLuint ihandle);
    Texture(string filekey, int channels);
    ~Texture();
    GLuint handle;
    int components;
    unsigned char* data;
    int width, height;
    bool generated;
    void use(GLenum unit);
private:
    void generate();
};

