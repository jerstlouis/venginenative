
uniform float CloudsFloor;
uniform float CloudsCeil;
uniform float CloudsThresholdLow;
uniform float CloudsThresholdHigh;
uniform float CloudsWindSpeed;
uniform vec3 CloudsOffset;
uniform float NoiseOctave1;
uniform float NoiseOctave2;
uniform float NoiseOctave3;
uniform float NoiseOctave4;
uniform float NoiseOctave5;
uniform float NoiseOctave6;
uniform vec3 SunDirection;
uniform float AtmosphereScale;
uniform float CloudsDensityScale;
uniform float CloudsDensityThresholdLow;
uniform float CloudsDensityThresholdHigh;
uniform float Time;
uniform float WaterWavesScale;
uniform float Rand1;
uniform float Rand2;


layout(binding = 18) uniform sampler2D cloudsCloudsTex;
layout(binding = 22) uniform sampler2D atmScattTex;
layout(binding = 20) uniform sampler2D cloudsRefShadowTex;

#include Shade.glsl
#include noise3D.glsl

#define iSteps 8
#define jSteps 6

struct Ray { vec3 o; vec3 d; };
struct Sphere { vec3 pos; float rad; };

bool shouldBreak(){
   vec2 position = UV * 2.0 - 1.0;
    if(length(position)> 1.0) return true;
    else return false;    
}

float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{ return dot(point - origin, normal) / dot(direction, normal); }

vec3 getViewDir(){
    //return normalize(reconstructCameraSpaceDistance(UV, 1.0));
    vec2 fdir = UV * 2.0 - 1.0;
    //if(length(fdir)> 0.99) fdir = normalize(fdir) * 0.99;
    float mixer = sqrt(max(0.0001, 1.0 - fdir.x*fdir.x - fdir.y * fdir.y));
    return vec3(fdir.x, mixer, fdir.y);
	
}
vec3 getViewDir2(){
    //return normalize(reconstructCameraSpaceDistance(UV, 1.0));
    vec2 fdir = (UV * 2.0 - 1.0);
   // if(length(fdir)> 0.99) {fdir = normalize(fdir) * 0.99;}
    float mixer = sqrt(max(0.0001, 1.0 - fdir.x*fdir.x - fdir.y * fdir.y));
    return normalize(vec3(fdir.x, ((mixer)), fdir.y));
	
}
vec2 reverseViewDir(){
 //   return UV;
    vec3 dir = normalize(reconstructCameraSpaceDistance(UV, 1.0));
    if(dir.y > 0){	
		vec2 fdir = normalize(dir.xz);
		float mixer = sqrt(1.0 - dot(dir, vec3(0,1,0)));
		return mix(vec2(0,0), fdir, mixer) * 0.5 + 0.5;
	}
    return vec2(0, 0);
}
vec2 reverseDir(vec3 dir){
 //   return UV;
    if(dir.y < 0.0) dir.y = - dir.y;
    vec2 fdir = normalize(dir.xz);
  //  dir.y = 1.0 - dir.y;
		float mixer = sqrt(1.0 - dot(dir, vec3(0,1,0)));
    fdir = mix(vec2(0,0), fdir, mixer);
    return fdir * 0.5 + 0.5;
}
vec2 reverseDir2(vec3 dir){
 //   return UV;
    if(dir.y < 0.0) dir.y = - dir.y;
    vec2 fdir = normalize(dir.xz);
  //  dir.y = 1.0 - dir.y;
    float mixer = sqrt( 1.0 - dir.y * dir.y) ;
    fdir = mix(vec2(0,0), fdir, mixer);
    return fdir * 0.5 + 0.5;
}

float planetradius = 6371e3;
Sphere planet = Sphere(vec3(0), planetradius);

