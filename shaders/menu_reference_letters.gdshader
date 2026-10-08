shader_type canvas_item;
varying vec2 point;
uniform float width=310.0;
void vertex(){point=VERTEX;}
void fragment(){
 vec4 ink=texture(TEXTURE,UV);
 float t=smoothstep(0.05,0.98,point.x/width);
 float mask=smoothstep(0.58,0.96,dot(ink.rgb,vec3(0.3333)));
 COLOR=vec4(vec3(0.81,0.91,0.96),ink.a*mask*mix(0.95,0.36,t));
}
