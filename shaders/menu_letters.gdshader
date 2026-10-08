shader_type canvas_item;
void fragment(){
 float t=smoothstep(0.12,0.98,UV.x);
 vec2 step_uv=TEXTURE_PIXEL_SIZE*mix(0.0,1.8,t);
 float alpha=0.0;
 for(int x=-4;x<=4;x++){
  for(int y=-4;y<=4;y++){
   alpha+=texture(TEXTURE,UV+vec2(float(x),float(y))*step_uv).a/81.0;
  }
 }
 float grain=0.92+0.08*sin(UV.x*471.0+sin(UV.y*221.0));
 COLOR=vec4(vec3(0.68,0.77,0.84),alpha*mix(0.92,0.32,t)*mix(1.0,grain,t));
}
