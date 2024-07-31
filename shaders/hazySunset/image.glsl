float octaveNoise1D(float v, float seed, float o)
{
    float r = 0.;
    float s = 0.;
    for (float i = 0.; i < o; i++)
    {
        float os = exp2(i);
        s += 1. / os;
        float l = (v + 100. * seed) * os;
        float a = floor(l);
        float b = a + 1.;
        float f = fract(l);
        float na = pcg(a + seed * os).x / os;
        float nb = pcg(b + seed * os).x / os;
        r += mix(na, nb, smoothstep(0.,1.,f));
    }
    return r / s;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    float px = 1. / min(iResolution.x, iResolution.y);
    
    vec2 sun = vec2(-.5, 1.);
    float d = distance(sun, uv) * 2.;
    float bright = 1. / d;
    vec3 col = mix(vec3(.45,.3,.2), vec3(1.,.9,.7), bright);

    for (float i = 9.; i >= 0.; i--)
    {
        float df = pow(.8, i);
        float h = -.7 + df * octaveNoise1D((uv.x + .4 * iTime * df) / df, i, 10. - i / 3.) + .08 * i;
        vec3 clayer = mix(vec3(0.05,0.03,0.01), vec3(0.37,0.28,0.2), 0.1 * (i + 1.));
        float d = h - uv.y;
        float aa = smoothstep(0., 2. * px, d);
        col = mix(col, clayer, aa);
    }
    
    col += 0.07 * pcg(vec3(fragCoord, iTime)).x;
    fragColor = vec4(col, 1.);
}