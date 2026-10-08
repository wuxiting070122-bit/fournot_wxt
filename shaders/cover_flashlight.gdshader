shader_type canvas_item;
uniform vec2 pointer=vec2(0.4,0.62);
uniform float blackout=0.0;
void fragment(){
 vec2 sample_uv=(UV-pointer)*0.88+vec2(0.40,0.60);
 // Clamp the enlarged mask at its border; never cut its bright bottom off abruptly.
 float beam=dot(texture(TEXTURE,clamp(sample_uv,vec2(0),vec2(1))).rgb,vec3(0.3333));
 COLOR=vec4(vec3(0.005,0.012,0.02),clamp((1.0-beam)*0.74+blackout,0.0,0.93));
}
