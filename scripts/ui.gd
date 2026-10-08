extends RefCounted

const INK = Color("e0e7eb")
const MUTED = Color("9caaa5")
const GOLD = Color("b7ccd6")
const TEAL = Color("81d6c8")

static func box(color: Color, border := Color("737777"), radius := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("080808") if color.a >= 0.99 and color.get_luminance() < 0.08 else color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func panel(parent: Node, rect: Rect2, color := Color("080808")) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color))
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, rect: Rect2, font_size := 20, color := INK) -> Label:
	var node := Label.new()
	node.position = rect.position
	node.size = rect.size
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, rect: Rect2, callback: Callable, accent := false) -> Button:
	var node := Button.new()
	node.position = rect.position
	node.size = rect.size
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_color_override("font_color", Color("071015") if accent else INK)
	node.add_theme_stylebox_override("normal", box(TEAL if accent else Color("151515")))
	node.add_theme_stylebox_override("hover", box(Color("c5e3eb") if accent else Color("303030"), GOLD))
	node.add_theme_stylebox_override("pressed", box(Color("527582")))
	node.add_theme_stylebox_override("disabled", box(Color("101010"),Color("404040")))
	node.add_theme_color_override("font_disabled_color",Color("69747d"))
	node.add_theme_stylebox_override("focus",box(Color(0,0,0,0),TEAL))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

static func bar(parent: Node, rect: Rect2, color := TEAL) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = rect.position
	node.size = rect.size
	node.max_value = 100
	node.show_percentage = false
	node.add_theme_stylebox_override("background",box(Color("080808"),Color("737777"),4))
	node.add_theme_stylebox_override("fill",box(color,color,4))
	parent.add_child(node)
	return node

# Fixed terminal chrome for modal surfaces and the system status bar.
static func terminal_panel(parent: Node, rect: Rect2, caption: String, active := false) -> Panel:
	var node := panel(parent,rect,Color("080808"))
	node.add_theme_stylebox_override("panel",box(Color("080808"),TEAL if active else Color("737777")))
	node.draw.connect(func():
		node.draw_rect(Rect2(2,2,node.size.x-4,27),Color("242424"))
		for y in range(4,27,3):
			node.draw_line(Vector2(2,y),Vector2(node.size.x-2,y),Color(0.8,0.9,0.9,0.045))
		node.draw_line(Vector2(2,29),Vector2(node.size.x-2,29),TEAL if active else Color("737777"))
		node.draw_rect(Rect2(10,9,12,12),TEAL if active else INK,false,2)
		node.draw_rect(Rect2(14,13,4,4),TEAL if active else INK)
	)
	label(node,caption,Rect2(32,3,rect.size.x-42,24),17,TEAL if active else INK)
	return node

static func terminal_button(parent: Node, text: String, rect: Rect2, callback: Callable) -> Button:
	var node := button(parent,text,rect,callback)
	node.add_theme_color_override("font_color",TEAL)
	node.add_theme_stylebox_override("normal",box(Color("080808"),Color("59726e")))
	node.add_theme_stylebox_override("hover",box(Color("152521"),TEAL))
	node.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := node.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		node.add_theme_stylebox_override(state,style)
	return node
