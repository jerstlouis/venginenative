
uniform float CloudsFloor;
uniform float CloudsCeil;
uniform float CloudsThresholdLow;
uniform float CloudsThresholdHigh;
uniform float CloudsWindSpeed;
uniform vec3 CloudsOffset;
uniform vec3 SunDirection;
uniform float AtmosphereScale;
uniform float CloudsDensityScale;
uniform float CloudsDensityThresholdLow;
uniform float CloudsDensityThresholdHigh;
uniform float Time;
uniform float WaterWavesScale;


layout(binding = 18) uniform sampler2D cloudsCloudsTex;
layout(binding = 19) uniform sampler2D atmScattTex;
layout(binding = 20) uniform sampler2D cloudsRefShadowTex;

#include Shade.glsl
#include noise3D.glsl

#define iSteps 12
#define jSteps 6

struct Ray { vec3 o; vec3 d; };
struct Sphere { vec3 pos; float rad; };

bool shouldBreak(){
   vec2 position = UV * 2.0 - 1.0;
    if(length(position)> 1.0) return true;
    else return false;    
}

vec3 getViewDir(){
    //return normalize(reconstructCameraSpaceDistance(UV, 1.0));
    vec2 fdir = UV * 2.0 - 1.0;
    if(length(fdir)<= 1.0){	
		float mixer = sqrt(1.0 - fdir.x*fdir.x - fdir.y * fdir.y);
		return vec3(fdir.x, mixer, fdir.y);
	}
    return vec3(0, -1, 0);
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
    float mixer = sqrt(1.0 - dot(dir, vec3(0,1,0)));
    return mix(vec2(0,0), fdir, mixer) * 0.5 + 0.5;
}

float planetradius = 6371e3;
Sphere planet = Sphere(vec3(0), planetradius);

float minhit = 0.0;
float maxhit = 0.0;
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
    minhit = min(t0, t1);
    maxhit = max(t0, t1);
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

vec3 sun(vec3 camdir, vec3 sundir){
    float dt = max(0, dot(camdir, sundir));
    return mix((1.0 - smoothstep(0.003, 0.0054, 1.0 - dt*dt*dt*dt*dt)) * vec3(10), pow(dt*dt*dt*dt*dt, 256.0) * vec3(10), max(0, dot(sundir, vec3(0,1,0))));
}

