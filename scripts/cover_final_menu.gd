extends Control
signal start_requested
signal continue_requested
const UI = preload("res://scripts/ui.gd")
var can_continue := false
var revealed := false
var intact: TextureRect
var fracture: TextureRect
var animating := false
var hovered := -1
var focus_index := 0
var about: Control
var polygons: Array = []
var shards: Array[Polygon2D] = []
var keyboard_focus := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var texture := preload("res://assets/cover/menu_english_dissolve.png")
	var background := TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = Vector2(1280,800)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	# Follow the black fracture rays all the way to their shared left tip.
	# Coordinates are authored on the source image, then mapped to the game viewport.
	var source_polygons := [
		PackedVector2Array([Vector2(650,641),Vector2(1043,390),Vector2(1603,0),Vector2(1603,370),Vector2(1066,543)]),
		PackedVector2Array([Vector2(650,641),Vector2(1066,543),Vector2(1603,370),Vector2(1603,604),Vector2(1116,684)]),
		PackedVector2Array([Vector2(650,641),Vector2(1116,684),Vector2(1603,604),Vector2(1603,890),Vector2(1168,739)])
	]
	for points in source_polygons:
		var mapped := PackedVector2Array()
		for point in points: mapped.append(point*Vector2(1280.0/1603.0,800.0/981.0))
		polygons.append(mapped)

	for points in polygons:
		var underlay := Polygon2D.new()
		underlay.polygon = points
		underlay.color = Color("05090d")
		add_child(underlay)
	for i in range(3):
		var shard := Polygon2D.new()
		shard.polygon = polygons[i]
		shard.texture = texture
		var uv := PackedVector2Array()
		for point in polygons[i]: uv.append(point*Vector2(texture.get_size())/Vector2(1280,800))
		shard.uv = uv
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/menu_shard.gdshader")
		material.set_shader_parameter("hover",0.0)
		shard.material = material
		add_child(shard)
		shards.append(shard)

	# Intact original artwork covers the menu until the first click.
	intact = TextureRect.new()
	intact.texture = preload("res://assets/cover/character.jpg")
	intact.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intact.size = Vector2(1280,800)
	intact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(intact)
	fracture = TextureRect.new()
	fracture.texture = preload("res://assets/cover/glass.jpg")
	fracture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fracture.size = Vector2(1280,800)
	fracture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crack_material := ShaderMaterial.new()
	crack_material.shader = preload("res://shaders/cover_glass.gdshader")
	fracture.material = crack_material
	add_child(fracture)

func hit_test(point: Vector2) -> int:
	for i in range(3):
		if Geometry2D.is_point_in_polygon(point-shards[i].position,polygons[i]): return i
	return -1

func _process(delta: float) -> void:
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
		material.set_shader_parameter("pointer",Vector2(1090, [300,440,610][i]) if keyboard_focus else point-shards[i].position)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered >= 0 and (hovered != 1 or can_continue) else Control.CURSOR_ARROW

func reveal() -> void:
	if revealed or animating: return
	animating = true
	var tween := create_tween()
	tween.tween_method(func(value: float): fracture.material.set_shader_parameter("reveal",value),0.0,1.35,0.42)
	tween.parallel().tween_method(func(value: float): fracture.material.set_shader_parameter("impact",value),0.7,0.0,0.38)
	for i in range(6):
		var shift := Vector2((6-i)*(1 if i%2 == 0 else -1),0)
		tween.tween_property(intact,"position",shift,0.035)
	tween.tween_property(intact,"position",Vector2.ZERO,0.05)
	tween.tween_property(intact,"modulate:a",0.0,0.35)
	tween.parallel().tween_property(fracture,"modulate:a",0.0,0.35)
	tween.tween_callback(func(): intact.hide(); fracture.hide(); revealed = true; animating = false)


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
	if event is InputEventMouseMotion: keyboard_focus = false
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
