shader_type canvas_item;
uniform float spread = -0.1;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float radius=length((UV-vec2(0.405,0.65))*vec2(1.6,1.0));
 float intact=smoothstep(spread-0.045,spread+0.015,radius);
 COLOR=vec4(c.rgb,c.a*intact);
}
