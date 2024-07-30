#define GRAIN .05

uvec3 pcg3d(uvec3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return v;
}

vec3 pcg33(vec3 p)
{
    uvec3 r = pcg3d(floatBitsToUint(p));
    return vec3(r) / float(0xffffffffu);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    float noise = pcg33(vec3(fragCoord, iFrame)).x;
    fragColor = noise * GRAIN + texture(iChannel0, uv);
}