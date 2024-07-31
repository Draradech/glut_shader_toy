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
