// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#include <stdio.h>
#include <tchar.h>


#include <stdlib.h>
#include <string.h>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <unordered_set>
#include <functional>
#include <thread>
#include <algorithm>
#include <queue>
#include <regex>
#include <map>

using namespace std;


#include "glad.h"
#include "glfw.h"

#define glAssert() {if(glGetError() != GL_NO_ERROR) printf("ERROR ON LINE [%d] %s", __LINE__, __FILE__);}

#include "glm/vec3.hpp" // glm::vec3
#include "glm/vec4.hpp" // glm::vec4
#include "glm/mat4x4.hpp" // glm::mat4
#include "glm/gtc/matrix_transform.hpp" // glm::translate, glm::rotate, glm::scale, glm::perspective
#include "glm/gtc/constants.hpp" // glm::pi 
#include "glm/gtc/quaternion.hpp"
#include "glm/gtc/type_ptr.hpp"

#define PI 3.14159265358979323846
#define rad2deg(a) (a * (180.0 / PI))
#define deg2rad(a) (a * (PI / 180.0))
