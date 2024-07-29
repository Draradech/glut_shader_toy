#define N 7.
#define PI 3.14159265

#define TRAIL_PERSISTENCE .99
#define TRAIL_SPEED .003
#define ANIMATION_SPEED .005

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1., 2. / 3., 1. / 3., 3.);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    vec2 tuv = fragCoord / iResolution.xy;
    vec2 tpx = 1. / iResolution.xy;
    
    // not using iTime for animation, because trail effect is based on frame timing, so animation has to match
    float t = ANIMATION_SPEED * float(iFrame);
    uv *= mat2(cos(t), sin(t), -sin(t), cos(t));
    vec3 col = TRAIL_PERSISTENCE * texture(iChannel0, tuv + tpx * TRAIL_SPEED * iResolution.y * vec2(sin(.1 * t), cos(.1 * t))).rgb;
    for (float i = 0.; i < N; i++)
    {
        float phase = 4. * PI * i / N + t;
        vec2 pos = .65 * vec2(sin(phase), sin(2. * phase));
        float d = smoothstep(3. / iResolution.y, 0., abs(length(uv - pos) - .15) - .01);
        col = mix(col, hsv2rgb(vec3(mix(0., .1, i / (N - 1.)), 1., 1.)), d);
    }

    fragColor = vec4(col, 1.);
}
