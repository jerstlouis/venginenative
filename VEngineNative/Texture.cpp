#include "stdafx.h"
#include "Texture.h"
#include "Media.h"

Texture::Texture(GLuint ihandle)
{
    handle = ihandle;
    generated = true;
    width = 1;
    height = 1;
    components = 4;
    data = nullptr;
}

Texture::Texture(string filekey)
{
    int x, y, n;
    data = stbi_load(Media::getPath(filekey).c_str(), &x, &y, &n, 0);
    width = x;
    height = y;
    components = n;
    generated = false;
    genMode = genModeFromFile;
}

Texture::Texture(int iwidth, int iheight, GLint internalFormat, GLenum format, GLenum type)
{
    width = iwidth;
    height = iheight;
    internalFormatRequested = internalFormat;
    formatRequested = format;
    typeRequested = type;
    generated = false;
    genMode = genModeEmptyFromDesc;
}

Texture::~Texture()
{
}
void Texture::pregenerate()
{
    if (!generated) {
        generate();
    }
}

void Texture::generateMipMaps()
{
    glBindTexture(GL_TEXTURE_2D, handle);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glGenerateMipmap(GL_TEXTURE_2D);
}

void Texture::use(int unit)
{
    if (!generated) {
        generate();
    }
    glActiveTexture(GL_TEXTURE0 + unit);
    glBindTexture(GL_TEXTURE_2D, handle);
}

void Texture::generate()
{
    glGenTextures(1, &handle);
    glBindTexture(GL_TEXTURE_2D, handle);
    if (genMode == genModeFromFile) {
        GLint internalFormat;
        GLenum format;
        if (components == 1) {
            internalFormat = GL_RED;
            format = GL_RED;
        }
        else if (components == 2) {
            internalFormat = GL_RG;
            format = GL_RG;
        }
        else if (components == 3) {
            internalFormat = GL_RGB;
            format = GL_RGB;
        }
        else {
            internalFormat = GL_RGBA;
            format = GL_RGBA;
        }

        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width, height, 0, format, GL_UNSIGNED_BYTE, data);
        stbi_image_free(data);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glGenerateMipmap(GL_TEXTURE_2D);
        GLfloat largest_supported_anisotropy;
        glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &largest_supported_anisotropy);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, largest_supported_anisotropy);
    }
    else {
        glTexImage2D(GL_TEXTURE_2D, 0, internalFormatRequested, width, height, 0, formatRequested, typeRequested, (void*)0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
       // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE_ARB);
    }

    generated = true;
}
