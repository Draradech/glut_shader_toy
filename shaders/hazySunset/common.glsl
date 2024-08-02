// ################### hash implementations ###################

// https://www.pcg-random.org/
uint pcg(uint v)
{
	uint state = v * 747796405u + 2891336453u;
	uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
}

uvec2 pcg2d(uvec2 v)
{
    v = v * 1664525u + 1013904223u;

    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;

    v = v ^ (v>>16u);

    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;

    v = v ^ (v>>16u);

    return v;
}

// http://www.jcgt.org/published/0009/03/02/
uvec3 pcg3d(uvec3 v) {

    v = v * 1664525u + 1013904223u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    v ^= v >> 16u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    return v;
}

// http://www.jcgt.org/published/0009/03/02/
uvec4 pcg4d(uvec4 v)
{
    v = v * 1664525u + 1013904223u;
    
    v.x += v.y*v.w;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v.w += v.y*v.z;
    
    v ^= v >> 16u;
    
    v.x += v.y*v.w;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v.w += v.y*v.z;
    
    return v;
}

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



// ################### float versions with consistent naming scheme ###################

vec4  pcg44(vec4  p) {return  vec4( pcg4d( floatBitsToUint(p) ) ) / float(0xffffffffu);}
vec3  pcg33(vec3  p) {return  vec3( pcg3d( floatBitsToUint(p) ) ) / float(0xffffffffu);}
vec2  pcg22(vec2  p) {return  vec2( pcg2d( floatBitsToUint(p) ) ) / float(0xffffffffu);}
float pcg11(float p) {return float(   pcg( floatBitsToUint(p) ) ) / float(0xffffffffu);}

vec3  iq33(vec3  p) {return  vec3( iqint2( floatBitsToUint(p) ) ) / float(0xffffffffu);}
float iq21(vec2  p) {return float( iqint3( floatBitsToUint(p) ) ) / float(0xffffffffu);}
float iq11(float p) {return float( iqint1( floatBitsToUint(p) ) ) / float(0xffffffffu);}



// ################### decide which hashes to use ###################

float hash11(float p)
{
    //return pcg33(vec3(p)).x;
    return pcg11(p);
    //return iq11(p);
}

float hash31(vec3 p)
{
    return pcg33(p).x;
    //return iq33(p).x;
}



// ################### functions using hashes ###################

float octaveNoise1D(float pos, float seed, float octaves)
{
    float result = 0.;
    float divisor = 0.;
    float octaveScale = 1.;
    float offset = 63.949 * seed;
    for (float i = 0.; i < octaves; i++)
    {
        divisor += 1. * octaveScale;
        float posLeft = floor(pos + offset);
        float posRight = posLeft + 1.;
        float rightFactor = fract(pos + offset);
        float noiseLeft = hash11(posLeft) * octaveScale;
        float noiseRight = hash11(posRight) * octaveScale;
        result += mix(noiseLeft, noiseRight, smoothstep(0., 1., rightFactor));
        octaveScale *= .5;
        pos *= 2.;
    }
    return result / divisor;
}
