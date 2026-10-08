extends Panel
## Opaque UI-only desktop window. Sibling order controls both drawing and hit testing.
var active := false
var caption := ""
var content: Control
var base_content_size := Vector2.ONE
var content_scroll: ScrollContainer
var original_rects: Dictionary = {}
var minimum_size := Vector2(240,100)
var manipulating := false
var resize_edge := Vector2.ZERO
var start_pointer := Vector2.ZERO
var start_rect := Rect2()

func desktop_size() -> Vector2:
	var parent := get_parent() as Control
	return parent.size if parent != null and parent.size.x > 0 else get_viewport_rect().size

func start_manipulation(edge: Vector2) -> void:
	raise_window()
	manipulating = true
	resize_edge = edge
	start_pointer = get_global_mouse_position()
	start_rect = Rect2(position,size)

func apply_pointer(pointer: Vector2) -> void:
	var delta := pointer-start_pointer
	var desktop := desktop_size()
	if resize_edge == Vector2.ZERO:
		position = (start_rect.position+delta).clamp(Vector2.ZERO,(desktop-size).max(Vector2.ZERO))
	else:
		var a := start_rect.position
		var b := start_rect.end
		if resize_edge.x < 0: a.x = clampf(a.x+delta.x,0,b.x-minimum_size.x)
		if resize_edge.x > 0: b.x = clampf(b.x+delta.x,a.x+minimum_size.x,desktop.x)
		if resize_edge.y < 0: a.y = clampf(a.y+delta.y,0,b.y-minimum_size.y)
		if resize_edge.y > 0: b.y = clampf(b.y+delta.y,a.y+minimum_size.y,desktop.y)
		position = a
		size = b-a
		layout_content()
	queue_redraw()

func layout_content() -> void:
	if not is_instance_valid(content): return
	var available := size-Vector2(4,30)
	if not is_instance_valid(content_scroll):
		content_scroll = ScrollContainer.new()
		content_scroll.position = Vector2(2,28)
		content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		add_child(content_scroll)
		move_child(content_scroll,0)
		content.reparent(content_scroll,false)
		content.position = Vector2.ZERO
		content_scroll.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed: raise_window()
		)
	content_scroll.size = available
	content.scale = Vector2.ONE
	# Resize layout rectangles, never the canvas or fonts. Keep enough vertical
	# space for wrapped labels and expose overflow through the window scrollbar.
	var width := maxf(100,available.x-14)
	var ratio := width/base_content_size.x
	var controls: Array[Control] = []
	for child in content.get_children():
		if child is Control:
			if not original_rects.has(child): original_rects[child] = Rect2(child.position,child.size)
			controls.append(child)
	controls.sort_custom(func(a: Control,b: Control): return original_rects[a].position.y < original_rects[b].position.y)
	var bottom := base_content_size.y
	var extra := 0.0
	var previous_y := -1.0
	var row_extra := 0.0
	for child in controls:
		var rect: Rect2 = original_rects[child]
		if child is Panel:
			child.size = Vector2(width,base_content_size.y)
			continue
		if rect.position.y > previous_y+8:
			extra += row_extra
			row_extra = 0
		previous_y = rect.position.y
		child.position = Vector2(roundf(rect.position.x*ratio),rect.position.y+extra)
		child.size = Vector2(roundf(rect.size.x*ratio),rect.size.y)
		if child is Label:
			child.size.y = maxf(rect.size.y,child.get_minimum_size().y)
			row_extra = maxf(row_extra,child.size.y-rect.size.y)
		bottom = maxf(bottom,child.position.y+child.size.y+10)
	content.custom_minimum_size = Vector2(width,bottom)
	content.size = content.custom_minimum_size

