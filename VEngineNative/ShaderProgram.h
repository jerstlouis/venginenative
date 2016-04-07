#pragma once
class ShaderProgram
{

public:
    ShaderProgram(string vertex, string fragment, string geometry = "", string tesscontrol = "", string tesseval = "");
    ~ShaderProgram();
    void recompile();
    void use();
    void setUniform(string name, GLint value);
    void setUniform(string name, GLuint value);

    void setUniform(string name, float value);
    void setUniform(string name, bool value);

    void setUniform(string name, glm::vec2 value);
    void setUniform(string name, glm::vec3 value);
    void setUniform(string name, glm::vec4 value);

    void setUniform(string name, glm::mat3 value);
    void setUniform(string name, glm::mat4 value);
    void setUniform(string name, glm::quat value);

    void setUniformVector(string name, vector<GLint> value);
    void setUniformVector(string name, vector<GLuint> value);

    void setUniformVector(string name, vector<float> value);

    void setUniformVector(string name, vector<glm::vec2> value);
    void setUniformVector(string name, vector<glm::vec3> value);
    void setUniformVector(string name, vector<glm::vec4> value);

    void setUniformVector(string name, vector<glm::mat3> value);
    void setUniformVector(string name, vector<glm::mat4> value);
    void setUniformVector(string name, vector<glm::quat> value);

    static ShaderProgram *current;

private:

    bool generated = false;
    GLuint handle;
    string vertexFile;
    string fragmentFile;
    string geometryFile;
    string tessControlFile;
    string tessEvalFile;
    map<string, GLint> uniformLocationsMap;

    GLint getUniformLocation(string name);
    void compile();
    string resolveIncludes(string source);
    GLuint compileSingleShader(GLenum type, string filename, string source);
};

