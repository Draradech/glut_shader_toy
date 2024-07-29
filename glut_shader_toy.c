#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#include <GL/glew.h>
#include <GL/freeglut.h>

static char *vs = ""
"#version 330 core                                                       \n"
"layout(location = 0) in vec3 p;                                         \n"
"void main(){gl_Position = vec4(p.x, p.y, p.z, 1.0);}                    \n";

static char *fs_header = ""
"#version 330 core                                                       \n"
"#extension GL_ARB_explicit_uniform_location : enable                    \n"
"layout(location =  0) uniform int       iFrame;                         \n"
"layout(location =  1) uniform float     iTime;                          \n"
"layout(location =  2) uniform float     iTimeDelta;                     \n"
"layout(location =  3) uniform float     iFrameRate;                     \n"
"layout(location =  4) uniform vec3      iResolution;                    \n"
"layout(location =  5) uniform vec4      iMouse;                         \n"
"layout(location =  6) uniform vec4      iDate;                          \n"
"layout(location =  7) uniform sampler2D iChannel0;                      \n"
"layout(location =  8) uniform sampler2D iChannel1;                      \n"
"layout(location =  9) uniform sampler2D iChannel2;                      \n"
"layout(location = 10) uniform sampler2D iChannel3;                      \n"
"layout(location =  0) out vec4 glut_shader_toy_out_color;               \n"
"void mainImage(out vec4 fragColor, in vec2 fragCoord);                  \n"
"void main(){mainImage(glut_shader_toy_out_color, gl_FragCoord.xy);}     \n";

#ifdef _WIN32
#include <GL/wglew.h>
#include <windows.h>
#define glSwapInterval wglSwapIntervalEXT
static int usDiv = 0;
static int64_t micros()
{
    int64_t time;
    if (usDiv == 0)
    {
        int64_t freq;
        QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
        if (freq % 1000000 != 0)
        {
            fprintf(stderr, "PerfCounter non-integer fraction of us: freq = %lld\n", freq);
            exit(0);
        }
        usDiv = freq / 1000000;
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&time);
    
    return time / usDiv;
}

// MSVC defines this in winsock2.h!?
typedef struct timeval {
    time_t tv_sec;
    long tv_usec;
} timeval;

int gettimeofday(struct timeval * tp, struct timezone * tzp)
{
    // Note: some broken versions only have 8 trailing zero's, the correct epoch has 9 trailing zero's
    // This magic number is the number of 100 nanosecond intervals since January 1, 1601 (UTC)
    // until 00:00:00 January 1, 1970 
    static const uint64_t EPOCH = ((uint64_t) 116444736000000000ULL);

    SYSTEMTIME  system_time;
    FILETIME    file_time;
    uint64_t    time;

    GetSystemTime( &system_time );
    SystemTimeToFileTime( &system_time, &file_time );
    time =  ((uint64_t)file_time.dwLowDateTime )      ;
    time += ((uint64_t)file_time.dwHighDateTime) << 32;

    tp->tv_sec  = (long) ((time - EPOCH) / 10000000L);
    tp->tv_usec = (long) (system_time.wMilliseconds * 1000);
    return 0;
}
#else
#include <sys/time.h>
#include <GL/glxew.h>
void glSwapInterval(int interval)
{
    Display *dpy = glXGetCurrentDisplay();
    GLXDrawable drawable = glXGetCurrentDrawable();
    glXSwapIntervalEXT(dpy, drawable, interval);
}

int64_t micros()
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (int64_t)ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
}
#endif

static int width = 960;
static int height = 540;
static float fpsTarget = 1000.;
static int vsync = 1;
static int cw = 0;
static int ch = 0;
static GLuint vao, vbo, fbo;
static GLuint shader[5];
static GLuint texture[5][2];
static int lastRendered[5];

static int iFrame;
static int64_t iTimeRef;
static float iTime, iTimeDelta, iFrameRate, iResolution[3], iMouse[4], iDate[4];

