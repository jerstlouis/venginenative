
uniform float CloudsFloor;
uniform float CloudsCeil;
uniform float CloudsThresholdLow;
uniform float CloudsThresholdHigh;
uniform float CloudsWindSpeed;
uniform vec3 CloudsScale;
uniform vec3 SunDirection;
uniform float AtmosphereScale;
uniform float CloudsDensityScale;
uniform float CloudsDensityThresholdLow;
uniform float CloudsDensityThresholdHigh;
uniform float Time;


#define PI 3.141592
#define iSteps 16
#define jSteps 8

float rsi(vec3 r0, vec3 rd, float sr) {
    // Simplified ray-sphere intersection that assumes
    // the ray starts inside the sphere and that the
    // sphere is centered at the origin. Always intersects.
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    return (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    float iStepSize = rsi(r0, r, rAtmos) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos) / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;
        
        float invshRlh = 1.0 / shRlh;
        float invshMie = 1.0 / shMie;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight * invshRlh) * jStepSize;
            jOdMie += exp(-jHeight * invshMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return max(vec3(0.0), iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie));
}

vec3 sun(vec3 camdir, vec3 sundir){
    float dt = max(0, dot(camdir, sundir));
    //return pow(smoothstep(0.99574189, 0.99996189, dt), 60.0) * vec3(1);
    return pow(dt*dt*dt*dt*dt, 256.0) * vec3(10) + pow(dt, 128.0) * vec3(0.8);
}