vec3 getAtmosphereForDirection(vec3 origin, vec3 dir, vec3 sunpos){
    return atmosphere(
        dir,           // normalized ray direction
        vec3(0,planetradius  ,0)+ origin,               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        planetradius,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(2.5e-6, 6.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
}


vec3 atmcolor = vec3(0);
vec3 atm(vec3 sunpos){
    float mult = 1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
    vec3 vdir = getViewDir();
    vec3 colorSky = getAtmosphereForDirection(vec3(0,1,0) * AtmosphereScale, vdir, sunpos);
   // atmcolor = getAtmosphereForDirection(vec3(0), normalize(sunpos) + vec3(0, 0.15, 0), sunpos);
   // vec3 colorObjects = diffused * (1.0 - (1.0 / (textureLod(mrt_Distance_Bump_Tex, UV, 0).r * 0.001 + 1.0)));
    return colorSky;// + colorObjects * (1.0 - mult);
}

//float iter = 1.03423;
float hash2(float n){
   // iter = fract(n*17.131783223);
    return fract(abs((n+165.23123119)*17.131783223));
}

float hash( float n ){
   // return fract(mod(n, 6.2526)*758.5453);
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
float pn(vec3 p) {
   vec3 i = floor(p);
   vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
   vec3 f = cos((p-i)*3.1415)*(-.5) + .5;
   a = mix(sin(cos(a)*a), sin(cos(1.+a)*(1.+a)), f.x);
   a.xy = mix(a.xz, a.yw, f.y);
   return mix(a.x, a.y, f.z);
}
/*
float fbm( vec3 p ){
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f -= 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*4.04;
    f += 0.03500*noise( p ); p = p*4.01;
    f += 0.01250*noise( p+(Time * CloudsWindSpeed * 0.4) ); 
    return f/0.984375;
}*/

#define wind vec3(-1.0, 0.0, 0.0)
#define fbmsamples 5
#define fbm fbm_alu
//#define fbm fbm_tex
float noise2x(vec3 p) //Thx to Las^Mercury
{
	vec3 i = floor(p);
	vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
	vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z) * 0.5 + 0.5;
}
float fbm_alu(vec3 p){
    p *= 0.1;
	float a = 0.0;
    float w = 1.0;
	for(int i=0;i<fbmsamples;i++){
		a += noise(p) * w;	
        w *= 0.5;
		p = p * 4.0;
	}
	return a;
}
float fbm_alu2(vec3 p){
    //p *= 0.1;
   return noise(p * 0.06)*.75 + noise2x(p*3.0)*.25;// + noise2x(p*25.0)*.125;// + noise2x(p*100.0 + wind * Time * 0.01)*.125;
}

float fbm_new(vec3 p) {
   return pn(p*.06125)*.5 + pn(p*.125)*.25 + pn(p*.25)*.125;
}
vec3 wtim =vec3(0);

float edgeclose = 0.0;
float cloudsDensity3D(vec3 pos){
    vec3 ps = pos +CloudsOffset;// + wtim;
    float density = 1.0 - fbm(ps * 0.05 + fbm(ps * 1.5));
   // density *= smoothstep(CloudsDensityThresholdLow, CloudsDensityThresholdHigh, 1.0 - fbm(ps * 0.005 * CloudsDensityScale));
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh,  density);
    //edgeclose = pow(1.0 - abs(CloudsThresholdLow - density), CloudsThresholdHigh * 113.0);
    float mid = (CloudsThresholdLow + CloudsThresholdHigh) * 0.5;
    edgeclose = pow(1.0 - abs(mid - density), 16.0);
    return  init;
}

float rand2s(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}


Sphere sphere1;
Sphere sphere2;

vec3 sundir = normalize(SunDirection);
vec3 viewdirglob = vec3(0,1,0);
vec3 outpoint = vec3(0);
float color = 0.0;

float internalmarchconservativeCoverageOnly(float scale, vec3 p1, vec3 p2){
    float iter = 0.0;
    float span = CloudsCeil - CloudsFloor;
    const float stepcount = 3;
    const float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV * vec2(Time, Time)) * stepsize;
    float start = planetradius + CloudsFloor;
    const float invspan = 1.0 / span;
    float coverageinv = 1.0;
    
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, iter + rd);
        float height = length(vec3(0,planetradius ,0) + pos);
        float spx = (height - start) * invspan;
        float clouds = cloudsDensity3D(pos * 0.01 * scale);// * (1.0 - smoothstep( 0.3, 0.5, abs(spx - 0.5) ) );
        coverageinv -= clamp(clouds, 0.0, 1.0)  * 0.5;
        coverageinv = max(0.0, coverageinv);
        if(coverageinv <= 0.01) break;
       // if(coverageinv < 0.04) return 1.0;
        iter += stepsize;
    }
    return clamp(coverageinv, 0.0, 1.0);
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
vec3 fukpos = vec3(0);
float getAOPos(float scale, vec3 pos){
    float a = 0;
        vec3 dir = normalize(SunDirection + randdir() * 0.2);
        Ray r = Ray(vec3(0,planetradius ,0) +pos, dir);
        float hitceil = rsi2(r, sphere2);
        vec3 posceil = pos + dir * hitceil;
        a +=internalmarchconservativeCoverageOnly(scale, pos, posceil);
    return a ;
}
vec3 startpos; 
vec3 ssdir;
vec4 internalmarchconservative(float scale, vec3 p1, vec3 p2){ 
    startpos = p1;
    ssdir = normalize(p2 - p1);
    float iter = 0.0;
    float span = CloudsCeil - CloudsFloor;
    // float stepcount = mix(300, 64, span / distance(p1, p2));
    const float stepcount = 5;
    const float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV * vec2(Time, Time)) * stepsize;
    hash1x = rand2s(UV * vec2(Time, Time));
    float shadow = 0.0;
    //float outpointdst = 1.0;
    float w = 0.0;
    const float invspan = 1.0 / span;
    float start = planetradius + CloudsFloor;
    
    float c = 0.0;
    float coverageinv = 1.0;
    float depth = 0.0;
    float posc = 0.0;
    float poscw = 0.0;
    vec3 pos = vec3(0);
    for(int i=0;i<stepcount;i++){
        pos = mix(p1, p2, iter + rd);
        float height = length(vec3(0,planetradius ,0) + pos);
        float spx = (height - start) * invspan;
        float clouds = cloudsDensity3D(pos * 0.01 * scale);// * (1.0 - smoothstep( 0.3, 0.5, abs(spx - 0.5) ) );
       // if(edgeclose > 0.02){
            c += edgeclose * getAOPos(scale, pos);
            w += edgeclose;
       // } 
        coverageinv *= 1.0 - clamp(clouds, 0.0, 1.0) * 1;
        coverageinv = max(0.0, coverageinv);
        if(coverageinv <= 0.01) break;
        iter += stepsize;
    }
    float iter1 = posc / (poscw + 0.01);
    vec3 psc = mix(p1, p2, iter1);
    
    Ray r = Ray(vec3(0,planetradius ,0) +psc, normalize(SunDirection));
    float hitceil = rsi2(r, sphere2);
    float covershadw = 1.0 ;//- internalmarchconservativeCoverageOnly(scale, psc, psc + r.d * hitceil);
    if(w > 0.01) c /= w; else c = 1.0;
    // outpoint = mix(p1, p2, outpointdst);
    // if(distance(outpoint, p1) > 50000) outpoint = p1 + normalize(outpoint - p1) * 50000;
    float dst =  length(p1);
    return vec4(1.0 - clamp(coverageinv, 0.0, 1.0), c, dst, 1.0);
}
#define intersects(a) (a >= 0.0)
vec4 raymarchCloudsRay(vec3 campos, vec3 viewdir, float scale, float floord, float ceiling){
    viewdirglob = viewdir;
    vec3 atmorg = vec3(0,planetradius ,0) + campos;  
    Ray r = Ray(atmorg, viewdir);
    float height = length(atmorg);
    float cloudslow = planetradius + floord;
    float cloudshigh = planetradius + ceiling;
    
    sphere1 = Sphere(vec3(0), cloudslow);
    sphere2 = Sphere(vec3(0), cloudshigh);
    
    float planethit = rsi2(r, planet);
    float hitfloor = rsi2(r, sphere1);
    float floorminhit = minhit;
    float floormaxhit = maxhit;
    float hitceil = rsi2(r, sphere2);
    float ceilminhit = minhit;
    float ceilmaxhit = maxhit;
    float dststart = 0.0;
    float dstend = 0.0;
    float coverageinv = 1.0;
    vec4 res = vec4(0);
    if(height < cloudslow){
        if(planethit < 0){
            res = internalmarchconservative(scale, campos + viewdir * hitfloor, campos + viewdir * hitceil);
        }
    } else if(height >= cloudslow && height < cloudshigh){
        if(intersects(hitfloor)){
            res = internalmarchconservative(scale, campos, campos + viewdir * floorminhit);
            if(!intersects(planethit)){
                vec4 r2 = internalmarchconservative(scale, campos + viewdir * floormaxhit, campos + viewdir * ceilmaxhit);
                res.g = mix(r2.g, res.g, res.r);
                res.b = mix(r2.b, res.b, res.r);
                res.r =1.0 - (1.0 - res.r) * (1.0 - r2.r);
            }
        } else {
            res = internalmarchconservative(scale, campos, campos + viewdir * hitceil);
        }
    } else if(height > cloudshigh){
        if(!intersects(hitfloor) && !intersects(hitceil)){
            res = vec4(0);
        } else if(!intersects(hitfloor)){
            res = internalmarchconservative(scale, campos + viewdir * minhit, campos + viewdir * maxhit);
        } else {
            res = internalmarchconservative(scale, campos + viewdir * ceilminhit, campos + viewdir * floorminhit);
        }
    }
    
    return res;
}
vec4 getCloudDensityForDirection(vec3 origin, vec3 dir, float scale, float floord, float ceiling){
    //wtim = wind * Time * CloudsWindSpeed;
    return raymarchCloudsRay(origin, dir, scale, floord, ceiling);
}
float outcloudsref = 0.0;
vec4 raymarchCloudsConservative(float scale, float floord, float ceiling){
    vec3 campos = vec3(0,1,0) * AtmosphereScale;
    vec3 viewdir = getViewDir();
    return getCloudDensityForDirection(campos, viewdir, scale, floord, ceiling);
}


