#define T(U) texelFetch( iChannel0, ivec2(U), 0 )
void mainImage( out vec4 O, vec2 U )
{  O = T(U); }