const vec3 colSun   = vec3(.99, .90, .70);
const vec3 colSky   = vec3(.45, .30, .20);
const vec3 colFront = vec3(.05, .03, .01);
const vec3 colBack  = vec3(.37, .28, .20);

const float numLayers = 10.;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    
    float hit = 0.;
    float df = 1.;
    for (float i = 0.; uv.y < 0.3 && i < numLayers; i++)
    {
        float h = -.7 + df * octaveNoise1D((uv.x + .4 * iTime * df) / df, i, 9. - i / 3.) + .08 * i;
        if (uv.y < h) {hit = i + 1.; break;}
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

    col += .07 * hash31(vec3(fragCoord, iTime));
    fragColor = vec4(col, 1.);
}