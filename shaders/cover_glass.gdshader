shader_type canvas_item;
uniform float reveal = 0.0;
uniform float impact = 0.0;
void fragment(){
 float radius=distance(UV,vec2(0.39,0.71));
 float spread=1.0-smoothstep(reveal-0.08,reveal+0.01,radius);
 vec3 c=texture(TEXTURE,UV).rgb;
 float ink=1.0-dot(c,vec3(0.333333));
 COLOR=vec4(mix(vec3(0.015,0.025,0.035),vec3(0.6,0.8,0.9),impact),ink*spread);
}