float blurgray(sampler2D tex, int kernel){
    ivec2 pxsz = textureSize(tex, 0);
    ivec2 coords = ivec2(UV * pxsz);
    float accum = 0.0;
    for(int i=-kernel;i<kernel;i++){
        for(int g=-kernel;g<kernel;g++){
            accum += texelFetch(tex, coords + ivec2(i, g), 0).r;
        }
    }
    return accum / (kernel * 2 * kernel * 2);
}
vec3 atmcolor1;
vec3 atmx2(vec3 sunpos, float shadowvalue){

    //return mix(vec3(1.0), 1.0 * scatter2,1.0 - texture(cloudsCloudsTex, UV).y);
    //return mix(vec3(3.0), scatter2 * 3.0, 1.0 - texture(cloudsCloudsTex, UV).y);
    vec3 cmix = mix(vec3(1.0), atmcolor, 1.0 - max(0, dot(sunpos, vec3(0,1,0))));
    vec3 cfla = mix(atmcolor1, vec3(0.01),  1.0 - max(0, dot(sunpos, vec3(0,1,0))));
    cmix *= cfla;
    float shadowmult = 1000.0 / (CloudsCeil - CloudsFloor);
    return mix(atmcolor, vec3(0.01), shadowvalue);
}

float stars(vec3 viewdir){
    //vec3 viewdir = ;
    float a = viewdir.x;
    float b = viewdir.y;
    float ns = rand2s(vec2(a,b));
    return pow(smoothstep(0.997, 1.0, ns), 3.0) * fbm(vec3(a*100.0, b*100.0, Time*2.0));
}

