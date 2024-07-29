cl /Feglut_shader_toy.exe /DNDEBUG /O2 /Ifreeglut/include /Iglew/include glut_shader_toy.c /link /LIBPATH:freeglut/lib /LIBPATH:glew/lib/Release/x64 glew32.lib

del *.obj