static void calcFps(int64_t time)
{
   static int64_t timeOld, timeLast;
   static int frameCounter;
   
   frameCounter++;
   
   iTimeDelta = timeLast == 0 ? 0 : 1e-6 * (time - timeLast);
   timeLast = time;
   
   if(timeOld == 0) {timeOld = time; frameCounter = 0;}
   if(time > timeOld + 100000) // 100ms
   {
      iFrameRate = frameCounter * 1000000.0 / (time - timeOld);
      frameCounter = 0;
      timeOld = time;
      printf("%.1f    %.1f fps    %d x %d\n", iTime, iFrameRate, cw, ch);
      //printf("%f %f %f %f\n", iMouse[0], iMouse[1], iMouse[2], iMouse[3]);
   }
}

static void updateUniforms()
{
    int64_t now = micros();
    iTime = iFrame == 0 ? 0 : 1e-6 * (now - iTimeRef);
    if (iFrame == 0) iTimeRef = now;
    calcFps(now); // iFrameRate, iTimeDelta

    struct timeval tv;
    gettimeofday(&tv, NULL);
    struct tm *tm = localtime(&tv.tv_sec);

    iDate[0] = 1900 + tm->tm_year;
    iDate[1] = tm->tm_mon; // really, shadertoy? 0 - 11?
    iDate[2] = tm->tm_mday;
    iDate[3] = (tm->tm_hour * 60. + tm->tm_min) * 60. + tm->tm_sec + 1e-6 * tv.tv_usec;
}

static void setUniforms()
{
    glUniform1i( 0, iFrame);
    glUniform1f( 1, iTime);
    glUniform1f( 2, iTimeDelta);
    glUniform1f( 3, iFrameRate);
    glUniform4f( 5, iMouse[0], iMouse[1], iMouse[2], iMouse[3]);
    glUniform4f( 6, iDate[0], iDate[1], iDate[2], iDate[3]);
}

static void activateTextures()
{
    if (shader[1])
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture[1][lastRendered[1]]);
    }
    if (shader[2])
    {
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texture[2][lastRendered[2]]);
    }
    if (shader[3])
    {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, texture[3][lastRendered[3]]);
    }
    if (shader[4])
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, texture[4][lastRendered[4]]);
    }
}

static void idle(void)
{
    static int64_t timeLast = 0;
    int64_t time = micros();
    if(timeLast == 0) timeLast = time;
    if(time - timeLast >= 1e6 / fpsTarget)
    {
        glutPostRedisplay();
        timeLast = time;
    }
}

static void draw(void)
{
    updateUniforms();
    
    for (int i = 1; i < 5; i++)
    {
        if (shader[i])
        {
            int nowRendering = !lastRendered[i];
            glBindFramebuffer(GL_FRAMEBUFFER, fbo);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture[i][nowRendering], 0);
            GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
            if(status != GL_FRAMEBUFFER_COMPLETE)
            {
                fprintf(stderr, "Framebuffer status error: %d\n", status);
                exit(0);
            }
            glUseProgram(shader[i]);
            activateTextures();
            setUniforms();
            glDrawArrays(GL_TRIANGLES, 0, 6);
            lastRendered[i] = nowRendering;
        }
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glUseProgram(shader[0]);
    activateTextures();
    setUniforms();
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glutSwapBuffers();
    iFrame++;
    if (iMouse[3] > 0) iMouse[3] = -iMouse[3];
}

static void clearTexture(GLuint tex)
{
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE)
    {
        fprintf(stderr, "Framebuffer status error: %d\n", status);
        exit(0);
    }
    glClear(GL_COLOR_BUFFER_BIT);
}

