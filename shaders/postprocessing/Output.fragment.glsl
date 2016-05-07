#version 430 core

#include PostProcessEffectBase.glsl

layout(binding = 3) uniform samplerCube skyboxTex;
layout(binding = 5) uniform sampler2D directTex;
layout(binding = 6) uniform sampler2D alTex;
layout(binding = 16) uniform sampler2D aoxTex;

uniform int UseAO;
uniform int UseGamma;

#include FXAA.glsl

const float SRGB_ALPHA = 0.055;
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
    return 12.92 * channel;
    else
    return (1.0 + SRGB_ALPHA) * pow(channel, 1.0/2.4) - SRGB_ALPHA;
}
vec3 rgb_to_srgb(vec3 rgb) {
    return UseGamma == 0 ? rgb : vec3(
    linear_to_srgb(rgb.r),
    linear_to_srgb(rgb.g),
    linear_to_srgb(rgb.b)
    );
}

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

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

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

#define HOW_CLOUDY 0.4
#define SHADOW_THRESHOLD 0.2
#define SHADOW 0.2
#define SUBSURFACE 1.0
#define WIND_DIRECTION 2.0
#define TIME_SCALE 0.7
#define SCALE 0.5
#define ENABLE_SHAFTS

mat2 RM = mat2(cos(WIND_DIRECTION), -sin(WIND_DIRECTION), sin(WIND_DIRECTION), cos(WIND_DIRECTION));
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

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
    f += 0.06250*noise( p ); p = p*2.04;
    f += 0.03500*noise( p ); p = p*4.01;
    f += 0.01250*noise( p ); p = p*4.04;
    f -= 0.00125*noise( p );
    return f/0.984375;
}

float cloud(vec3 p)
{
	p-=fbm(vec3(p.x,p.y,0.0)*0.5)*2.25;
	float a = min((fbm(p*3.0)*2.2-1.1), 0.0);
	return a*a;
}

float shadow = 1.0;

#define iGlobalTime 1.0
float clouds(vec2 p){
	float ic = cloud(vec3(p * 2.0, iGlobalTime*0.01 * TIME_SCALE)) / HOW_CLOUDY;
	float init = smoothstep(0.1, 1.0, ic) * 10.0;
	shadow = smoothstep(0.0, SHADOW_THRESHOLD, ic) * SHADOW + (1.0 - SHADOW);
	init = (init * cloud(vec3(p * (6.0), iGlobalTime*0.01 * TIME_SCALE)) * ic);
	init = (init * (cloud(vec3(p * (11.0), iGlobalTime*0.01 * TIME_SCALE))*0.5 + 0.4) * init);
	return min(1.0, init);
}
float cloudslowres(vec2 p){
	float ic = 1.0 - cloud(vec3(p * 2.0, iGlobalTime*0.01 * TIME_SCALE)) / HOW_CLOUDY;
	float init = smoothstep(0.1, 1.0, ic) * 1.0;
	return min(5.0, init);
}

vec2 ratio = vec2(1.0, 1.0);
float fail = 1.0;
vec3 intersectPlane(vec3 origin, vec3 dir, vec3 point, vec3 normal)
{
    float dst = (dot(point-origin,normal)/dot(dir,normal));
    fail = max(0, sign(dst));
    return origin + dir * dst;
}
vec3 getclouds(){
    vec3 p = intersectPlane(CameraPosition, normalize(reconstructCameraSpaceDistance(UV, 1.0)), vec3(0, 500, 0), vec3(0,-1,0));
	vec2 surfacePosition = p.xz;
	vec2 position = RM*( surfacePosition * 0.001);
	float c = clouds(position) * fail;
	return mix(vec3(1), pow(vec3(0.23, 0.33, 0.48), vec3(2.2)), c) * ((1.0 / max(1.0, (distance(CameraPosition, p) - 500.0) * 0.005)));		
}

vec3 atm(vec3 sunpos){
    float mult = 1.0 - smoothstep(0.0, 0.001, textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
    vec3 colorSky = atmosphere(
        normalize(reconstructCameraSpaceDistance(UV, 1.0)),           // normalized ray direction
        vec3(0,6372e3 + CameraPosition.y * 10 ,0),               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    ) + getclouds();
    vec3 diffused = atmosphere(
        vec3(0, 1, 0),           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
    diffused += atmosphere(
        normalize(sunpos),           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
    diffused *= 0.5;
    vec3 colorObjects = diffused * (1.0 - (1.0 / (textureLod(mrt_Distance_Bump_Tex, UV, 0).r * 0.001 + 1.0)));
    return colorSky * mult + colorObjects * (1.0 - mult);
}

float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 11.2;

vec3 Uncharted2Tonemap(vec3 x)
{
   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}


vec4 shade(){    
    vec3 color = fxaa(directTex, UV).rgb + fxaa(alTex, UV).rgb * (UseAO ==1 ? fxaa(aoxTex, UV).r : 1.0);
    //vec3 color = fxaa(aoxTex, UV).rrr;
    color += atm(vec3(1,1,0));
    return vec4(rgb_to_srgb((color )), textureLod(mrt_Distance_Bump_Tex, UV, 0).r);
}