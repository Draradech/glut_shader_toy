#define N 7.
#define PI 3.14159265

#define TRAIL_PERSISTENCE .99
#define TRAIL_SPEED .003
#define ANIMATION_SPEED .005

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
        col = mix(col, vec3(1., .6 * i / (N - 1.), 0.), d);
    }

    fragColor = vec4(col, 1.);
}