static void createTextures(int ti)
{
    if (texture[ti][0] == 0) glGenTextures(2, &texture[ti][0]);

    glBindTexture(GL_TEXTURE_2D, texture[ti][0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, cw, ch, 0, GL_RGBA,  GL_UNSIGNED_BYTE, NULL);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    clearTexture(texture[ti][0]);

    glBindTexture(GL_TEXTURE_2D, texture[ti][1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, cw, ch, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);    
    clearTexture(texture[ti][1]);
}

static void reset()
{
    iFrame = 0;
    for (int i = 1; i < 5; i++)
    {
        if (shader[i]) createTextures(i);
    }

}

static void key(unsigned char key, int x, int y)
{
   static int fs = 0;
   switch(key)
   {
      case 27:
         glutLeaveMainLoop();
         break;
      case 'f':
         fs = !fs;
         if(fs) glutFullScreen();
         else glutReshapeWindow(width, height);
         break;
      case 'r':
         reset();
         break;
   }
}

static void mouse(int button, int state, int x, int y)
{
    if (button == GLUT_LEFT_BUTTON)
    {
        if (state == GLUT_DOWN)
        {
            iMouse[0] = x;
            iMouse[1] = ch - y;
            iMouse[2] = x;
            iMouse[3] = ch - y;
        }
        else
        {
            iMouse[2] = -iMouse[2];
        }   
    }
}

static void motion(int x, int y)
{
    iMouse[0] = x;
    iMouse[1] = ch - y;
}

static void reshape(int w, int h)
{
    cw = w;
    ch = h;
    iResolution[0] = w;
    iResolution[1] = h;
    iResolution[2] = 1.;
    glViewport(0, 0, w, h);
    
    for (int i = 0; i < 5; i++)
    {
        if (shader[i])
        {
            if (i != 0) createTextures(i);
            glUseProgram(shader[i]);
            glUniform3f( 4, iResolution[0], iResolution[1], iResolution[2]);
        }
    }
}

static void addShader(GLuint shaderProgram, char* pShaderText, GLenum shaderType)
{
    GLuint shaderObj = glCreateShader(shaderType);

    if (shaderObj == 0) {
        fprintf(stderr, "Error creating shader type %d\n", shaderType);
        exit(0);
    }

    const GLchar* p[1];
    p[0] = pShaderText;

    GLint l[1];
    l[0] = (GLint)strlen(pShaderText);

    glShaderSource(shaderObj, 1, p, l);
    glCompileShader(shaderObj);
    GLint success;
    glGetShaderiv(shaderObj, GL_COMPILE_STATUS, &success);
    if (!success) {
        GLchar infoLog[1024];
        glGetShaderInfoLog(shaderObj, 1024, NULL, infoLog);
        fprintf(stderr, "Error compiling shader type %d: '%s'\n", shaderType, infoLog);
        exit(1);
    }

    glAttachShader(shaderProgram, shaderObj);
}

static void compileShader(int shaderIndex, char* vs, char *fs)
{
    shader[shaderIndex] = glCreateProgram();

    if (shader[shaderIndex] == 0) {
        fprintf(stderr, "Error creating shader program\n");
        exit(1);
    }

    addShader(shader[shaderIndex], vs, GL_VERTEX_SHADER);
    addShader(shader[shaderIndex], fs, GL_FRAGMENT_SHADER);

    GLint success = 0;
    GLchar errorLog[1024] = { 0 };

    glLinkProgram(shader[shaderIndex]);
    glGetProgramiv(shader[shaderIndex], GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shader[shaderIndex], sizeof(errorLog), NULL, errorLog);
        fprintf(stderr, "Error linking shader program: '%s'\n", errorLog);
        exit(1);
    }

    glValidateProgram(shader[shaderIndex]);
    glGetProgramiv(shader[shaderIndex], GL_VALIDATE_STATUS, &success);
    if (!success)
    {
        glGetProgramInfoLog(shader[shaderIndex], sizeof(errorLog), NULL, errorLog);
        fprintf(stderr, "Invalid shader program: '%s'\n", errorLog);
        exit(1);
    }

    glUseProgram(shader[shaderIndex]);
    glUniform1i( 7, 0); // Texture Units
    glUniform1i( 8, 1);
    glUniform1i( 9, 2);
    glUniform1i(10, 3);
}

#define MAX 100000
static char *fname, *fs, *common;
static char *names[] = {"/image.glsl", "/buffer_a.glsl", "/buffer_b.glsl", "/buffer_c.glsl", "/buffer_d.glsl"};
static char *cname = "/common.glsl";
void compileShaders(char *folderName)
{
    fname = malloc(255);
    
    int fs_header_l = strlen(fs_header);

    fname[0] = 0;
    strcat(fname, folderName);
    strcat(fname, cname);
    FILE* f = fopen(fname, "r");
    int common_l = 0;
    common = malloc(MAX);
    common[0] = 0;
    if (f)
    {
        common_l = fread(common, 1, MAX, f);
        fclose(f);
    }

    fname[0] = 0;
    strcat(fname, folderName);
    strcat(fname, names[0]);
    f = fopen(fname, "r");
    if (!f)
    {
        fprintf(stderr, "image shader is mandatory \"%s\"\n", fname);
        exit(1);
    }
    fs = malloc(MAX);
    fs[0] = 0;
    strcat(fs, fs_header);
    strcat(fs, common);
    int cnt = fread(fs + fs_header_l + common_l, 1, MAX - fs_header_l - common_l - 1, f);
    fs[fs_header_l + common_l + cnt] = 0;
    fclose(f);
    compileShader(0, vs, fs);
    
    for (int i = 1; i < 5; i++)
    {
        fname[0] = 0;
        strcat(fname, folderName);
        strcat(fname, names[i]);
        f = fopen(fname, "r");
        if (f)
        {
            fs[0] = 0;
            strcat(fs, fs_header);
            strcat(fs, common);
            int cnt = fread(fs + fs_header_l + common_l, 1, MAX - fs_header_l - common_l - 1, f);
            fs[fs_header_l + common_l + cnt] = 0;
            compileShader(i, vs, fs);
            fclose(f);
        }
    }
    
    free(common);
    free(fname);
    free(fs);
    
    printf("\nShaders loaded.\n%s:   %s\n%s:    Y\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n\n", cname, common_l?"Y":"N", names[0], names[1], shader[1]?"Y":"N", names[2], shader[2]?"Y":"N", names[3], shader[3]?"Y":"N", names[4], shader[4]?"Y":"N");
}

static void GLAPIENTRY messageCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message, const void* userParam )
{
    fprintf(stderr, "GLDebug message: source 0x%x, type 0x%x, id 0x%x, severity 0x%x: %s\n", source, type, id, severity, message);
}

