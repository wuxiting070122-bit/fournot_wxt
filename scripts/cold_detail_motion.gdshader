shader_type canvas_item;
uniform float phase = 0.0;
uniform float gust = 0.0;
float patch(vec2 p, vec2 center, vec2 radius) {
 return 1.0-smoothstep(0.35,1.0,length((p-center)/radius));
}
void fragment(){
 vec2 p=UV/ TEXTURE_PIXEL_SIZE;
 float curtain=patch(p,vec2(169.0,378.0),vec2(30.0,26.0))
 +patch(p,vec2(362.0,378.0),vec2(30.0,26.0))
 +patch(p,vec2(621.0,378.0),vec2(30.0,26.0))
 +patch(p,vec2(856.0,378.0),vec2(30.0,26.0));
 float frost=patch(p,vec2(591.0,704.0),vec2(60.0,32.0))
 +patch(p,vec2(1280.0,514.0),vec2(65.0,43.0));
 vec2 shift=vec2(sin(phase*2.8+p.y*0.045)*curtain*(0.35+gust*0.8),0.0);
 shift+=vec2(sin(phase*3.6+p.y*0.13),cos(phase*2.4+p.x*0.11))*frost*(0.3+gust*0.9);
 COLOR=texture(TEXTURE,UV+shift*TEXTURE_PIXEL_SIZE);
}
