#pragma once
class Texture3d
{
public:
    Texture3d(GLuint ihandle);
    Texture3d(int iwidth, int iheight, int idepth, GLint internalFormat, GLenum format, GLenum type);
    ~Texture3d();

    GLuint handle;
    int width, height, depth;
    void use(int unit);
    void bind(int unit);
    void pregenerate();
    void generateMipMaps();
private:
    bool generated;
    void generate();
    GLint internalFormatRequested;
    GLenum formatRequested;
    GLenum typeRequested;
};
