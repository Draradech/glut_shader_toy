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
// main reaction-diffusion loop

// actually the diffusion is realized as a separated two-pass Gaussian blur kernel and is stored in buffer C
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelSize = 1. / iResolution.xy;
    
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);
    
    vec3 noise = pcg33(vec3(fragCoord, iTime));

    // get the gradients from the blurred image
	vec2 d = pixelSize*4.;
	vec4 dx = (texture(iChannel2, fract(uv + vec2(1,0)*d)) - texture(iChannel2, fract(uv - vec2(1,0)*d))) * 0.5;
	vec4 dy = (texture(iChannel2, fract(uv + vec2(0,1)*d)) - texture(iChannel2, fract(uv - vec2(0,1)*d))) * 0.5;
    
    vec2 uv_red = uv + vec2(dx.x, dy.x)*pixelSize*8.; // add some diffusive expansion
    
    float new_red = texture(iChannel0, fract(uv_red)).x + (noise.x - 0.5) * 0.0025 - 0.002; // stochastic decay
	new_red -= (texture(iChannel2, fract(uv_red + (noise.xy-0.5)*pixelSize)).x -
				texture(iChannel0, fract(uv_red + (noise.xy-0.5)*pixelSize))).x * 0.047; // reaction-diffusion
        
    if(iFrame == 0)
    {
        fragColor = vec4(noise, 1); 
    }
    else
    {
        fragColor.x = clamp(new_red, 0., 1.);
    }

    //fragColor = vec4(noise, 1); // need a restart?
}