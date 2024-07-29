void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelSize = 1. / iResolution.xy;
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);

	vec2 lightSize=vec2(4.);

	// add the pixel gradients
	vec2 d = pixelSize*1.;
	vec4 dx = texture(iChannel0, uv + vec2(1,0)*d) - texture(iChannel0, uv - vec2(1,0)*d);
	vec4 dy = texture(iChannel0, uv + vec2(0,1)*d) - texture(iChannel0, uv - vec2(0,1)*d);

	vec2 displacement = vec2(dx.x,dy.x)*lightSize; // using only the red gradient as displacement vector
    vec2 mouse = iMouse.xy;
    if (mouse == vec2(0)) mouse = iResolution.xy * .66;
	float light = pow(max(1.-distance(0.5+(uv-0.5)*aspect*lightSize + displacement,0.5+(mouse.xy*pixelSize-0.5)*aspect*lightSize),0.),4.);

	// recolor the red channel
	vec4 rd = vec4(texture(iChannel0,uv+vec2(dx.x,dy.x)*pixelSize*8.).x)*vec4(0.7,1.5,2.0,1.0)-vec4(0.3,1.0,1.0,1.0);

    // and add the light map
    fragColor = mix(rd,vec4(8.0,6.,2.,1.), light*0.75*vec4(1.-texture(iChannel0,uv+vec2(dx.x,dy.x)*pixelSize*8.).x)); 
	
	//fragColor = texture(iChannel0, uv); // bypass    
}