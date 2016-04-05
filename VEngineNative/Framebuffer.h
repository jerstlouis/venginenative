#pragma once
#include "Texture.h"
class Framebuffer
{
public:
    Framebuffer();
    Framebuffer(int iwidth, int iheight, GLuint ihandle);
    ~Framebuffer();
    void attachTexture(Texture *tex, GLenum attachment);
    void use(bool clear);
private:
    class Attachment {
    public:
        Texture* texture;
        GLenum attachment;
    };
    vector<Attachment*> attachedTextures;
    GLuint handle;
    bool generated;
    int width;
    int height;
    void generate();
};

