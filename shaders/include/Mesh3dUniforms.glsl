uniform mat4 VPMatrix;
uniform vec3 CameraPosition;
uniform vec2 Resolution;

uniform vec3 SpecularColor;
uniform vec3 DiffuseColor;
uniform float Roughness;

uniform int NormalTexEnabled;
uniform int BumpTexEnabled;
uniform int RoughnessTexEnabled;
uniform int DiffuseTexEnabled;
uniform int SpecularTexEnabled;

#define UseNormalsTex (NormalTexEnabled > 0)
#define UseBumpTex (BumpTexEnabled > 0)
#define UseRoughnessTex (RoughnessTexEnabled > 0)
#define UseDiffuseTex (DiffuseTexEnabled > 0)
#define UseSpecularTex (SpecularTexEnabled > 0)

layout(binding = 5) uniform sampler2D normalsTex;
layout(binding = 6) uniform sampler2D bumpTex;
layout(binding = 7) uniform sampler2D roughnessTex;
layout(binding = 8) uniform sampler2D diffuseTex;
layout(binding = 9) uniform sampler2D specularTex;