func _input(event: InputEvent) -> void:
	if not manipulating: return
	if event is InputEventMouseMotion:
		apply_pointer(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		manipulating = false
		get_viewport().set_input_as_handled()

func add_resize_handles() -> void:
	for edge in [Vector2(-1,-1),Vector2(0,-1),Vector2(1,-1),Vector2(-1,0),Vector2(1,0),Vector2(-1,1),Vector2(0,1),Vector2(1,1)]:
		var handle := Control.new()
		handle.name = "Resize_%s_%s" % [edge.x,edge.y]
		handle.mouse_filter = Control.MOUSE_FILTER_STOP
		handle.mouse_default_cursor_shape = Control.CURSOR_HSIZE if edge.y == 0 else (Control.CURSOR_VSIZE if edge.x == 0 else (Control.CURSOR_FDIAGSIZE if edge.x == edge.y else Control.CURSOR_BDIAGSIZE))
		add_child(handle)
		if edge.x == 0:
			handle.anchor_right = 1
			handle.offset_left = 9
			handle.offset_right = -9
		else:
			handle.anchor_left = 0 if edge.x < 0 else 1
			handle.anchor_right = handle.anchor_left
			handle.offset_left = 0 if edge.x < 0 else -8
			handle.offset_right = 8 if edge.x < 0 else 0
		if edge.y == 0:
			handle.anchor_bottom = 1
			handle.offset_top = 9
			handle.offset_bottom = -9
		else:
			handle.anchor_top = 0 if edge.y < 0 else 1
			handle.anchor_bottom = handle.anchor_top
			handle.offset_top = 0 if edge.y < 0 else -8
			handle.offset_bottom = 8 if edge.y < 0 else 0
		handle.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				start_manipulation(edge)
				handle.accept_event()
		)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh_frame()

func refresh_frame() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("080808")
	frame.border_color = Color("46edee") if active else Color("929898")
	frame.set_border_width_all(3 if active else 2)
	add_theme_stylebox_override("panel",frame)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(2,2,size.x-4,26),Color("292929"))
	draw_line(Vector2(2,28),Vector2(size.x-2,28),Color("737777"),1)
	var font := get_theme_default_font()
	draw_string(font,Vector2(35,21),caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-48,17,Color("e0e4e2"))
	var ink := Color("46edee") if active else Color("c3cccc")
	# Small bitmap-like title icons; no decorative inactive close buttons.
	draw_rect(Rect2(10,8,15,14),ink,false,2)
	if caption == "人物":
		draw_rect(Rect2(15,10,5,4),ink)
		draw_rect(Rect2(13,16,9,4),ink)
	elif caption == "对话记录":
		draw_rect(Rect2(13,12,9,2),ink)
		draw_rect(Rect2(13,16,6,2),ink)
		draw_rect(Rect2(12,22,3,3),ink)
	elif caption == "任务":
		draw_line(Vector2(13,15),Vector2(16,18),ink,2)
		draw_line(Vector2(16,18),Vector2(22,11),ink,2)
	else:
		draw_rect(Rect2(14,12,7,6),ink,false,1)
	for y in range(4,27,3):
		draw_line(Vector2(30,y),Vector2(size.x-4,y),Color(1,1,1,0.025),1)
	# Bottom-right stepped resize grip.
	for i in range(3):
		draw_rect(Rect2(size.x-5-i*4,size.y-5,2,2),ink)
		draw_rect(Rect2(size.x-5,size.y-5-i*4,2,2),ink)

func raise_window() -> void:
	for sibling in get_parent().get_children():
		if sibling.get_script() == get_script():
			sibling.active = sibling == self
			sibling.refresh_frame()
	get_parent().move_child(self,get_parent().get_child_count()-1)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		raise_window()
		if event.button_index == MOUSE_BUTTON_LEFT and event.position.y < 28:
			start_manipulation(Vector2.ZERO)
			accept_event()

func bind_controls(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed: raise_window()
			)
		bind_controls(child)

static func wrap(parent: Control, bounds: Rect2, title: String, offset := Vector2.ZERO) -> Panel:
	var window = load("res://scripts/terminal_window.gd").new()
	window.caption = title
	window.position = bounds.position-Vector2(0,28)+offset
	window.size = bounds.size+Vector2(0,28)
	window.name = "Terminal_"+title
	var candidates: Array[Control] = []
	for child in parent.get_children():
		if child is Control and bounds.has_point(child.position) and child.size.x <= bounds.size.x+2 and child.size.y <= bounds.size.y+2:
			candidates.append(child)
	parent.add_child(window)
	window.base_content_size = bounds.size
	window.minimum_size = Vector2(maxf(220,bounds.size.x*0.8),maxf(90,bounds.size.y*0.8+28))
	window.content = Control.new()
	window.content.position = Vector2(0,28)
	window.content.size = bounds.size
	window.content.mouse_filter = Control.MOUSE_FILTER_PASS
	window.add_child(window.content)
	for child in candidates:
		var old_position := child.position
		child.reparent(window.content,false)
		child.position = old_position-bounds.position
	window.bind_controls(window)
	window.add_resize_handles()
	return window
