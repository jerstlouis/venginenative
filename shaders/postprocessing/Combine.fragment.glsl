#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D directTex;
layout(binding = 6) uniform sampler2D alTex;
layout(binding = 16) uniform sampler2D aoxTex;

uniform int UseAO;

#define CLOUD_SAMPLES 18
#define CLOUDCOVERAGE_DENSITY 50    
#include Atmosphere.glsl

float rdhash = 0.453451 + Time;
vec2 randpoint2(){
    float x = rand2s(UV * rdhash);
    rdhash += 2.1231255;
    float y = rand2s(UV * rdhash);
    rdhash += 1.6271255;
    return vec2(x, y) * 2.0 - 1.0;
}

float aaoo(){
    vec2 uv = reverseViewDir();
    float center = texture(cloudsCloudsTex, uv).b;
    float aoc = 0;
    for(int i=0;i<32;i++){
        vec2 rdp = randpoint2() * 0.01;
        float there = texture(cloudsCloudsTex, uv + rdp).b;
        float w = 1.0 - smoothstep(1000.0, 10000, center - there);
        aoc += w * clamp(center - there, 0.0, 1000.0) * 0.001;
    }
    return pow(1.0 - aoc / 32.0, 16.0);
}
vec4 smartblur(vec3 dir){
    vec2 uv = reverseDir(dir);
    //return texture(cloudsCloudsTex, uv).rgba;
    vec4 centerval = vec4(0);
    float center = texture(cloudsCloudsTex, uv).r;
    float aoc = 0;
    for(int i=0;i<32;i++){
        vec2 rdp = randpoint2() * 0.003;
        float there = texture(cloudsCloudsTex, uv + rdp).r;
        float w = pow( 1.0 - abs(there - center), 32.0);
        centerval += w * texture(cloudsCloudsTex, uv + rdp).rgba;
        aoc += w;
    }
    return aoc == 0 ? texture(cloudsCloudsTex, uv).rgba : centerval / aoc;
}


float fogatt(float dist){
    dist *= 0.000015;
    return min(1.0, (dist * dist) );
}

vec3 octaveN(vec2 a, float esp){
    vec2 zxpos = a * 0.01;
    //  zxpos += snoise(vec3(zxpos * 1.0 - Time * 0.1, 0));
    // zxpos += Time;
    float h1 = snoise(vec3(zxpos, Time * 0.1));
    float h2 = snoise(vec3(zxpos + vec2(esp, 0.0), Time * 0.5));
    float h3 = snoise(vec3(zxpos + vec2(0.0, esp), Time * 0.9));
    return normalize(vec3((h2 - h1) * 1.0, 11.0, (h3 - h1)* 1.0));
}
vec3 octaveNX(vec2 a, float esp){
    vec2 zxpos = a * 0.01;
    //  zxpos += snoise(vec3(zxpos * 1.0 - Time * 0.1, 0));
    // zxpos += Time;
    float h1 = snoise(vec3(zxpos, -Time * 0.1));
    float h2 = snoise(vec3(zxpos + vec2(esp, 0.0), -Time * 0.5));
    float h3 = snoise(vec3(zxpos + vec2(0.0, esp), -Time * 0.9));
    return normalize(vec3((h2 - h1) * 1.0, 11.0, (h3 - h1)* 1.0));
}
float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{ return dot(point - origin, normal) / dot(direction, normal); }


vec3 cloudsbydir(vec3 dir){
    float fresnel = 1.0;
    float dst = 0;
    if(dir.y < 0.0){
        
        vec3 atmorg = vec3(0, planetradius, 0) + CameraPosition;  
        Ray r = Ray(atmorg, dir);
        float planethit = intersectPlane(CameraPosition, dir, vec3(0), vec3(0,1,0));    
        dst = planethit;
        vec3 n = vec3(0,0,0);
        float w = 0;
        float w2 = 1.0;
        float mult = 0.1;
        for(int i=0;i<2;i++){
            n = normalize(n + w2 * octaveN((atmorg + dir * planethit).xz * mult, w2));
            w += w2;
            n = normalize(n + w2 * octaveNX((atmorg + dir * planethit).xz * mult, w2));
            w += w2;
            mult *= 2.5;
            w2 *= 0.6;
        }
      //  n = mix(n, vec3(0,1,0), min(1.0, planethit * 0.00001));
        fresnel = fresnel_again(vec3(0.04), n, dir, 0.04);
        dir = normalize(reflect(dir, n));
        if(dir.y < 0.0){
            dir = normalize(reflect(dir, vec3(0,1,0)));
        }
        
        //  return dir.yyy;
    }

    vec4 cdata = smartblur(dir).rgba;
    vec3 scatt = texture(atmScattTex, reverseDir(dir)).rgb + sun(dir, normalize(SunDirection));
    vec3 skydaylightcolor = vec3(0.23, 0.33, 0.48);
    atmcolor = getAtmosphereForDirection(vec3(0), normalize(SunDirection), normalize(SunDirection)) + vec3(1);
    atmcolor1 = getAtmosphereForDirection(vec3(0), vec3(0,1,0), normalize(SunDirection));
    float diminisher = max(0, dot(normalize(SunDirection), vec3(0,1,0)));
    vec3 shadowcolor = mix(skydaylightcolor, skydaylightcolor * 0.05, 1.0 - diminisher);
    vec3 litcolor = mix(vec3(10.0), atmcolor * 0.2, 1.0 - diminisher);
    vec3 colorcloud = mix(shadowcolor, litcolor, pow(cdata.g, 2.0)) ;//* (diminisher * 0.3 + 0.7);
    //cdata.r = mix(cdata.r, 0.0, fogatt(cdata.b));
    //   cdata.r = mix(cdata.r, 0.0, min(1.0, dst * 0.000005));
    vec3 scatcolor = mix(vec3(1.0), atmcolor * 0.1, 1.0 - diminisher) * 0.2;
    vec3 result = fresnel * mix(scatt, colorcloud, min(1.0, cdata.r * 1.1));// + scatcolor * pow(cdata.a, 12.0);
    
    return result;
   //return texture(atmScattTex, UV).rgb;
  // return texture(atmScattTex, UV).rgb;
  // eturn getatscatter(dir, normalize(SunDirection))+ sun(dir, normalize(SunDirection));
    //   return vec3(1) * cdata.a;
}

vec3 fisheye(){
    vec2 fullsp = UV * 2.0 - 1.0;
    fullsp = fullsp / sqrt(1.0 - length(fullsp) * 0.5);
    vec3 dir = normalize(reconstructCameraSpaceDistance(fullsp * 0.5 + 0.5, 1.0));
    return dir;
}

vec4 shade(){    
    vec3 color = texture(directTex, UV).rgb + texture(alTex, UV).rgb * (UseAO == 1 ? texture(aoxTex, UV).r : 1.0);
    
    

    if(length(currentData.normal) < 0.1){
        color = cloudsbydir(fisheye());
    } else color += cloudsbydir(currentData.normal);
    return vec4( color, 1.0);
}