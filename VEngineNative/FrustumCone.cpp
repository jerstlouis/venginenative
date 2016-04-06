#include "stdafx.h"
#include "FrustumCone.h"

using namespace glm;

FrustumCone::FrustumCone()
{
}


FrustumCone::~FrustumCone()
{
}

void FrustumCone::update(vec3 iorigin, mat4 viewprojmatrix)
{
    origin = iorigin;
    mat4 inv = inverse(viewprojmatrix);
    leftBottom = getDir(origin, vec2(-1, -1), inv);
    leftTop = getDir(origin, vec2(-1, 1), inv);
    rightBottom = getDir(origin, vec2(1, -1), inv);
    rightTop = getDir(origin, vec2(1, 1), inv);
}

vec3 FrustumCone::getDir(vec3 origin, vec2 uv, mat4 inv)
{
    vec4 clip = inv * vec4(uv.x, uv.y, 0.01, 1.0);
    return normalize(vec3(clip.x, clip.y, clip.z) / clip.w);
}
