const vec3 colSun = vec3(1.,.9,.7);
const vec3 colSky = vec3(.45,.3,.2);
const vec3 colFront = vec3(0.05,0.03,0.01);
const vec3 colBack = vec3(0.37,0.28,0.2);
const float numLayers = 10.;

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
        float na = pcg(a + seed * os).x / os;
        float nb = pcg(b + seed * os).x / os;
        r += mix(na, nb, smoothstep(0.,1.,f));
        os *= 2.;
    }
    return r / s;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    float hit = 0.;
    float df = 1.;
    for (float i = 0.; uv.y < 0.3 && i < numLayers; i++)
    {
        float h = -.7 + df * octaveNoise1D((uv.x + .4 * iTime * df) / df, i, 9. - i / 3.) + .08 * i;
        if (uv.y < h)
        {
            hit = i + 1.;
            break;
        }
        df *= .8;
    }
    
    vec3 col;
    if (hit == 0.)
    {
        vec2 sun = vec2(-.5, 1.);
        float d = distance(sun, uv) * 2.;
        float bright = 1. / d;
        col = mix(colSky, colSun, bright);
    }
    else
    {
        col = mix(colFront, colBack, hit / numLayers);
    }

    col += 0.07 * pcg(vec3(fragCoord, iTime)).x;
    fragColor = vec4(col, 1.);
}