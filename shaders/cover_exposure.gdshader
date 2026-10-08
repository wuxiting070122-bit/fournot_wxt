shader_type canvas_item;
uniform float exposure = 1.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 original=texture(TEXTURE,UV);
 vec2 p=(UV-vec2(0.40,0.57))/vec2(0.39,0.54);
 float center=exp(-dot(p,p)*1.4);
 float lightness=dot(original.rgb,vec3(0.2126,0.7152,0.0722));
 // Raise existing midtones and highlights, preserving ink rather than painting a white veil.
 float ink_protection=smoothstep(0.045,0.27,lightness);
 vec3 exposed=original.rgb*(1.0+center*exposure*0.85*ink_protection);
 exposed+=vec3(0.035,0.07,0.085)*center*ink_protection*exposure;
 COLOR=vec4(clamp(exposed,vec3(0.0),vec3(1.0)),original.a)*tint;
}