int main(int argc, char* argv[])
{
    glutInit(&argc, argv);
    glutInitContextVersion(3, 3);
    glutInitContextProfile(GLUT_CORE_PROFILE);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(width, height);
    glutCreateWindow("GLUT Shader Toy");
    
    GLenum res = glewInit();
    if (res != GLEW_OK)
    {
        fprintf(stderr, "glewInit(): '%s'\n", glewGetErrorString(res));
        exit(1);
    }

    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(messageCallback, 0);
    
    glDisable(GL_DEPTH_TEST);
    
    glSwapInterval(-vsync);
    
    float verts[6][3] = {{-1,-1,0},{1,1,0},{-1,1,0},{-1,-1,0},{1,1,0},{1,-1,0}};

    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_STATIC_DRAW);

    glBindVertexArray(vao);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    GLenum dBuffers[1] = {GL_COLOR_ATTACHMENT0};
    glDrawBuffers(1, dBuffers);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    if (argc < 2)
    {
        fprintf(stderr, "shader folder needed\n");
        exit(1);
    }
    compileShaders(argv[1]);

    glutDisplayFunc(draw);
    glutReshapeFunc(reshape);
    glutKeyboardFunc(key);
    glutIdleFunc(idle);
    glutMouseFunc(mouse);
    glutMotionFunc(motion);

    glutMainLoop();

    return 0;
}


/*
next steps:
- cleanup
- mouse support
- iDate
- test more shaders
- git
- test linux

*/
