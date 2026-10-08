shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float progress = 0.0;
void fragment(){
 float pulse = (1.0-smoothstep(0.015,0.075,abs(progress-0.12)))
             + (1.0-smoothstep(0.01,0.055,abs(progress-0.39)))
             + (1.0-smoothstep(0.01,0.045,abs(progress-0.67)));
 pulse=clamp(pulse,0.0,1.0);
 float band=floor(UV.y*36.0);
 float shift=sin(band*13.7+floor(progress*28.0)*7.3)*0.006*pulse;
 vec2 uv=SCREEN_UV+vec2(shift,0.0);
 vec3 base=texture(screen_texture,uv).rgb;
 vec3 split=vec3(texture(screen_texture,uv+vec2(.003*pulse,0)).r,base.g,texture(screen_texture,uv-vec2(.003*pulse,0)).b);
 vec3 inverse=vec3(1.0)-split;
 vec3 color=mix(split,inverse,pulse*.85);
 color=mix(color,vec3(.80,.95,1.0),pulse*.12);
 COLOR=vec4(color,pulse);
}
