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
float roughtomipmap(float roughness, sampler2D txt){
    //roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(txt)) - 2.0);
    float mx = log2(roughness*512+1)/log2(512);
    return mx * levels;
}
vec4 smartblur(vec3 dir, float roughness){
    vec2 uv = reverseDir(dir);
    float levels = max(0, float(textureQueryLevels(cloudsCloudsTex)) - 2.0);
    float mx = log2(roughness*512+1)/log2(512);
    float mlvel = mx * levels;
    return textureLod(cloudsCloudsTex, uv, mlvel).rgba;
    vec4 centerval = vec4(0);
    float center = textureLod(cloudsCloudsTex, uv, mlvel).r;
    float aoc = 0;
    float blurrange = 0.003;
    for(int i=0;i<64;i++){
        vec2 rdp = randpoint2() * blurrange;
        float there = textureLod(cloudsCloudsTex, uv + rdp, mlvel).r;
        float w = pow( 1.0 - abs(there - center), 32.0);
        centerval += w * textureLod(cloudsCloudsTex, uv + rdp, mlvel).rgba;
        aoc += w;
    }
    return aoc == 0 ? textureLod(cloudsCloudsTex, uv, mlvel).rgba : centerval / aoc;
}


float fogatt(float dist){
    dist *= 0.000015;
    return min(1.0, (dist * dist) );
}

#define wassnoise(a) pow((snoise(a) * 0.5 + 0.5), 1.0)
vec3 octaveN(vec2 a, float esp){
    vec2 zxpos = a * esp;
    float h1 = snoise(vec3(zxpos.xy, Time * 0.1));
    float h2 = wassnoise(vec3(zxpos.xy, Time * 0.1));
    float h3 = snoise(vec3(zxpos.xy, Time * 0.1));
    return normalize(vec3(h1, h2, h3));
}

float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{ return dot(point - origin, normal) / dot(direction, normal); }
#define ssin(a) (smoothstep(0,3.1415,a*3.1415) * 2.0 - 1.0) 
#define snoisesin(a) pow(1.0 - (abs(noise(a) - 0.5) * 2.0), 4.0)
float heightwater(vec2 pos){
    pos *= 0.01;
   // pos += noise(vec3(pos * 0.4, 0)) * 0.4;
    float res = 0.0;
    float w = 0.0;
    float wz = 0.5;
    float tmod = 0.1;
    for(int i=0;i<4;i++){
        float t = tmod * Time;
        res += wz * snoisesin(vec3(pos + t, t));
        res += wz * snoisesin(vec3(pos - t, -t));
         w += wz;
         w += wz;
         wz *= 0.4;
        pos *= 2.1;
      //  pos += t;
        tmod *= 1.4;
    }
    return res / w;
}
float heightwaterd(vec2 pos){
    pos *= 0.01;
   // pos += noise(vec3(pos * 0.4, 0)) * 0.4;
    float res = 0.0;
    float w = 0.0;
    float wz = 0.5;
    float tmod = 0.1;
    for(int i=0;i<7;i++){
        float t = tmod * Time;
         if(i>6){wz = 0.01;pos += 2 * snoisesin(vec3(pos + t, t));}
        res += wz * snoisesin(vec3(pos + t, t));
        res += wz * snoisesin(vec3(pos - t, -t));
         w += wz;
         w += wz;
         wz *= 0.4;
        pos *= 2.1;
        //pos += t;
        tmod *= 1.4;
    }
    return res / w;
}

#define waterdepth 22.0
vec3 normalx(vec3 pos, float e){
    vec2 ex = vec2(e, 0);
    vec3 a = vec3(pos.x, heightwaterd(pos.xz) * waterdepth, pos.z);    
    vec3 b = vec3(pos.x + e, heightwaterd(pos.xz + ex.xy) * waterdepth, pos.z);       
    vec3 c = vec3(pos.x, heightwaterd(pos.xz + ex.yx) * waterdepth, pos.z + e);      
    vec3 normal = normalize(cross((b-a), (c-a)));
    return -normalize(normal);// + 0.1 * vec3(snoise(normal), snoise(-normal), snoise(normal.zyx)));
}
    
