shader_type canvas_item;
uniform float phase = 0.0;
uniform bool walking = false;
uniform int facing = 0;
void fragment() {
 vec2 atlas_pixel = UV / TEXTURE_PIXEL_SIZE;
 vec2 cell = floor(atlas_pixel / 64.0) * 64.0;
 vec2 local = atlas_pixel - cell;
 vec2 source = local;
 if (walking) {
  float swing = sin(phase * 6.283185);
  float leg = local.x < 32.0 ? 1.0 : -1.0;
  float foot = smoothstep(48.0, 56.0, local.y);
  // Alternate planted and lifted feet; retain the hand-drawn upper body.
  source.y += floor(max(0.0, swing * leg) * 3.0 + 0.5) * foot;
  float stride = (facing == 1 || facing == 2) ? 2.0 : 1.0;
  source.x -= floor(swing * leg * stride + 0.5) * foot;
 }
 vec2 sample_uv = (cell + floor(source) + vec2(0.5)) * TEXTURE_PIXEL_SIZE;
 COLOR = texture(TEXTURE, sample_uv);
 if (source.x < 0.0 || source.x >= 64.0 || source.y < 0.0 || source.y >= 64.0) COLOR = vec4(0.0);
}
