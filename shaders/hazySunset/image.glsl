const vec3 colSun   = vec3(.99, .90, .70);
const vec3 colSky   = vec3(.45, .30, .20);
const vec3 colFront = vec3(.05, .03, .01);
const vec3 colBack  = vec3(.37, .28, .20);

const float numLayers = 10.;
const float yOffset = -.7;
const float layerOffset = .08;
const float layerScaleFactor = .8;
const float grainStrength = .07;

const float maxHeight = max(1. + yOffset, pow(layerScaleFactor, numLayers - 1.) + layerOffset * (numLayers - 1.) + yOffset);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    
    float hitLayer = 0.;
    float distanceScale = 1.;
    for (float curLayer = 0.; uv.y < maxHeight && curLayer < numLayers; curLayer++)
    {
        float xPos = uv.x / distanceScale + .4 * iTime;
        float octaves = 9. - curLayer / 3.;
        float seed = curLayer;
        float height = distanceScale * octaveNoise1D(xPos, seed, octaves);
        height += yOffset + layerOffset * curLayer;
        if (uv.y < height)
        {
            hitLayer = curLayer + 1.;
            break;
        }
        distanceScale *= layerScaleFactor;
    }
    
    vec3 col;
    if (hitLayer == 0.)
    {
        vec2 sun = vec2(-.5, 1.);
        float d = distance(sun, uv) * 2.;
        float bright = 1. / d;
        col = mix(colSky, colSun, bright);
    }
    else
    {
        col = mix(colFront, colBack, hitLayer / numLayers);
    }

    col += grainStrength * hash31(vec3(fragCoord, iTime));
    fragColor = vec4(col, 1.);
}