float rsi2(in Ray ray, in Sphere sphere)
{
    vec3 oc = ray.o - sphere.pos;
    float b = 2.0 * dot(ray.d, oc);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float disc = b * b - 4.0 * c;
    if (disc < 0.0) return -1.0;
    float q = b < 0.0 ? ((-b - sqrt(disc))/2.0) : ((-b + sqrt(disc))/2.0);
    float t0 = q;
    float t1 = c / q;
    if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    if (t1 < 0.0) return -1.0;
    if (t0 < 0.0) return t1;
    else return t0; 
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    pSun = normalize(pSun);
    r = normalize(r);
    float iStepSize = rsi2(Ray(r0, r), Sphere(vec3(0), rAtmos)) / float(iSteps);
    float iTime = 0.0;
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);
    float iOdRlh = 0.0;
    float iOdMie = 0.0;
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));
    for (int i = 0; i < iSteps; i++) {
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);
        float iHeight = length(iPos) - rPlanet;
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;
        float jStepSize = rsi2(Ray(iPos, pSun), Sphere(vec3(0),rAtmos)) / float(jSteps);
        float jTime = 0.0;
        float jOdRlh = 0.0;
        float jOdMie = 0.0;
        float invshRlh = 1.0 / shRlh;
        float invshMie = 1.0 / shMie;
        for (int j = 0; j < jSteps; j++) {
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);
            float jHeight = length(jPos) - rPlanet;
            jOdRlh += exp(-jHeight * invshRlh) * jStepSize;
            jOdMie += exp(-jHeight * invshMie) * jStepSize;
            jTime += jStepSize;
        }
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;
        iTime += iStepSize;
    }
    return max(vec3(0.0), iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie));
}

vec3 sun(vec3 camdir, vec3 sundir, float gloss){
    float mult = sign(sundir.y);
    sundir = normalize(sundir * vec3(1.0, dot(sundir, vec3(0,1,0)), 1.0));
    sundir.y *= mult;
    float dt = max(0, dot(camdir, sundir));
    vec3 var1 = 1100.0 * mix((1.0 - smoothstep(0.003, mix(1.0, 0.0054, gloss), 1.0 - gloss * dt*dt*dt*dt*dt)) * vec3(10), pow(dt*dt*dt*dt*dt, 1256.0 * gloss) * vec3(10), max(0, dot(sundir, vec3(0,1,0)))) * (gloss * 0.9 + 0.1);
    vec3 var2 = vec3(1) * max(0, dot(camdir, sundir));
    return mix(var2, var1, gloss);
}

vec3 getAtmosphereForDirection(vec3 origin, vec3 dir, vec3 sunpos, float roughness){
   float levels = max(0, float(textureQueryLevels(atmScattTex)) - 2.0);
    float mx = log2(roughness*256+1)/log2(256);
    return textureLod(atmScattTex, reverseDir(dir), mx * levels).rgb;
}

