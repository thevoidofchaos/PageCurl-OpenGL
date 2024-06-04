#version 300 es

precision mediump float;  // For better precision in lighting calculations


uniform sampler2D s_front;
uniform sampler2D s_back;
uniform int frontFacing;

in vec2 texcoord;
in vec3 normal;
in vec3 lightDirection;
in vec3 frontLightDirection;

out vec4 fragColor;

//This has to do with the OpenGL co-ordinate system. I need to pass this lightDirection from the vertex shader or based on the position of curl (top-right or top-left).
//TODO: - Disable the curl from top
//For right back - const vec3 lightDirection = normalize(vec3(1.0, -1.0, -1.0));
//For left back - const vec3 lightDirection = normalize(vec3(-1.0, -1.0, -1.0));
//const vec3 lightDirection = normalize(vec3(-1.0, -1.0, -1.0));
//For front - const vec3 lightDirection = normalize(vec3(-1.0, 0.0, 1.0));  // Adjust and test different directions
//Less value for the ambientLight means that the shadows will be more intense
const vec4 ambientLight = vec4(0.4, 0.4, 0.4, 1.0);  // Reduce ambient light

// For back - const vec3 lightDirection = normalize(vec3(-1.0, 0.0, 0.0));
void main()
{
        if (gl_FrontFacing) {
//            vec3 lightDirection = normalize(vec3(-1.0, 0.0, 1.0));
//            fragColor = texture(s_front, texcoord);
            vec4 color = texture(s_front, texcoord);
            vec3 n = normalize(normal);
                vec3 lightDir = normalize(lightDirection);
                float diff = max(dot(n, lightDir), 0.0);
                vec3 lighting = color.rgb * (ambientLight.rgb + diff);
                fragColor = vec4(lighting, color.a);
            
            //BLUE
            
//            float gestureDirectionX = gestureDirection.x;
//            if gestureDirectionX >= 0.f {
//                fragColor = vec4(0.0f, 0.0f, 1.0f, 1.0f);
//            } else {
//                fragColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
//            }
//            fragColor = vec4(normalize(normal) * 0.5 + 0.5, 1.0);

        }else{
//            vec3 lightDirection = normalize(vec3(-1.0, 0.0, 0.0));
//            fragColor = texture(s_back, texcoord);
            vec4 color = texture(s_back, texcoord);
            vec3 n = normalize(normal);
                vec3 lightDir = normalize(lightDirection);
                float diff = max(dot(n, lightDir), 0.0);
                vec3 lighting = color.rgb * (ambientLight.rgb + diff);
                fragColor = vec4(lighting, color.a);
            
            //YELLOW
//            float gestureDirectionX = gestureDirection.x;
//            if gestureDirectionX >= 0.f {
//                fragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
//            } else {
//                fragColor = vec4(0.0f, 1.0f, 0.0f, 1.0f);
//            }
//            fragColor = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
        }
    
}
