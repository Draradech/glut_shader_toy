//Pyramid Bloom
//https://www.shadertoy.com/view/lsBfRc

vec3 makeBloom(float lod, vec2 offset, vec2 bCoord, vec2 aPixelSize)
{
    offset += aPixelSize;

    float lodFactor = exp2(lod);

    vec3 bloom = vec3(0.0);
    vec2 scale = lodFactor * aPixelSize;

    vec2 coord = (bCoord.xy-offset)*lodFactor;
    float totalWeight = 0.0;

    if (any(greaterThanEqual(abs(coord - 0.5), scale + 0.5)))
        return vec3(0.0);

    for (int i = -3; i < 3; i++) 
    {
        for (int j = -3; j < 3; j++) 
        {
            float wg = pow(1.0-length(vec2(i,j)) * 0.125, 6.0); //* 0.125, 6.0
            vec3 lTextureColor = textureLod(iChannel0, vec2(i,j) * scale + lodFactor * aPixelSize + coord, lod).rgb;
            lTextureColor = (any(greaterThan(lTextureColor, vec3(BLOOM_THRESHOLD)))) ? lTextureColor * BLOOM_SIZE : vec3(0.0);
            lTextureColor = pow(lTextureColor, vec3(2.2)) * wg;
            bloom = lTextureColor + bloom;

            totalWeight += wg;
            
        }
    }

    bloom /= totalWeight;

    return bloom;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelSize = 1.0 / iResolution.xy;
    vec4 lInputColor0 = texture(iChannel1, uv);

    vec3 lBlur  = makeBloom(2., vec2(0.0, 0.0), uv, pixelSize);
         lBlur += makeBloom(3., vec2(0.3, 0.0), uv, pixelSize);
         lBlur += makeBloom(4., vec2(0.0, 0.3), uv, pixelSize);
         lBlur += makeBloom(5., vec2(0.1, 0.3), uv, pixelSize);
         lBlur += makeBloom(6., vec2(0.2, 0.3), uv, pixelSize);

        vec4 lOutputColor = vec4(clamp(pow(lBlur, vec3(1.0 / 2.2)), vec3(0), vec3(100)), 1.0);
        fragColor = mix(lInputColor0, lOutputColor, BLOOM_FRAME_BLEND); 
}