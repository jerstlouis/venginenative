#include "stdafx.h"
#include "CubeMapFramebuffer.h"

CubeMapFramebuffer::CubeMapFramebuffer()
{
    attachedTextures = {};
    generated = false;
    width = 1;
    height = 1;
}

CubeMapFramebuffer::CubeMapFramebuffer(int iwidth, int iheight, GLuint ihandle)
{
    handle = ihandle;
    width = iwidth;
    height = iheight;
    generated = true;
}

CubeMapFramebuffer::~CubeMapFramebuffer()
{
}

void CubeMapFramebuffer::attachTexture(CubeMapTexture * tex, GLenum attachment)
{
    Attachment *ath = new Attachment();
    ath->texture = tex;
    ath->attachment = attachment;
    attachedTextures.push_back(ath);
    width = tex->width;
    height = tex->height;
}

void CubeMapFramebuffer::use()
{
    if (!generated)
        generate();

    glBindFramebuffer(GL_FRAMEBUFFER, handle);

    glViewport(0, 0, width, height);
}

Camera* CubeMapFramebuffer::switchFace(GLenum face, bool clear)
{
    int vindex = face - GL_TEXTURE_CUBE_MAP_POSITIVE_X;
    for (int i = 0; i < attachedTextures.size(); i++) {
        glFramebufferTexture2D(GL_FRAMEBUFFER, attachedTextures[i]->attachment, face, attachedTextures[i]->texture->handle, 0);
    }
    if (clear)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return facesCameras[vindex];
}

void CubeMapFramebuffer::generate()
{
    facesCameras = {};

    Camera * cam_posx = new Camera();
    Camera * cam_posy = new Camera();
    Camera * cam_posz = new Camera();

    Camera * cam_newx = new Camera();
    Camera * cam_newy = new Camera();
    Camera * cam_newz = new Camera();

    cam_posx->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);
    cam_posy->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);
    cam_posz->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);

    cam_newx->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);
    cam_newy->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);
    cam_newz->createProjectionPerspective(deg2rad(90.0f), 1.0f, 0.1f, 10000.0f);

    cam_posx->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(1, 0, 0), glm::vec3(0, -1, 0)));
    cam_posy->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(0, -1, 0), glm::vec3(0, 0, -1)));
    cam_posz->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(0, 0, 1), glm::vec3(0, -1, 0)));

    cam_newx->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(-1, 0, 0), glm::vec3(0, -1, 0)));
    cam_newy->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(0, 1, 0), glm::vec3(0, 0, 1)));
    cam_newz->transformation->orientation = glm::quat_cast(glm::lookAt(glm::vec3(0), glm::vec3(0, 0, -1), glm::vec3(0, -1, 0)));

    facesCameras.push_back(cam_posx);
    facesCameras.push_back(cam_newx);

    facesCameras.push_back(cam_posy);
    facesCameras.push_back(cam_newy);

    facesCameras.push_back(cam_posz);
    facesCameras.push_back(cam_newz);

    glGenFramebuffers(1, &handle);
    glBindFramebuffer(GL_FRAMEBUFFER, handle);
    vector<GLenum> buffers;
    for (int i = 0; i < attachedTextures.size(); i++) {
        attachedTextures[i]->texture->pregenerate();
        glFramebufferTexture2D(GL_FRAMEBUFFER, attachedTextures[i]->attachment, GL_TEXTURE_CUBE_MAP_POSITIVE_X, attachedTextures[i]->texture->handle, 0);
        if (attachedTextures[i]->attachment < GL_DEPTH_ATTACHMENT)buffers.push_back(attachedTextures[i]->attachment);
    }
    glDrawBuffers((GLsizei)buffers.size(), buffers.data());

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        printf("Framebuffer not complete");
    }
    generated = true;
}