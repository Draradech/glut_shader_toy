// https://www.pcg-random.org/
vec3 pcg(uvec3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return vec3(v) / float(0xffffffffu);
}

vec3 pcg(vec3 p) {return pcg(floatBitsToUint(p));}
vec3 pcg(uvec2 p){return pcg(p.xyx);}
vec3 pcg(vec2 p) {return pcg(floatBitsToUint(p));}
vec3 pcg(uint p) {return pcg(uvec3(p));}
vec3 pcg(float p){return pcg(floatBitsToUint(p));}

// Integer Hash - I
// - Inigo Quilez, Integer Hash - I, 2017
//   https://www.shadertoy.com/view/llGSzw
uint iqint1(uint n)
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;

    return n;
}

// Integer Hash - II
// - Inigo Quilez, Integer Hash - II, 2017
//   https://www.shadertoy.com/view/XlXcW4
uvec3 iqint2(uvec3 x)
{
    const uint k = 1103515245u;

    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;

    return x;
}

// Integer Hash - III
// - Inigo Quilez, Integer Hash - III, 2017
//   https://www.shadertoy.com/view/4tXyWN
uint iqint3(uvec2 x)
{
    uvec2 q = 1103515245U * ( (x>>1U) ^ (x.yx   ) );
    uint  n = 1103515245U * ( (q.x  ) ^ (q.y>>3U) );

    return n;
}


float hash(float v)
{
    //return pcg(v).x;
    return float(iqint1(floatBitsToUint(v))) / float(0xffffffffu);
}


float octaveNoise1D(float v, float seed, float o)
{
    float r = 0.;
    float s = 0.;
    float os = 1.;
    for (float i = 0.; i < o; i++)
    {
        s += 1. / os;
        float l = (v + 100. * seed) * os;
        float a = floor(l);
        float b = a + 1.;
        float f = fract(l);
        float na = hash(a) / os;
        float nb = hash(b) / os;
        r += mix(na, nb, smoothstep(0., 1., f));
        os *= 2.;
    }
    return r / s;
}