vec3 atmcolor = vec3(0);
vec3 atm(vec3 sunpos){
    float mult = 1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
    vec3 vdir = normalize(reconstructCameraSpaceDistance(UV, 1.0));
    vec3 colorSky = atmosphere(
        vdir,           // normalized ray direction
        vec3(0,6372e3  ,0)+ CameraPosition * AtmosphereScale,               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(2.5e-6, 6.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
    vec3 diffused = atmosphere(
        normalize(sunpos) + vec3(0, 0.15, 0),           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(2.5e-6, 6.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
    atmcolor = diffused;
    vec3 colorObjects = diffused * (1.0 - (1.0 / (textureLod(mrt_Distance_Bump_Tex, UV, 0).r * 0.001 + 1.0)));
    return colorSky * mult;// + colorObjects * (1.0 - mult);
}
#define PI 3.141592

float hash( float n )
{
    return fract(sin(n)*758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x); 
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
		    mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f -= 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*4.04;
    f += 0.03500*noise( p ); p = p*4.01;
    f += 0.01250*noise( p+(Time * CloudsWindSpeed * 0.4) ); 
    return f/0.984375;
}

float fbmx( vec3 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f -= 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*2.04;
    return f/0.984375 * 2.0;
}

float howcloudy = 0.83;
float howcloudyM = 0.84;
vec3 wtim =vec3(0);

#define wind vec3(-1.0, 0.0, 0.0)
float cloudsDensity3D(vec3 pos){
    vec3 ps = pos * CloudsScale + wtim;
    float density = 1.0 - fbm(ps * 0.05);
    density *= smoothstep(CloudsDensityThresholdLow, CloudsDensityThresholdHigh, 1.0 - fbm(ps * 0.005 * CloudsDensityScale));
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh,  density);
    return  init;
}
float cloudsDensity3DLOWRES(vec3 pos){
    vec3 ps = pos * CloudsScale + wtim;
    float density = fbmx(ps * 0.05);
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh, 1.0 - density);
    return  init;
}

struct Ray {
    vec3 o; //origin
    vec3 d; //direction (should always be normalized)
};

struct Sphere {
    vec3 pos;   //center of sphere position
    float rad;  //radius
};
float minhit = 0.0;
float maxhit = 0.0;
float rsi2(in Ray ray, in Sphere sphere)
{
    vec3 oc = ray.o - sphere.pos;
    float b = 2.0 * dot(ray.d, oc);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float disc = b * b - 4.0 * c;

    if (disc < 0.0)
        return -1.0;

    float q;
    if (b < 0.0)
        q = (-b - sqrt(disc))/2.0;
    else
        q = (-b + sqrt(disc))/2.0;

    float t0 = q;
    float t1 = c / q;

    if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    minhit = min(t0, t1);
    maxhit = max(t0, t1);

    if (t1 < 0.0)
        return -1.0;

    if (t0 < 0.0) {
        return t1;
    } else {
        return t0; 
    }
}
float planetradius = 6372e3;
Sphere planet = Sphere(vec3(0), planetradius);

float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}
    

Sphere sphere1;
Sphere sphere2;

vec3 sundir = normalize(SunDirection);
vec3 viewdirglob = vec3(0,1,0);
vec3 outpoint = vec3(0);
float color = 0.0;
vec2 internalmarchconservative(float scale, vec3 p1, vec3 p2){
    float iter = 0.0;
    float span = CloudsCeil - CloudsFloor;
   // float stepcount = mix(300, 64, span / distance(p1, p2));
    const float stepcount = 128.0;
    const float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV + vec2(0, 0)) * stepsize;
    float shadow = 0.0;
    //float outpointdst = 1.0;
    float w = 0.0;
    const float invspan = 1.0 / span;
    float start = planetradius + CloudsFloor;
    
    float c = 0.0;
    float coverageinv = 1.0;
    
    
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, iter + rd);
        float clouds = cloudsDensity3D(pos * 0.01 * scale);
        float height = length(vec3(0,planetradius ,0) + pos);
        c += coverageinv * ((height - start) * invspan);
        w += coverageinv;
     //   outpointdst = min(outpointdst, mix(outpointdst, iter + rd, step(0.01, clouds)));
        coverageinv *= 1.0 - clamp(clouds * stepsize * 90, 0.0, 1.0);
       // if(coverageinv < 0.03)break;
        iter += stepsize;
    }
    if(w > 0.01) c /= w;
   // outpoint = mix(p1, p2, outpointdst);
   // if(distance(outpoint, p1) > 50000) outpoint = p1 + normalize(outpoint - p1) * 50000;
    return vec2(1.0 - coverageinv, c);
}
#define intersects(a) (a >= 0.0)
vec2 raymarchCloudsConservative(float scale, float floord, float ceiling){
    vec3 campos = CameraPosition * AtmosphereScale;
    vec3 viewdir = normalize(reconstructCameraSpaceDistance(UV, 10.0));
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
    vec2 res = vec2(0);
    if(height < cloudslow){
        if(planethit < 0){
            res = internalmarchconservative(scale, campos + viewdir * hitfloor, campos + viewdir * hitceil);
        }
    } else if(height >= cloudslow && height < cloudshigh){
        if(intersects(hitfloor)){
            res = internalmarchconservative(scale, campos, campos + viewdir * floorminhit);
        } else {
            res = internalmarchconservative(scale, campos, campos + viewdir * hitceil);
        }
    } else if(height > cloudshigh){
        if(!intersects(hitfloor) && !intersects(hitceil)){
            res = vec2(0);
        } else if(!intersects(hitfloor)){
            res = internalmarchconservative(scale, campos + viewdir * minhit, campos + viewdir * maxhit);
        } else {
            res = internalmarchconservative(scale, campos + viewdir * ceilminhit, campos + viewdir * floorminhit);
        }
    }
    
    return res;
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
vec3 atmx2(vec3 sunpos, float shadowvalue){

    //return mix(vec3(1.0), 1.0 * scatter2,1.0 - texture(cloudsCloudsTex, UV).y);
    //return mix(vec3(3.0), scatter2 * 3.0, 1.0 - texture(cloudsCloudsTex, UV).y);
    vec3 cmix = mix(vec3(1.0), atmcolor, 1.0 - max(0, dot(sunpos, vec3(0,1,0))));
    vec3 cfla = mix(cmix, vec3(0.01),  1.0 - max(0, dot(sunpos, vec3(0,1,0))));
    cmix *= cfla;
    float shadowmult = 1000.0 / (CloudsCeil - CloudsFloor);
    return mix(vec3(cmix * shadowmult), vec3(cmix * 3.0), shadowvalue);
}

float stars(){
    vec3 viewdir = normalize(reconstructCameraSpaceDistance(UV, 10.0));
    float a = dot(viewdir, vec3(0,1,0)) * 0.5 + 0.5;
    float b = dot(viewdir, vec3(1,0,0)) * 0.5 + 0.5;
    float ns = rand2s(vec2(a,b));
    return pow(smoothstep(0.997, 1.0, ns), 3.0) * fbmx(vec3(a*100.0, b*100.0, Time*2.0));
}

vec2 CloudsGetCloudsCoverageShadow(){
    wtim = wind * Time * CloudsWindSpeed;
    return raymarchCloudsConservative(1, CloudsFloor, CloudsCeil);
}

vec3 ApplyAtmosphere(vec3 color, vec2 cloudsData){
    //return mix(color, vec3(1), cloudsData.r);
    vec3 campos = CameraPosition * AtmosphereScale;
    vec3 viewdir = normalize(reconstructCameraSpaceDistance(UV, 10.0));
    vec3 atmorg = vec3(0,planetradius ,0) + campos;  
    Ray r = Ray(atmorg, viewdir);
    float planethit = rsi2(r, planet);
    color += atm(normalize(SunDirection));
    if(planethit > 0){
        color += atmcolor* min(1.0, planethit * 0.0001);
    } else {
        color += stars();
        color += sun(normalize(reconstructCameraSpaceDistance(UV, 1.0)), normalize(SunDirection));
    }
    float mult = 1.0 ;//- smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
    return mix(color, vec3(atmx2(normalize(SunDirection), cloudsData.y)), cloudsData.r);
}