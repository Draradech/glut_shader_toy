void mainImage(out vec4 o, vec2 u)
{
    u /= iResolution.xy;
    float l = 2.9, d = .5, i, x, a, b, c, f, m, s, j;
    for(i = 0.; i < 1. && l > 2.; i+=.1)
    {
        x = u.x / d + .4 * iTime + 71. * i;
        a = 0.;
        for(b = 1.; b > .001; b *= .5)
        {
            f = fract(x);
            c = x - f;
            m = fract(c * .37);
            s = fract((c + 1.) * .37);
            a += mix(m, s, f) * b;
            x *= 2.;
        }
        if(u.y < d * a + i - .2) l = i + .3;
        d *= .8;
    }
    o = vec4(.4, .3, .2, 0) * l;
}

