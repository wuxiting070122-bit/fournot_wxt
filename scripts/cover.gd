extends Control
signal start_requested
signal continue_requested
const UI = preload("res://scripts/ui.gd")
var can_continue := false
var revealed := false
var intact: TextureRect
var animating := false
var hovered := -1
var focus_index := 0
var about: Control
var polygons: Array = []
var shards: Array[Polygon2D] = []
var keyboard_focus := false
var flashlight: TextureRect
var beam_position := Vector2(0.4,0.62)
var beam_sway := Vector2.ZERO
var flash: ColorRect
var break_glitch: ColorRect

var shell: TextureRect
var art: Control
var menu_letters: Array[Polygon2D] = []

func layer(texture: Texture2D) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.size = Vector2(1400,1080)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(node)
	return node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	art = Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size = Vector2(1400,1080)
	art.clip_contents = true
	add_child(art)
	resized.connect(layout_art)
	layout_art()
	var texture := preload("res://assets/cover/cracked_reference.jpg")
	var background := layer(texture)
	var exposure := ShaderMaterial.new()
	exposure.shader = preload("res://shaders/cover_source.gdshader")
	background.material = exposure
	# Original 1400 x 1080 black fracture rays; all sampling uses these coordinates.
	polygons = [
		PackedVector2Array([Vector2(550,765),Vector2(1400,12),Vector2(1400,510)]),
		PackedVector2Array([Vector2(550,765),Vector2(1400,548),Vector2(1400,943)]),
		PackedVector2Array([Vector2(570,790),Vector2(1400,950),Vector2(1400,1080),Vector2(698,1080)])
	]
	var letter_regions := [
		PackedVector2Array([Vector2(0,0),Vector2(1566,0),Vector2(1566,370),Vector2(0,580)]),
		PackedVector2Array([Vector2(0,580),Vector2(1566,370),Vector2(1566,705),Vector2(0,820)]),
		PackedVector2Array([Vector2(0,820),Vector2(1566,705),Vector2(1566,1004),Vector2(0,1004)])
	]
	for i in range(3):
		var shard := Polygon2D.new()
		shard.polygon = polygons[i]
		shard.uv = polygons[i]
		shard.texture = texture
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/cover_source.gdshader")
		material.set_shader_parameter("hover",0.0)
		shard.material = material
		art.add_child(shard)
		shards.append(shard)
		var letters := Polygon2D.new()
		letters.texture = preload("res://assets/cover/user_menu_letters.png")
		letters.uv = letter_regions[i]
		var points := PackedVector2Array()
		var factor: float = [0.484,0.517,0.418][i]
		var source_center: Vector2 = [Vector2(800,270),Vector2(870,585),Vector2(955,860)][i]
		var destination: Vector2 = [Vector2(1170,385),Vector2(1190,720),Vector2(1205,1007)][i]
		var angle: float = [-0.14,0.10,0.21][i]
		for point in letter_regions[i]: points.append((point-source_center).rotated(angle)*factor+destination)
		letters.polygon = points
		letters.modulate.a = 0.0
		var fog := ShaderMaterial.new()
		fog.shader = preload("res://shaders/menu_shard.gdshader")
		letters.material = fog
		shard.add_child(letters)
		menu_letters.append(letters)
	intact = layer(preload("res://assets/cover/character.jpg"))
	var reveal_material := ShaderMaterial.new()
	reveal_material.shader = preload("res://shaders/cover_source.gdshader")
	reveal_material.set_shader_parameter("intact",true)
	intact.material = reveal_material
	flashlight = layer(preload("res://assets/cover/light.jpg"))
	var beam_material := ShaderMaterial.new()
	beam_material.shader = preload("res://shaders/cover_flashlight.gdshader")
	flashlight.material = beam_material
	flash = ColorRect.new()
	flash.size = Vector2(1400,1080)
	flash.color = Color(0.7,0.87,1.0,0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(flash)
	break_glitch = ColorRect.new()
	break_glitch.size = Vector2(1400,1080)
	break_glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glitch_material := ShaderMaterial.new()
	glitch_material.shader = preload("res://shaders/cover_break_glitch.gdshader")
	break_glitch.material = glitch_material
	break_glitch.hide()
	art.add_child(break_glitch)
	shell = TextureRect.new()
	shell.texture = preload("res://assets/cover/terminal_shell.png")
	shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var shell_material := ShaderMaterial.new()
	shell_material.shader = preload("res://shaders/terminal_shell_fit.gdshader")
	shell.material = shell_material
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shell)
	layout_art()

func layout_art() -> void:
	# The transparent opening of the supplied 1586 x 992 monitor shell.
	var opening := Rect2(size*Vector2(184.0/1586.0,80.0/992.0),size*Vector2(1216.0/1586.0,822.0/992.0))
	var fit := minf(opening.size.x/1400.0,opening.size.y/1080.0)
	art.scale = Vector2.ONE*fit
	art.position = opening.position+(opening.size-Vector2(1400,1080)*fit)*0.5
	if is_instance_valid(shell):
		shell.size = size
		shell.material.set_shader_parameter("screen_left",art.position.x/size.x)
		shell.material.set_shader_parameter("screen_right",(art.position.x+1400.0*fit)/size.x)

