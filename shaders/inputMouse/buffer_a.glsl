#define T(U) texelFetch( iChannel0, ivec2(U), 0 )
// see also https://www.shadertoy.com/view/Mss3zH

#define mouseUp      ( iMouse.z < 0. )                  // mouse up even:   mouse button released (well, not just that frame) 
#define mouseDown    ( iMouse.z > 0. && iMouse.w > 0. ) // mouse down even: mouse button just clicked
#define mouseClicked ( iMouse.z > 0. && iMouse.w < 0. ) // mouse clicked:   mouse button currently clicked

void mainImage( out vec4 O, vec2 U )
{
    O = T(U);                                   // restore previous state
                                                // ======== color: new mouse events ============
    vec4 C = vec4( mouseUp,                     // mouse up even: mouse button just released
                   mouseClicked,                // mouse button currently clicked
                   mouseDown,                   // mouse down even: mouse button just clicked
                   
                   1                            // disk mask
                 );

    O = max(  O,                                // blend 
             ( 20.-  length( U - iMouse.xy ) )  // draw disk
             * C );

 // C = vec4(.5+.5*sign(iMouse.zw), 0,0);
    if (U.y < 20.) 
        O = U.x < 4. ? C : T(U-vec2(4,0));      // events time-line
}