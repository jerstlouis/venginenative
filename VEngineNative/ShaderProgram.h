#pragma once
class ShaderProgram
{

public:
    ShaderProgram(string vertex, string fragment, string geometry = "", string tesscontrol = "", string tesseval = "");
    ~ShaderProgram();
    void use();


    static ShaderProgram *current;

private:

    bool generated = false;
    GLuint handle;
    string vertexFile;
    string fragmentFile;
    string geometryFile;
    string tessControlFile;
    string tessEvalFile;

    void compile();
    GLuint compileSingleShader(GLenum type, string filename, string source);
};

