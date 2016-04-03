#include "stdafx.h"
#include "ShaderProgram.h"
#include "Media.h"


ShaderProgram::ShaderProgram(string vertex, string fragment, string geometry = "", string tesscontrol = "", string tesseval = "")
{
    vertexFile = vertex;
    fragmentFile = fragment;
    geometryFile = geometry;
    tessControlFile = tesscontrol;
    tessEvalFile = tesseval;
    generated = false;
}

ShaderProgram::~ShaderProgram()
{
}

void ShaderProgram::use()
{
    if (!generated)
        compile();
    glUseProgram(handle);
}

void ShaderProgram::compile()
{
    handle = glCreateProgram();
    GLuint vertexHandle = compileSingleShader(GL_VERTEX_SHADER, vertexFile, Media::readString(vertexFile));
    glAttachShader(handle, vertexHandle);

    if (fragmentFile != "") {
        GLuint fragmentHandle = compileSingleShader(GL_FRAGMENT_SHADER, fragmentFile, Media::readString(fragmentFile));
        glAttachShader(handle, fragmentHandle);
    }
    if (geometryFile != "") {
        GLuint geometryHandle = compileSingleShader(GL_GEOMETRY_SHADER, geometryFile, Media::readString(geometryFile));
        glAttachShader(handle, geometryHandle);
    }
    if (tessControlFile != "") {
        GLuint tesscHandle = compileSingleShader(GL_TESS_CONTROL_SHADER, tessControlFile, Media::readString(tessControlFile));
        glAttachShader(handle, tesscHandle);
    }
    if (tessEvalFile != "") {
        GLuint tesseHandle = compileSingleShader(GL_TESS_EVALUATION_SHADER, tessEvalFile, Media::readString(tessEvalFile));
        glAttachShader(handle, tesseHandle);
    }
    glLinkProgram(handle); 
    GLint status;
    glGetProgramiv(handle, GL_LINK_STATUS, &status);
    if (status != 1) {
        GLint loglen;
        glGetProgramiv(handle, GL_INFO_LOG_LENGTH, &loglen);
        char* log = new char[loglen + 1, sizeof(char)];
        glGetProgramInfoLog(handle, loglen, NULL, log);
        printf("LINKING FAILED WITH MESSAGE::\n%s\n", log);
        delete log;
        glDeleteProgram(handle);
    }
    generated = true;
}

GLuint ShaderProgram::compileSingleShader(GLenum type, string filename, string source)
{
    printf("Compiling shader %s\n", filename.c_str());
    GLuint shader = glCreateShader(type);
    const char* cstr = source.c_str();
    glShaderSource(shader, 1, &cstr, NULL);
    glCompileShader(shader);
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != 1) {
        GLint loglen;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &loglen);
        char* log = new char[loglen + 1, sizeof(char)];
        glGetShaderInfoLog(shader, loglen, NULL, log);
        printf("COMPILATION FAILED WITH MESSAGE::\n%s\n", log);
        delete log;
        glDeleteShader(shader);
    }
    return shader;
}
