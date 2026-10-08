shader_type canvas_item;
render_mode blend_add;
varying vec4 tint;
void vertex(){ tint=COLOR; }
float noise(vec2 p){return sin(p.x*7.3+sin(p.y*4.1))*0.5+0.5;}
void fragment(){
 vec2 p=SCREEN_UV;
 float cloud=noise(p*3.0+vec2(TIME*0.025,0.0));
 float veil=0.48+0.22*cloud+0.22*sin(p.x*5.0+p.y*3.0+TIME*0.17);
 COLOR=vec4(vec3(0.92,0.96,1.0),veil*tint.a);
}
