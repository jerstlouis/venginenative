#pragma once
class ShaderProgram
{
public:
    ShaderProgram(string vertex, string fragment, string geometry = "", string tesscontrol = "", string tesseval = "");
    ShaderProgram(string compute);
    ~ShaderProgram();
    void recompile();
    void use();
    void dispatch(GLuint groups_x, GLuint groups_y, GLuint groups_z);
    void setUniform(const string &name, const GLint &value);
    void setUniform(const string &name, const GLuint &value);

    void setUniform(const string &name, const float &value);
    void setUniform(const string &name, const bool &value);

    void setUniform(const string &name, const glm::vec2 &value);
    void setUniform(const string &name, const glm::vec3 &value);
    void setUniform(const string &name, const glm::vec4 &value);

    void setUniform(const string &name, const glm::mat3 &value);
    void setUniform(const string &name, const glm::mat4 &value);
    void setUniform(const string &name, const glm::quat &value);

    void setUniformVector(const string &name, const vector<GLint> &value);
    void setUniformVector(const string &name, const vector<GLuint> &value);

    void setUniformVector(const string &name, const vector<float> &value);

    void setUniformVector(const string &name, const vector<glm::vec2> &value);
    void setUniformVector(const string &name, const vector<glm::vec3> &value);
    void setUniformVector(const string &name, const vector<glm::vec4> &value);

    void setUniformVector(const string &name, const vector<glm::mat3> &value);
    void setUniformVector(const string &name, const vector<glm::mat4> &value);
    void setUniformVector(const string &name, const vector<glm::quat> &value);

    static ShaderProgram *current;

private:

    bool generated = false;
    GLuint handle;
    string vertexFile;
    string fragmentFile;
    string geometryFile;
    string tessControlFile;
    string tessEvalFile;
    string computeFile;
    map<string, GLint> uniformLocationsMap;

    GLint getUniformLocation(const string &name);
    void compile();
    string resolveIncludes(string source);
    GLuint compileSingleShader(GLenum type, string filename, string source);
};