vec3 raymarchwater(vec3 upper, vec3 lower){
    float stepsize = 1.0 / 12.0;
    float iter = 0;
    for(int i=0;i<12 + 1;i++){
        vec3 pos = mix(upper, lower, iter);
        if(heightwater(pos.xz) > 1.0 - iter) {
           // return normalx(pos, 1);
            iter -= stepsize;
            float stepsize = stepsize / 8.0;
            for(int z=0;z<8 + 1;z++){
                vec3 pos = mix(upper, lower, iter);
                if(heightwater(pos.xz) > 1.0 - iter) {
                    return normalx(pos, 1);
                }
                iter += stepsize;
            }
        }
        iter += stepsize;
    }
    return vec3(0,1,0);
}
vec3 raymarchwaterLOW1(vec3 upper, vec3 lower){
    float stepsize = 1.0 / 8.0;
    float iter = 0;
    for(int i=0;i<8 + 1;i++){
        vec3 pos = mix(upper, lower, iter);
        if(heightwater(pos.xz) > 1.0 - iter) {
           // return normalx(pos, 1);
            iter -= stepsize;
            float stepsize = stepsize / 4.0;
            for(int z=0;z<4 + 1;z++){
                vec3 pos = mix(upper, lower, iter);
                if(heightwater(pos.xz) > 1.0 - iter) {
                    return normalx(pos, 1);
                }
                iter += stepsize;
            }
        }
        iter += stepsize;
    }
    return vec3(0,1,0);
}

vec3 raymarchwaterLOW2(vec3 upper, vec3 lower){
    float stepsize = 1.0 / 4.0;
    float iter = 0;
    for(int i=0;i<4 + 1;i++){
        vec3 pos = mix(upper, lower, iter);
        if(heightwater(pos.xz) > 1.0 - iter) {
           // return normalx(pos, 1);
            iter -= stepsize;
            float stepsize = stepsize / 3.0;
            for(int z=0;z<3 + 1;z++){
                vec3 pos = mix(upper, lower, iter);
                if(heightwater(pos.xz) > 1.0 - iter) {
                    return normalx(pos, 1);
                }
                iter += stepsize;
            }
        }
        iter += stepsize;
    }
    return vec3(0,1,0);
}
vec3 raymarchwaterLOW3(vec3 upper, vec3 lower){
    return normalx(upper, 1);
}

#define LOD1 320.0
#define LOD2 620.0
#define LOD3 12500.0
        