vec4 CloudsGetCloudsCoverageShadow(){
    vec4 r = raymarchCloudsConservative(1, CloudsFloor, CloudsCeil);
    return r;
}
float reflectionCoefficent = 1.0;
vec3 shadeWater(vec3 campos, vec3 normal, vec3 viewdir, vec3 worldPos, vec3 atmcolorx){
    vec3 cmix = mix(vec3(1.0), atmcolorx, 1.0 - max(0, dot(normalize(SunDirection), vec3(0,1,0))));
    vec3 cfla = mix(cmix, vec3(0.01),  1.0 - max(0, dot(normalize(SunDirection), vec3(0,1,0))));
  //  cmix *= cfla * smoothstep(0.0, 0.1, max(0, dot(normalize(SunDirection), vec3(0,1,0))));
    float fresnel = fresnel_again(vec3(0.04), normal, viewdir, 0.00);
    
    vec3 radiance = reflectionCoefficent * shade(campos, vec3(fresnel), normal, worldPos, worldPos + sundir * 10, cmix, 0.10, true);    
    
    vec3 difradiance = shadeDiffuse(campos, vec3(0.0, 0.06, 0.1), normal, worldPos, worldPos + sundir * 10, cmix, 1, true);
    return difradiance * (1.0 - fresnel);
}