vec3 getAtmosphereForDirectionReal(vec3 origin, vec3 dir, vec3 sunpos){
    return atmosphere(
        dir,           // normalized ray direction
        vec3(0,planetradius  ,0)+ origin,               // ray origin
        sunpos,                        // position of the sun
        64.0,                           // intensity of the sun
        planetradius,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(2.5e-6, 6.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        5e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
}

float hash( float n ){
    return fract(sin(n)*758.5453);
}

float noise( in vec3 x ){
    vec3 p = floor(x);
    vec3 f = fract(x); 
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
    mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

#define fbmsamples 2
#define fbm fbm_alu
#define ssnoise(a) (snoise(a) * 0.5 + 0.5)
float fbm_alu(vec3 p){
    //p *= 0.2;
	float a = 0.0;
    float w = NoiseOctave6;
    float sum = 0.0;
    //p += ssnoise(p);	
    //w *= 0.7;
   // p = p * 4.0;
    vec3 px = p;
    px *= 0.5;
    
    a += ssnoise(px * NoiseOctave5) * w;	
    sum += w;
    px = px * 11.0 * w;
    w *= 0.1;
	
    //px += noise(px);
    w = 0.2;
    px = p * 4.0;
    
    a += noise(px + noise(px + Time * 0.1)) * w;	
    sum += w;
    px = px * 5.0;
    
    w = 0.1;
    a += noise(px + noise(px + Time * 0.1)) * w;	
    sum += w;
    
	return a / sum;
}

float edgeclose = 0.0;
float cloudsDensity3D(vec3 pos){
    vec3 ps = pos +CloudsOffset;// + wtim;
    //ps.xz *= CloudsDensityScale;
   // float density = 1.0 - fbm(ps * 0.05 + fbm(ps * 0.5));
    float density = 1.0 - fbm(ps * 0.05);
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh,  density);
    //edgeclose = pow(1.0 - abs(CloudsThresholdLow - density), CloudsThresholdHigh * 113.0);
    float mid = (CloudsThresholdLow + CloudsThresholdHigh) * 0.5;
    edgeclose = pow(1.0 - abs(mid - density), 16.0);
    return  init;
} 

float rand2s(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}
float rand2sTime(vec2 co){
    co *= Time;
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

Sphere sphere1;
Sphere sphere2;

float weightshadow = CloudsDensityScale;
float internalmarchconservativeCoverageOnly(vec3 p1, vec3 p2){
    float iter = 0.0;
    const float stepcount = 3;
    const float stepsize = 1.0 / stepcount;
    float rd = rand2sTime(UV);
    float coverageinv = 1.0;
    
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, rd);
        float clouds = cloudsDensity3D(pos * 0.01);
        coverageinv -= clouds * weightshadow;
        iter += stepsize;
        rd = rand2sTime(UV * iter);
    }
    return pow(clamp(coverageinv, 0.0, 1.0), 3.0);
}

float hash1x = 0.0;
vec3 randdir(){
    float x = rand2s(UV * hash1x);
    hash1x += 34.5451;
    float y = rand2s(UV * hash1x);
    hash1x += 3.62123;
    float z = rand2s(UV * hash1x);
    hash1x += 8.4652344;
    return (vec3(
        x, y, z
    ) * 2.0 - 1.0);
}

float intersectplanet(vec3 pos){
    Ray r = Ray(vec3(0,planetradius ,0) +pos, normalize(SunDirection));
    float hitceil = rsi2(r, planet);
    return max(0.0, -sign(hitceil));
}
float getAOPos(vec3 pos){
    float a = 0;
        vec3 dir = normalize(SunDirection + randdir() * 0.1);
        Ray r = Ray(vec3(0,planetradius ,0) +pos, dir);
        float hitceil = rsi2(r, sphere1);
        vec3 posceil = pos + dir * hitceil;
        a +=internalmarchconservativeCoverageOnly(pos, posceil);
    return a;
}
float directshadow(vec3 pos){
    float a = 0;
        vec3 dir = normalize(randdir());
        Ray r = Ray(vec3(0,planetradius ,0) +pos, dir);
        float hitceil = rsi2(r, sphere2);
        vec3 posceil = pos + dir * hitceil;
        a +=internalmarchconservativeCoverageOnly(pos, posceil);
    return a;// * intersectplanet(pos);
}
float godray(vec3 pos){
    float a = 0;
        vec3 dir = normalize(SunDirection);
        Ray r = Ray(vec3(0,planetradius ,0) +pos, dir);
        float hitceil = rsi2(r, sphere2);
        vec3 posceil = pos + dir * hitceil;
        float hitceil2 = rsi2(r, sphere1);
        vec3 posceil2 = pos + dir * hitceil2;
        a +=clamp(internalmarchconservativeCoverageOnly(posceil2, posceil), 0.0, 1.0);
    return a;//  * intersectplanet(pos);
}

vec4 internalmarchconservative(vec3 p1, vec3 p2){
    const float stepcount = 6;
    const float stepsize = 1.0 / stepcount;
    float rd = fract(rand2sTime(UV) + hash(Time)) * stepsize;
    hash1x = rand2s(UV * vec2(Time, Time));
    float c = 0.0;
    float w = 0.0;
    float coverageinv = 1.0;
    vec3 pos = vec3(0);
    float clouds = 0.0;
    float godr = 0.0;
    float godw = 0.0;
    float iter = 0.0;
    for(int i=0;i<stepcount;i++){
        pos = mix(p1, p2, rd + iter);
        clouds = cloudsDensity3D(pos * 0.01);// * (1.0 - rd);
        pos = mix(vec3(0,1,0), p2, iter + rd);
        godr += godray(pos) * stepsize;
      //  c += edgeclose * getAOPos(scale, pos);
      //  w += edgeclose;
        c += edgeclose * getAOPos(pos);
        w += edgeclose;
        coverageinv -= clouds * 3.0;
        iter += stepsize;
        //rd = fract(rd + iter * 124.345345);
    }

    if(w > 0.01) c /= w; else c = 1.0;

    //= clamp(pow(c * 1.1, 2.0), 0.0, 1.0);
    return vec4(1.0 - pow(clamp(coverageinv, 0.0, 1.0), 3.0), c, 0.0, godr);
}
vec4 raymarchCloudsRay(){
    vec3 viewdir = getViewDir();
    vec3 atmorg = vec3(0,planetradius ,0);  
    
    Ray r = Ray(atmorg, viewdir);
    
    sphere1 = Sphere(vec3(0), planetradius + CloudsFloor);
    sphere2 = Sphere(vec3(0), planetradius + CloudsCeil);
    
    float hitfloor = rsi2(r, sphere1);
    float hitceil = rsi2(r, sphere2);
    return internalmarchconservative(viewdir * hitfloor, viewdir * hitceil);
}
