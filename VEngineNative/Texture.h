#pragma once
class Texture
{
public:
    Texture(GLuint ihandle);
    Texture(string filekey);
    ~Texture();
    GLuint handle;
    int components;
    unsigned char* data;
    int width, height;
    bool generated;
    void use(int unit);
private:
    void generate();
};

