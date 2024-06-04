#version 300 es

uniform mat4 u_mvpMatrix;
uniform vec4 u_mn;// m n width height

uniform vec3 direction;
uniform vec2 point;

layout (location = 0) in vec2 a_position;
layout (location = 1) in vec2 a_texCoord;

out vec3 lightDirection;
out vec3 frontLightDirection;
out vec2 texcoord;
out vec3 normal;

#define M_PI 3.14159265358979323846264338327950288

void main()
{
    int row = gl_InstanceID/(int(u_mn.x));
    int col = gl_InstanceID%(int(u_mn.x));
    texcoord = vec2(a_texCoord.x + float(col)/u_mn.x,a_texCoord.y + float(row)/u_mn.y);
    vec3 pos = vec3(a_position.x + float(col) * u_mn.z/u_mn.x,a_position.y + float(row) * u_mn.w/u_mn.y,0);
  
    vec3 center;
    
    float distance = dot((point - pos.xy),direction.xy);
    if(distance > 0.f){
         vec2 bottom = pos.xy + distance * direction.xy;
         float moreThanHalfCir = (distance -  M_PI * direction.z);
    
          if(moreThanHalfCir >= 0.f){//exceed
            vec3 topPoint = vec3(bottom, float(2) * direction.z);
            pos = topPoint + moreThanHalfCir * vec3(direction.xy,0);
              center = topPoint;
          }else{
    
            float angle = M_PI - distance / direction.z;
            float h = distance - sin(angle)*direction.z;
            float z = direction.z + cos(angle)*direction.z;
            vec3 vD = pos + h * vec3(direction.xy,0);
            pos = vec3(vD.xy,z);
            center = vec3(bottom, 0);
    
          }
    }
    else {
        center = vec3(pos.xy, direction.z);
    }
    
    // Calculate the normal vector
        float br1 = clamp(sign(distance), 0.0, 1.0); // distance > 0.0
        float br2 = clamp(sign(distance - M_PI * direction.z), 0.0, 1.0); // distance > M_PI * direction.z

        normal = mix(vec3(0.0, 0.0, 1.0), (center - pos) / direction.z, br1);
        normal = mix(normal, vec3(0.0, 0.0, -1.0), br2);
    
    lightDirection = vec3(-direction.x, -direction.y, -1.0);
    
    gl_Position = u_mvpMatrix * vec4(pos,1);
}
