shader_type canvas_item;
render_mode unshaded;
// Expand only the housing horizontally; artwork retains its own uniform transform.
uniform float screen_left = 0.164;
uniform float screen_right = 0.836;
void fragment() {
 const float source_left = 184.0 / 1586.0;
 const float source_right = 1400.0 / 1586.0;
 float x;
 if (UV.x < screen_left) {
  x = UV.x / screen_left * source_left;
 } else if (UV.x > screen_right) {
  x = source_right + (UV.x-screen_right)/(1.0-screen_right)*(1.0-source_right);
 } else {
  x = mix(source_left,source_right,(UV.x-screen_left)/(screen_right-screen_left));
 }
 COLOR = texture(TEXTURE,vec2(x,UV.y));
}
