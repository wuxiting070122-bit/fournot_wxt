shader_type canvas_item;
uniform bool intact = false;
uniform float spread = -0.1;
uniform float hover = 0.0;
uniform vec2 pointer = vec2(0.0);
varying vec2 point;
void vertex(){ point=VERTEX; }
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 vec2 p=(UV-vec2(.40,.57))/vec2(.39,.54);
 float center=exp(-dot(p,p)*1.4);
 float ink=smoothstep(.045,.27,dot(c.rgb,vec3(.2126,.7152,.0722)));
 c.rgb=clamp(c.rgb*(1.0+center*.85*ink)+vec3(.035,.07,.085)*center*ink,vec3(0),vec3(1));
 float fog=exp(-dot((point-pointer)/vec2(280,210),(point-pointer)/vec2(280,210))*1.6)*hover;
 c.rgb=mix(c.rgb,vec3(.57,.68,.75),fog*.14);
 if(intact){float radius=length((UV-vec2(.393,.708))*vec2(1.2963,1.0));c.a*=smoothstep(spread-.045,spread+.015,radius);}
 COLOR=c;
}
