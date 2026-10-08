shader_type canvas_item;
uniform vec2 drift=vec2(0.0);
void fragment(){
 vec3 light=texture(TEXTURE,clamp(UV-drift,vec2(0.0),vec2(1.0))).rgb;
 float beam=dot(light,vec3(0.333333));
 COLOR=vec4(0.005,0.015,0.023,(1.0-beam)*0.82);
}
