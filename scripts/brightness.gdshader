shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float brightness = 1.0;
void fragment() {
 vec4 source = texture(screen_texture, SCREEN_UV);
 COLOR = vec4(clamp(source.rgb * brightness, vec3(0.0), vec3(1.0)), source.a);
}
