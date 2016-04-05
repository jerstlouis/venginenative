#include "stdafx.h"
#include "ShaderProgram.h"
#include "Media.h"

ShaderProgram * ShaderProgram::current = nullptr;

ShaderProgram::ShaderProgram(string vertex, string fragment, string geometry, string tesscontrol, string tesseval)
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
    glDeleteProgram(handle);
}

void ShaderProgram::use()
{
    if (!generated)
        compile();
    current = this;
    glUseProgram(handle);
}

void ShaderProgram::setUniform(string name, GLint value)
{
    glUniform1i(getUniformLocation(name), value);
}

void ShaderProgram::setUniform(string name, GLuint value)
{
    glUniform1ui(getUniformLocation(name), value);
}

void ShaderProgram::setUniform(string name, float value)
{
    glUniform1f(getUniformLocation(name), value);
}

void ShaderProgram::setUniform(string name, bool value)
{
    glUniform1i(getUniformLocation(name), value ? 1 : 0);
}

void ShaderProgram::setUniform(string name, glm::vec2 value)
{
    glUniform2f(getUniformLocation(name), value.x, value.y);
}

void ShaderProgram::setUniform(string name, glm::vec3 value)
{
    glUniform3f(getUniformLocation(name), value.x, value.y, value.z);
}

void ShaderProgram::setUniform(string name, glm::vec4 value)
{
    glUniform4f(getUniformLocation(name), value.x, value.y, value.z, value.w);
}

void ShaderProgram::setUniform(string name, glm::quat value)
{
    glUniform4f(getUniformLocation(name), value.x, value.y, value.z, value.w);
}

void ShaderProgram::setUniform(string name, glm::mat3 value)
{
    glUniformMatrix3fv(getUniformLocation(name), 1, GL_FALSE, glm::value_ptr(value));
}

void ShaderProgram::setUniform(string name, glm::mat4 value)
{
    glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, glm::value_ptr(value));
}

void ShaderProgram::setUniformVector(string name, vector<GLint> value)
{
    glUniform1iv(getUniformLocation(name), (GLsizei)value.size(), value.data());
}

void ShaderProgram::setUniformVector(string name, vector<GLuint> value)
{
    glUniform1uiv(getUniformLocation(name), (GLsizei)value.size(), value.data());
}

void ShaderProgram::setUniformVector(string name, vector<float> value)
{
    glUniform1fv(getUniformLocation(name), (GLsizei)value.size(), value.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::vec2> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i].x);
        floats.push_back(value[i].y);
    }
    glUniform2fv(getUniformLocation(name), (GLsizei)value.size(), floats.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::vec3> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i].x);
        floats.push_back(value[i].y);
        floats.push_back(value[i].z);
    }
    glUniform3fv(getUniformLocation(name), (GLsizei)value.size(), floats.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::vec4> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i].x);
        floats.push_back(value[i].y);
        floats.push_back(value[i].z);
        floats.push_back(value[i].w);
    }
    glUniform4fv(getUniformLocation(name), (GLsizei)value.size(), floats.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::quat> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i].x);
        floats.push_back(value[i].y);
        floats.push_back(value[i].z);
        floats.push_back(value[i].w);
    }
    glUniform4fv(getUniformLocation(name), (GLsizei)value.size(), floats.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::mat3> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i][0][0]);
        floats.push_back(value[i][0][1]);
        floats.push_back(value[i][0][2]);

        floats.push_back(value[i][1][0]);
        floats.push_back(value[i][1][1]);
        floats.push_back(value[i][1][2]);

        floats.push_back(value[i][2][0]);
        floats.push_back(value[i][2][1]);
        floats.push_back(value[i][2][2]);
    }
    glUniformMatrix3fv(getUniformLocation(name), (GLsizei)value.size(), GL_FALSE, floats.data());
}

void ShaderProgram::setUniformVector(string name, vector<glm::mat4> value)
{
    vector<float> floats;
    for (int i = 0; i < value.size(); i++) {
        floats.push_back(value[i][0][0]);
        floats.push_back(value[i][0][1]);
        floats.push_back(value[i][0][2]);
        floats.push_back(value[i][0][3]);

        floats.push_back(value[i][1][0]);
        floats.push_back(value[i][1][1]);
        floats.push_back(value[i][1][2]);
        floats.push_back(value[i][1][3]);

        floats.push_back(value[i][2][0]);
        floats.push_back(value[i][2][1]);
        floats.push_back(value[i][2][2]);
        floats.push_back(value[i][2][3]);

        floats.push_back(value[i][3][0]);
        floats.push_back(value[i][3][1]);
        floats.push_back(value[i][3][2]);
        floats.push_back(value[i][3][3]);
    }
    glUniformMatrix4fv(getUniformLocation(name), (GLsizei)value.size(), GL_FALSE, floats.data());
}

GLint ShaderProgram::getUniformLocation(string name)
{
    if (!generated) return -1;
    if (uniformLocationsMap.find(name) == uniformLocationsMap.end()) {
        GLuint location = glGetUniformLocation(handle, name.c_str());
        uniformLocationsMap[name] = location;
        return location;
    }
    else {
        return uniformLocationsMap.at(name);
    }
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

string ShaderProgram::resolveIncludes(string source)
{
    string src = source;
    regex includeregex("\\#include (.+)\n");
    smatch match;
    while (regex_search(src, match, includeregex)) {
        int pos = match.position();
        int len = match.length();
        string group = match[1];
        string includedSrc = resolveIncludes(Media::readString(group));
        stringstream ss;
        ss << src.substr(0, pos) << "\n" << includedSrc << "\n" << src.substr(pos + len);
        src = ss.str();
    }
    return src;
}

GLuint ShaderProgram::compileSingleShader(GLenum type, string filename, string source)
{
    printf("Compiling shader %s\n", filename.c_str());
    string resolved = resolveIncludes(source);
    printf("Compiling source %s\n", resolved.c_str());
    GLuint shader = glCreateShader(type);
    const char* cstr = resolved.c_str();
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
