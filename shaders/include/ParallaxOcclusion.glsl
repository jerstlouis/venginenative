
#define ParallaxHeightMultiplier 1.0
float newParallaxHeight = 0;
float parallaxScale = 0.02 * ParallaxHeightMultiplier;
vec2 adjustParallaxUV(vec3 camera){
    
    vec2 T = Input.TexCoord;
    
    vec3 twpos = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normalize(Input.Tangent.xyz));
    vec3 nwpos = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normalize(Input.Normal));
    vec3 bwpos =  normalize(cross(twpos, nwpos)) * Input.Tangent.w;
    
    vec3 eyevec = ((camera - Input.WorldPos));
    vec3 V = normalize(vec3(
    dot(eyevec, twpos),
    dot(eyevec, -bwpos),
    dot(eyevec, -nwpos)
    ));
    
    const float minLayers = 6;
    const float maxLayersAngle = 11;
    const float maxLayersDistance = 24;

    float numLayers = mix(maxLayersDistance, minLayers, clamp(distance(camera, Input.WorldPos) * 1, 0.0, 1.0)) * ParallaxHeightMultiplier;
    float layerHeight = 1.0 / numLayers;
    float curLayerHeight = 0;
    vec2 dtex = parallaxScale * V.xy / V.z / numLayers;
    vec2 currentTextureCoords = T;
    float heightFromTexture = 1.0 - getBump(currentTextureCoords);
    int cnt = int(numLayers);

    while(heightFromTexture > curLayerHeight && cnt-- >= 0) 
    {
        curLayerHeight += layerHeight; 
        currentTextureCoords -= dtex;
        heightFromTexture = 1.0 - getBump(currentTextureCoords);
    }

    vec2 prevTCoords = currentTextureCoords + dtex;
    float nextH  = heightFromTexture - curLayerHeight;
    float prevH  = 1.0 - getBump(prevTCoords) - curLayerHeight + layerHeight;
    float weight = nextH / (nextH - prevH);
    vec2 finalTexCoords = prevTCoords * weight + currentTextureCoords * (1.0-weight);
    newParallaxHeight = curLayerHeight + prevH * weight + nextH * (1.0 - weight);
    return finalTexCoords;
}
