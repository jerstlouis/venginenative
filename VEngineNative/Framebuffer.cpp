#include "stdafx.h"
#include "Framebuffer.h"


Framebuffer::Framebuffer()
{
    attachedTextures = {};
    generated = false;
    width = 1;
    height = 1;
}

Framebuffer::Framebuffer(int iwidth, int iheight, GLuint ihandle)
{
    handle = ihandle;
    width = iwidth;
    height = iheight;
    generated = true;
}


Framebuffer::~Framebuffer()
{
}

void Framebuffer::attachTexture(Texture * tex, GLenum attachment)
{
    Attachment *ath = new Attachment();
    ath->texture = tex;
    ath->attachment = attachment;
    attachedTextures.push_back(ath);
    width = tex->width;
    height = tex->height;
}

void Framebuffer::use(bool clear)
{
    if (!generated) 
        generate();

    glBindFramebuffer(GL_FRAMEBUFFER, handle);

    glViewport(0, 0, width, height);
    if (clear) 
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void Framebuffer::generate()
{
    glGenFramebuffers(1, &handle);
    glBindFramebuffer(GL_FRAMEBUFFER, handle);
    vector<GLenum> buffers;
    for (int i = 0; i < attachedTextures.size(); i++) {
        attachedTextures[i]->texture->pregenerate();
        glFramebufferTexture(GL_FRAMEBUFFER, attachedTextures[i]->attachment, attachedTextures[i]->texture->handle, 0);
        if(attachedTextures[i]->attachment < GL_DEPTH_ATTACHMENT)buffers.push_back(attachedTextures[i]->attachment);
    }
    glDrawBuffers((GLsizei)buffers.size(), buffers.data());

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        printf("Framebuffer not complete");
    }
    generated = true;
}
