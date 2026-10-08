shader_type canvas_item;
void fragment(){
 // Extend only the outermost edge; keep the image's pixel scale unchanged.
 COLOR=texture(TEXTURE,clamp(UV*vec2(1314.0/1280.0,1.0),vec2(0.0),vec2(1.0)));
}
