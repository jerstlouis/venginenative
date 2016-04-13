#pragma once
#include "CubeMapTexture.h"
#include "Camera.h"
class CubeMapFramebuffer
{
public:
    CubeMapFramebuffer();
    CubeMapFramebuffer(int iwidth, int iheight, GLuint ihandle);
    ~CubeMapFramebuffer();
    void attachTexture(CubeMapTexture *tex, GLenum attachment);
    void use();
    Camera* switchFace(GLenum face, bool clear);
private:
    class Attachment {
    public:
        CubeMapTexture* texture;
        GLenum attachment;
    };
    vector<Attachment*> attachedTextures;
    GLuint handle;
    bool generated;
    int width;
    int height;
    vector<Camera*> facesCameras;
    void generate();
};
