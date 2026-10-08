shader_type canvas_item;
uniform vec2 pointer = vec2(-1000.0);
uniform float hover = 0.0;
varying vec2 local_point;
varying vec4 tint;
void vertex(){local_point=VERTEX; tint=COLOR;}
void fragment(){
 vec4 base=texture(TEXTURE,UV);
 float d=length((local_point-pointer)/vec2(215.0,155.0));
 float fog=exp(-d*d*1.6)*hover;
 vec2 px=TEXTURE_PIXEL_SIZE*3.0;
 vec3 blur=(texture(TEXTURE,UV+vec2(px.x,0)).rgb+texture(TEXTURE,UV-vec2(px.x,0)).rgb+texture(TEXTURE,UV+vec2(0,px.y)).rgb+texture(TEXTURE,UV-vec2(0,px.y)).rgb)*0.25;
 vec3 col=mix(base.rgb,blur,fog*0.85);
 col=mix(col,vec3(0.57,0.68,0.75),fog*0.20);
 float glint=exp(-pow((local_point.x-pointer.x+(local_point.y-pointer.y)*0.7)/65.0,2.0))*exp(-d*d)*hover;
 col+=vec3(0.045,0.065,0.08)*glint;
 COLOR=vec4(col,base.a)*tint;
}