float sns(vec2 p, float scale, float tscale){
    return snoise(vec3(p.x*scale, p.y*scale, Time * tscale * 0.5));
}
float getwater( vec2 position ) {
    vec3 p = vec3(position, Time);
    p *= 0.01;
	float a = 0.0;
    float w = 1.0;
	for(int i=0;i<5;i++){
        w *= 0.5;
		a += snoise(p + wind * Time * w * 0.1) * w;	
		p = p * 4.0;
	}
	return a;

}
vec3 getwatern( vec2 position ) {

    vec3 a = vec3(position, getwater(position));
    vec2 m = vec2(0.01, 0.0);
    vec3 a1 = vec3(position - m.xy, getwater(position - m.xy));
    vec3 a2 = vec3(position - m.yx, getwater(position - m.yx));
    return normalize(cross(a1 - a, a2 - a)).xzy;
}
vec3 getwaterna( vec2 position ) {

    vec2 m = vec2(0.001, 0.0);
    float a = getwater(position);
    float b = getwater(position - m.xy);
    float c = getwater(position - m.yx);
    return normalize(vec3(a - b,1,a-c));
}
vec2 distortUV(vec2 uv, vec2 displ){
	return uv - vec2(displ) * 0.1;
}

vec3 ApplyAtmosphereJustClouds(vec3 color, vec2 cloudsData){
    return vec3(cloudsData.y * cloudsData.x);
    color += atm(normalize(SunDirection));
    vec3 atmcolor1 = atmx2(normalize(SunDirection), cloudsData.y);
    color += stars(getViewDir());
    color += sun(getViewDir(), normalize(SunDirection));
    return mix(color, atmcolor1, cloudsData.r);
}

vec3 AtmScatt(vec3 origin, vec3 viewdir){
  //return mix(color, vec3(1), cloudsData.r);
   // float mult = 1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
    //if(mult < 0.5) return vec3(0);
    vec3 campos = origin * AtmosphereScale;
    vec3 atmorg = vec3(0, planetradius, 0) + campos;  
    float height = length(atmorg);
    Ray r = Ray(atmorg, viewdir);
    float planethit = rsi2(r, planet);
    vec3 hitpos = atmorg + viewdir * planethit;
    vec3 realhpos = campos + viewdir * planethit;
    vec3 rposh = realhpos;
    vec3 hitnorm = normalize(hitpos);
    vec3 color = vec3(0);
    
        color += getAtmosphereForDirection(origin * AtmosphereScale, viewdir, normalize(SunDirection));
    
    return color;
}

vec4 CloudsRefShadow(){
    //return mix(color, vec3(1), cloudsData.r);
    vec3 campos = vec3(0,1,0) * AtmosphereScale;
    vec3 viewdir = getViewDir();
    vec3 atmorg = vec3(0, planetradius, 0) + campos;  
    float height = length(atmorg);
    Ray r = Ray(atmorg, viewdir);
    float planethit = rsi2(r, planet);
    vec3 hitpos = atmorg + viewdir * planethit;
    vec3 realhpos = campos + viewdir * planethit;
    vec3 rposh = realhpos;
    realhpos.y = 4.1;
    vec3 hitnorm = normalize(hitpos);
    vec4 color = vec4(0);
    if(planethit > 0){
        vec3 newn = normalize(hitnorm);
        vec3 dreflected = reflect(viewdir, newn);
        if(dot(dreflected, newn) < 0) dreflected = normalize(reflect(dreflected, newn));
        vec3 reflected = getAtmosphereForDirection(rposh, normalize(dreflected), normalize(SunDirection));
        vec2 res2 = getCloudDensityForDirection(realhpos, normalize(dreflected), 1.0, CloudsFloor, CloudsCeil).rg;
        vec2 res1 = getCloudDensityForDirection(realhpos, normalize(SunDirection), 1.0, CloudsFloor, CloudsCeil).rg;
        color = vec4(res2.x, res2.y, res1.x, res1.y);
    } 
    return color;
}

