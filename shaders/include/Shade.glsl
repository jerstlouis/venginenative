
#define PI 3.14159265

float CalculateFallof( float dist){
   return 1.0 / (dist * dist + 1.0);
}
 
float fresnel_again(vec3 normal, vec3 cameraspace, float roughness){
    vec3 dir = normalize(reflect(cameraspace, normal));
    float fz = roughness;
    float base =  1.0 - abs(dot(normalize(normal), dir));
    float fresnel = (fz + (1-fz)*(pow(base, 5.0)));
    return fresnel;
}
float fresnel_again2(float base, float roughness){
    float fz = roughness;
    float fresnel = (fz + (1-fz)*(pow(base, 5.0)));
    return fresnel;
}

float G1V(float dotNV, float k)
{
    return 1.0/max(0.001, dotNV*(1.0-k)+k);
}

vec3 LightingFuncGGX_REF(vec3 N, vec3 V, vec3 L, float roughness, vec3 F0)
{
    float alpha = roughness*roughness;

    vec3 H = normalize(V+L);

    float dotNL = max(0.001, dot(N,L));
    float dotNV = max(0.001, dot(N,V));
    float dotNH = max(0.001, dot(N,H));
    float dotLH = max(0.001, dot(L,H));

    vec3 F;
    float D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float pi = 3.14159;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
    D = alphaSqr/max(0.001, pi * denom * denom);

    // F
    float dotLH5 = pow(1.0-dotLH,5.0);
    F = F0;

    // V
    float k = alpha/2.0;
    vis = G1V(dotNL,k)*G1V(dotNV,k);

    vec3 specular = dotNL * D * F * vis;
    return specular;
}

vec3 orenNayarDiffuse(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness,
  vec3 albedo) {
  
  float LdotV = dot(lightDirection, viewDirection);
  float NdotL = dot(lightDirection, surfaceNormal);
  float NdotV = dot(surfaceNormal, viewDirection);

  float s = LdotV - NdotL * NdotV;
  float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

  float sigma2 = roughness * roughness;
  vec3 A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
  float B = 0.45 * sigma2 / (sigma2 + 0.09);

  return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
}

#define MaterialTypeSolid 0
#define MaterialTypeRandomlyDisplaced 1
#define MaterialTypeWater 2
#define MaterialTypeSky 3
#define MaterialTypeWetDrops 4
#define MaterialTypeGrass 5
#define MaterialTypePlanetSurface 6
#define MaterialTypeTessellatedTerrain 7
vec3 shade(
    vec3 camera,
    vec3 albedo, 
    vec3 normal,
    vec3 fragmentPosition, 
    vec3 lightPosition, 
    vec3 lightColor, 
    float roughness, 
    bool ignoreAtt
){
    vec3 lightRelativeToVPos =normalize( lightPosition - fragmentPosition);
    
    vec3 cameraRelativeToVPos = -normalize(fragmentPosition - camera);
    
    vec3 specularComponent = LightingFuncGGX_REF(
        normal,
        cameraRelativeToVPos,
        lightRelativeToVPos,
        roughness,
        lightColor
        );
        
    
    
    return  specularComponent * albedo;// * CalculateFallof(distance(lightPosition, fragmentPosition));
}

vec3 shadeDiffuse(
    vec3 camera,
    vec3 albedo, 
    vec3 normal,
    vec3 fragmentPosition, 
    vec3 lightPosition, 
    vec3 lightColor, 
    float roughness, 
    bool ignoreAtt
){
    vec3 lightRelativeToVPos =normalize( lightPosition - fragmentPosition);
    
    vec3 cameraRelativeToVPos = -normalize(fragmentPosition - camera);
    return  lightColor *  orenNayarDiffuse(lightRelativeToVPos,
              cameraRelativeToVPos,
              normal,
              roughness,
              albedo);
}