vec3 cloudsbydir(vec3 dir){
    float fresnel = 1.0;
    float dst = 0;
    float roughness = 0.0;
    if(dir.y < 0.0){
        
        vec3 atmorg = vec3(0, planetradius, 0) + CameraPosition;  
        Ray r = Ray(atmorg, dir);
        float planethit = intersectPlane(CameraPosition, dir, vec3(0), vec3(0,1,0));
        float planethit2 = intersectPlane(CameraPosition + vec3(0, waterdepth, 0), dir, vec3(0), vec3(0,1,0));    
        vec3 newpos = atmorg + dir * planethit;
        vec3 newpos2 = atmorg + dir * planethit2;
        float flh1 = planethit * 0.0005;
        roughness = 1.0 - smoothstep(0.0, 22.0, sqrt(sqrt(flh1)));
        roughness = 1.0 - pow(roughness, 164.0);
        dst = planethit;
        vec3 n = vec3(0,1,0);
        float w = 0;
        float w2 = 1.0;
        float mult = 0.001;
        for(int i=0;i<1;i++){
            n = normalize(n*7.0 + w2 * octaveN((atmorg + dir * planethit).xz , mult));
            w += w2;
            mult *= 2.1;
            w2 *= 0.4;
        }
        if(planethit >= LOD3) n = raymarchwaterLOW3(newpos, newpos2);
        else if(planethit < LOD3 && planethit >= LOD2) n = raymarchwaterLOW2(newpos, newpos2);
        else if(planethit < LOD2 && planethit >= LOD1) n = raymarchwaterLOW1(newpos, newpos2);
        else n = raymarchwater(newpos, newpos2);
        //roughness = roughness * 0.8 + 0.2;
        n = normalize(mix(n, vec3(0,1,0), roughness));
        roughness *= 0.1;
        dir = normalize(reflect(dir, n));
        fresnel = fresnel_again(vec3(0.04), n, dir, 1.0);
      //  dir = normalize(mix(dir, vec3(0,1,0), roughness));
        //dir = normalize(reflect(dir, vec3(0,1,0)));
    } else {
        roughness = pow(1.0 - (dir.y), 128.0);
    }
   // roughness = 0;
    vec4 cdata = smartblur(dir, roughness).rgba;
    vec3 scatt = textureLod(atmScattTex, reverseDir(dir), roughtomipmap(roughness, atmScattTex)).rgb + sun(dir, normalize(SunDirection), 1.0 - roughness);
    vec3 skydaylightcolor = vec3(0.23, 0.33, 0.48);
    vec3 atmcolor = getAtmosphereForDirection(vec3(0), normalize(SunDirection), normalize(SunDirection)) + vec3(1);
    vec3 atmcolor1 = getAtmosphereForDirection(vec3(0), vec3(0,1,0), normalize(SunDirection));
    float diminisher = max(0, dot(normalize(SunDirection), vec3(0,1,0)));
    float diminisher_absolute = dot(normalize(SunDirection), vec3(0,1,0)) * 0.5 + 0.5;
    float dimpow = 1.0 -  diminisher;
    vec3 shadowcolor = mix(skydaylightcolor, skydaylightcolor * 0.05, dimpow);
    vec3 litcolor = mix(vec3(10.0), vec3(0.3) * vec3((1.0 - diminisher) * 1.5, dimpow * 0.2, 0.0), 1.0 - diminisher);
    vec3 colorcloud = mix(shadowcolor, litcolor, cdata.g ) ;//* (diminisher * 0.3 + 0.7);
    //cdata.r = mix(cdata.r, 0.0, fogatt(cdata.b));
    //   cdata.r = mix(cdata.r, 0.0, min(1.0, dst * 0.000005));
    vec3 scatcolor = mix(vec3(1.0), atmcolor * 0.1, 1.0 - diminisher) * 0.2;

    vec3 result = fresnel * mix(scatt, colorcloud, min(1.0, cdata.r * 1.1));// + diminisher_absolute * (0.5 * pow(diminisher, 8.0) + 0.5) * litcolor * ((pow(1.0 - diminisher, 24.0)) * 0.9 + 0.1) * pow(cdata.a * 1.0, 2.0);
    
    return result;
   //return texture(atmScattTex, UV).rgb;
  // return texture(atmScattTex, UV).rgb;
  // eturn getatscatter(dir, normalize(SunDirection))+ sun(dir, normalize(SunDirection));
     //  return vec3(1) * cdata.r;
}

vec3 fisheye(){
    vec2 fullsp = UV * 2.0 - 1.0;
    fullsp = fullsp / sqrt(1.0 - length(fullsp) * 0.71);
    fullsp *= 2.0;
    vec3 dir = normalize(reconstructCameraSpaceDistance(fullsp * 0.5 + 0.5, 1.0));
    
    //vec3 dir = normalize(reconstructCameraSpaceDistance(UV, 1.0));
    //vec3 dir = normalize(reconstructCameraSpaceDistance((fullsp * 3.0) * 0.5 + 0.5, 1.0));
    return dir;
}

vec4 shade(){    
    vec3 color = texture(directTex, UV).rgb + texture(alTex, UV).rgb * (UseAO == 1 ? texture(aoxTex, UV).r : 1.0);
    
    

    if(length(currentData.normal) < 0.1){
        color = cloudsbydir(fisheye());
    } else color += cloudsbydir(currentData.normal);
    return vec4( color, 1.0);
}