vec3 ApplyAtmosphere(vec3 color, vec2 cloudsData){
    //return texture(cloudsRefShadowTex, UV).rgg;
    vec3 campos = vec3(0,1,0) * AtmosphereScale;
    vec3 viewdir = getViewDir();
    vec3 atmorg = vec3(0, planetradius, 0) + campos;  
    float height = length(atmorg);
    Ray r = Ray(atmorg, viewdir);
    float planethit = rsi2(r, planet);
    vec3 hitpos = atmorg + viewdir * planethit;
    vec3 realhpos = campos + viewdir * planethit;
    vec3 rposh = realhpos;
    realhpos.y = 4.1;
    vec3 hitnorm = normalize(hitpos);
    vec3 atmcolor1 = vec3(0);
    if(planethit > 0){
        vec3 atmxa = texture(atmScattTex, UV).rgb;
        atmcolor1 = atmx2(normalize(SunDirection), cloudsData.y);
        float precisionw = 0.03;
        float precisionsp = 0.16;
        /*float waterh = getwatern(realhpos.xz * precisionw);
        float waterh2 = getwatern(realhpos.xz * precisionw + vec2(precisionsp, 0.0));
        float waterh3 = getwatern(realhpos.xz * precisionw + vec2(0.0, precisionsp));
        vec3 p1 = realhpos * precisionw + vec3(0, 1, 0) * waterh;
        vec3 p2 = realhpos * precisionw + vec3(0.1, 0.0, 0.0) + vec3(0, 1, 0) * waterh2;
        vec3 p3 = realhpos * precisionw + vec3(0.0, 0.0, 0.1) + vec3(0, 1, 0) * waterh3;
        vec3 newn = vec3(waterh2 - waterh, 1.0, waterh3 - waterh);//-(cross(p2 - p1, p3 - p1));
    //  newn.xz *= 0.0;*/
        float vmultiplier = height < planetradius ? max(0, dot(normalize(hitnorm), viewdir)) : max(0, dot(-normalize(hitnorm), viewdir));
        vec3 wn = getwatern(realhpos.xz * 0.001);
        vec3 newn = normalize(hitnorm + wn * vec3(0.8,0,0.8) * vmultiplier * WaterWavesScale);
       // newn.xz *= 0.3;
        // newn = hitnorm;
        //newn.xz *= ;
        float rough = (1.0 - vmultiplier) * WaterWavesScale * 0.1;
        vec3 dreflected = reflect(viewdir, newn);
        if(dot(dreflected, newn) < 0) dreflected = normalize(reflect(dreflected, newn));
       // if(height < planetradius) dreflected = refract(viewdir, normalize(-newn),  1.4);
        vec3 reflected = texture(atmScattTex, UV).rgb;
        vec2 res2 = textureLod(cloudsRefShadowTex, distortUV(UV, newn.xz), mix(0.0, 3.0, rough)).rg;
        vec2 res1 = texture(cloudsRefShadowTex, UV).ba;
        // vec3 atmxaDiffuse = atmx2(normalize(SunDirection), res1.y);
        float cloudDiffuse = (1.0 - res1.r) ;
        
        //vec2 cloudReflectedA = texture(cloudsCloudsTex, distortUV(UV, newn.xz)).bg;
        float cloudReflected = 1.0 - res2.r;
      //  atmcolor = reflected;
     // cloudsData.r = 0.0;
        vec3 atmxaReflected = atmx2(normalize(SunDirection), res2.g);
        float fresnel = fresnel_again(vec3(0.04), newn, viewdir, 0.04);
        if(height < planetradius) fresnel = 1.0 - fresnel;
        reflectionCoefficent = cloudReflected;
        vec3 shaded = shadeWater(campos, newn, viewdir, realhpos, atmxa)  * cloudDiffuse + fresnel * mix(atmxaReflected, reflected, cloudReflected);
        shaded += sun(dreflected, normalize(SunDirection)) * cloudReflected ;
        //if(height < planetradius) shaded *= 1.0 - pow(clamp(planethit / 600.0, 0.0, 1.0), 2.0);
        color += shaded;
        color += stars(normalize(dreflected)) * max(0.0, 1.0 - WaterWavesScale * 2.0) * cloudReflected * (fresnel);
        viewdir = dreflected;
    } else {
        color += texture(atmScattTex, UV).rgb;
        atmcolor1 = atmx2(normalize(SunDirection), cloudsData.y);
        color += stars(getViewDir());
        color += sun(getViewDir(), normalize(SunDirection));
    }
    float mult = 1.0 ;//- smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
  //  return viewdir * (UV.x < 0.5 && planethit > 0 ? 0.0 : 1.0);
    return mix(color, atmcolor1, cloudsData.r);
}