func hit_test(point: Vector2) -> int:
	for i in range(3):
		if Geometry2D.is_point_in_polygon((point-art.position)/art.scale-shards[i].position,polygons[i]): return i
	return -1

func _process(delta: float) -> void:
	beam_sway = beam_sway.lerp(Vector2.ZERO,1.0-exp(-delta*2.8))
	var target := Vector2(0.4,0.62)+beam_sway
	beam_position = beam_position.lerp(target,1.0-exp(-delta*5.0))
	flashlight.material.set_shader_parameter("pointer",beam_position)
	if not revealed or animating: return
	var point := get_local_mouse_position()
	hovered = -1 if is_instance_valid(about) else hit_test(point)
	var chosen := focus_index if keyboard_focus and not is_instance_valid(about) else hovered
	for i in range(3):
		var selected := chosen == i
		var offset := Vector2(-10,-7) if selected else Vector2.ZERO
		shards[i].position = shards[i].position.lerp(offset,1.0-exp(-delta*10.0))
		var material := shards[i].material as ShaderMaterial
		var amount: float = material.get_shader_parameter("hover")
		material.set_shader_parameter("hover",lerpf(amount,1.0 if selected else 0.0,1.0-exp(-delta*8.0)))
		var pointer := Vector2(1200, [360,700,1010][i]) if keyboard_focus else (point-art.position)/art.scale-shards[i].position
		material.set_shader_parameter("pointer",pointer)
		menu_letters[i].material.set_shader_parameter("pointer",pointer)
		menu_letters[i].material.set_shader_parameter("hover",amount)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered >= 0 and (hovered != 1 or can_continue) else Control.CURSOR_ARROW

func reveal() -> void:
	if revealed or animating: return
	animating = true
	break_glitch.show()
	var glitch_tween := create_tween()
	glitch_tween.tween_method(func(v: float): break_glitch.material.set_shader_parameter("progress",v),0.0,1.0,0.38)
	glitch_tween.tween_callback(func(): break_glitch.hide())
	var tween := create_tween()
	tween.tween_property(flash,"color:a",0.16,0.055)
	tween.tween_property(flash,"color:a",0.0,0.12)
	tween.parallel().tween_method(func(v: float): flashlight.material.set_shader_parameter("blackout",v),0.18,0.0,0.16)
	tween.tween_method(func(v: float): intact.material.set_shader_parameter("spread",v),-0.1,1.6,0.5)
	tween.tween_callback(func(): intact.hide())
	for letters in menu_letters:
		tween.parallel().tween_property(letters,"modulate:a",1.0,0.35)
	tween.tween_callback(func(): revealed = true; animating = false)


func activate(index: int) -> void:
	if not revealed or animating or index < 0 or index > 2 or is_instance_valid(about): return
	if index == 1 and not can_continue: return
	match index:
		0: start_requested.emit()
		1: continue_requested.emit()
		2: show_about()

func show_about() -> void:
	if is_instance_valid(about): return
	about = Control.new()
	about.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(about)
	UI.panel(about,Rect2(0,0,1280,800),Color(0.02,0.04,0.06,0.94))
	UI.label(about,"关于作品 / 四非",Rect2(190,150,950,65),36,UI.GOLD)
	UI.label(about,"一个关于证据、判断与罪责的叙事推理 Demo。\n\n探索冷冻室，勾画原文中的一句话，\n在辩论中组织证据，决定第一轮投票。\n\n封面与角色绘画由作者提供。\n当前版本：第一轮投票可玩原型。",Rect2(190,248,900,320),24,UI.INK)
	UI.button(about,"返回镜面",Rect2(190,620,260,54),func(): about.queue_free(); about=null,true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		keyboard_focus = false
		beam_sway = (beam_sway+event.relative*0.00012).clamp(Vector2(-0.025,-0.018),Vector2(0.025,0.018))
	if is_instance_valid(about): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not revealed: reveal()
		else: activate(hit_test(event.position))
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if is_instance_valid(about):
		if event.keycode == KEY_ESCAPE: about.queue_free(); about = null
	elif event.keycode in [KEY_ENTER,KEY_SPACE]:
		if not revealed: reveal()
		else: activate(focus_index)
	elif event.keycode in [KEY_UP,KEY_DOWN]:
		keyboard_focus = true
		focus_index = posmod(focus_index+(1 if event.keycode == KEY_DOWN else -1),3)
		if focus_index == 1 and not can_continue: focus_index = 2 if event.keycode == KEY_DOWN else 0
	else: return
	get_viewport().set_input_as_handled()
