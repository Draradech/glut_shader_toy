#define FRACT_ITER 20.
#define LOC vec2(1.170820, 0.276393)
#define NUM_COLORS 16.

// from https://www.shadertoy.com/view/4cjyDR (mrange)
const float
  pi    = acos(-1.)
, tau   = pi * 2.
, phi   = .5 + sqrt(5.) * .5
, phi2  = phi * phi
, phi4  = phi2 * phi2
;

// from https://www.shadertoy.com/view/wlsSRB (vegardno)
vec3 hsv2rgb2(vec3 c, float k) {
    vec4 K = vec4(3. / 3., 2. / 3., 1. / 3., 3.);
    vec3 p = smoothstep(0. + k, 1. - k, .5 + .5 * cos((c.xxx + K.xyz) * tau));
    return c.z * mix(K.xxx, p, c.y);
}

// from https://www.shadertoy.com/view/4cjyDR (mrange)
float superCircle8(vec2 p, float r) {
    p *= p;
    p *= p;
    return pow(dot(p, p), 1. / 8.) - r;
}

vec3 draw(vec2 uv, float colId, float px)
{
    float d = superCircle8(uv, .5);
    float shading = smoothstep(.15, -.35, d);
    float shape = smoothstep(.0, -3. * px, d);
    return shading * shape * hsv2rgb2(vec3(colId / NUM_COLORS, .9, 1.), -.1);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 col = vec3(0);
    vec2 uv = (2. * fragCoord - iResolution.xy) / max(iResolution.x, iResolution.y);
    float t = .3 * iTime;
    float px = 1. / max(iResolution.x, iResolution.y);
    
    // fractal zoom
    float ft = fract(t);
    float scale = exp(log(phi4) * ft);
    // base zoom 4 to avoid areas ouside of fractal iteration 0 on very tall or wide screens
    uv /= 4. * scale;
    px /= 4. * scale;
    
    // fractal space division
    // left of x == 1 is this iteration, draw
    // otherwise, rotate left by 90°, move next iteration to origin and scale by phi
    uv += LOC;
    for (float i = 0.; i <= FRACT_ITER; i++)
    {
        if (uv.x < 1.)
        {
            col = draw(uv - .5, mod(i + 4. * floor(t), NUM_COLORS), px);
            break;
        }
        uv = vec2(-uv.y + 1., uv.x - 1.) * phi;
        px *= phi;
    }
    
    fragColor = vec4(pow(col, vec3(1./2.2)), 1.);
}


