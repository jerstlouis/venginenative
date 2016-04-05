
struct ModelInfo{
	vec4 Rotation;
	vec3 Translation;
	uint Id;
	vec4 Scale;
};

layout (std430, binding = 0) buffer MMBuffer
{
  ModelInfo ModelInfos[]; 
}; 

vec3 transform_vertex(int info, vec3 vertex){
	vec3 result = vertex;
	result *= ModelInfos[info].Scale.xyz;
	result = quat_mul_vec(ModelInfos[info].Rotation, result);
	result += ModelInfos[info].Translation.xyz;
	return result;
}