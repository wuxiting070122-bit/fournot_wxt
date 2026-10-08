extends Node2D
## Lightweight stepped animation in source-image coordinates. No collision changes.
var world: Node2D
var lights: Array = []
var time := 0.0
var frame_index := -1
var glow: GradientTexture2D

func _ready() -> void:
	z_index = -1 # Above background, behind all actors.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1,1,1,0.18))
	gradient.set_color(1, Color(1,1,1,0))
	gradient.add_point(0.35, Color(1,1,1,0.07))
	glow = GradientTexture2D.new()
	glow.gradient = gradient
	glow.width = 128
	glow.height = 128
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5,0.5)
	glow.fill_to = Vector2(0.5,1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(world) or not world.active: return
	time += delta
	var next_frame := floori(time * 10.0)
	if next_frame != frame_index:
		frame_index = next_frame
		queue_redraw()

func enabled(light: Dictionary) -> bool:
	match str(light.get("gate", "")):
		"second": return world.second_lit
		"electric": return world.lights_on
	return true

func _draw() -> void:
	if glow == null: return
	for i in range(lights.size()):
		var light: Dictionary = lights[i]
		if not enabled(light): continue
		var t: float = floorf(time * 10.0) / 10.0 + i * 2.37
		var flame: bool = light.get("flame",false)
		var pulse := 1.0 + sin(t*2.1)*0.06 + sin(t*5.7)*0.025
		var center: Vector2 = light.pos + Vector2(sin(t*1.9)*1.6, cos(t*2.3)*0.9)
		var radius: float = light.get("radius",60.0) * pulse
		var tint := Color("ffb36a") if flame else Color("ffe0a0")
		draw_texture_rect(glow,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2.0),false,tint)
		if flame:
			var s: float = light.get("size",8.0)
			var bend := sin(t*4.1)*s*0.22
			var height := s*(1.55+sin(t*7.0)*0.18)
			var base: Vector2 = light.pos
			var shape := PackedVector2Array([base+Vector2(-s*0.65,0),base+Vector2(-s*0.72,-s*0.6),base+Vector2(-s*0.3,-s),base+Vector2(bend,-height),base+Vector2(s*0.28,-s*0.8),base+Vector2(s*0.55,-s*1.18),base+Vector2(s*0.7,-s*0.4),base+Vector2(s*0.55,0)])
			draw_colored_polygon(shape,Color("df8242"))
			var inner := PackedVector2Array([base+Vector2(-s*0.32,0),base+Vector2(bend*0.5,-height*0.68),base+Vector2(s*0.34,0)])
			draw_colored_polygon(inner,Color("ffe1a0"))
	# The hazardous inlet has the strongest visible stream, matching its timer.
	if world.room == "cold" and world.wind_active:
		for i in range(7):
			var travel := fmod(time*0.8+i/7.0,1.0)
			var start := Vector2(560+i*9,680+travel*62)
			var alpha := sin(travel*PI)*0.20
			draw_polyline(PackedVector2Array([start,start+Vector2(-2,8),start+Vector2(2,15)]),Color(0.7,0.88,0.94,alpha),1.2,true)
