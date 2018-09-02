//#version 140

in vec3 position;
in vec3 normal;

#if EXPLICIT_COLOR==1
in vec4 color;
#endif

uniform mat4 viewMat;
uniform mat4 projMat;
uniform mat4 modelMat;

out vec3 Normal;

#if EXPLICIT_COLOR==1
out vec4 Color;
#endif


void main()
{
    gl_Position=projMat * viewMat * modelMat * vec4(position, 1.0);
    
    Normal=(transpose(inverse(viewMat * modelMat)) * vec4(normal,0)).xyz;

#if EXPLICIT_COLOR==1
    Color=color;
#endif
}