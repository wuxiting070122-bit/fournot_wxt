extends "res://scripts/world.gd"

# Source tiles are about 72px; the bedroom uses about 64px.
const MAP_SCALE := 64.0 / 72.0
var camera: Camera2D

func point(x: float, y: float) -> Vector2:
	return Vector2(x,y)*MAP_SCALE

func _ready() -> void:
	room = "meeting"
	y_sort_enabled = true
	font = load("res://assets/ui_font.tres")
	var art := Sprite2D.new()
	art.name = "Background"
	art.texture = load("res://assets/map_design/meeting/meeting-v1-clues.png")
	art.centered = false
	art.scale = Vector2.ONE*MAP_SCALE
	art.z_index = -5
	add_child(art)
	var lights := preload("res://scripts/ambient_effects.gd").new()
	lights.name = "AmbientLights"
	lights.world = self
	lights.scale = Vector2.ONE * MAP_SCALE
	for lamp in [Vector2(68,151),Vector2(354,73),Vector2(1180,73),Vector2(1464,150),Vector2(67,510),Vector2(123,542),Vector2(1450,560),Vector2(609,900),Vector2(924,900)]:
		lights.lights.append({"pos":lamp,"radius":82.0})
	for candle in [Vector2(588,458),Vector2(945,458)]:
		lights.lights.append({"pos":candle,"flame":true,"size":4.0,"radius":62.0})
	add_child(lights)
	# Source-image footprints; rugs are traversable.
	var blocks := [
		Rect2(0,0,1536,230), Rect2(0,0,70,1024), Rect2(1465,0,71,1024),
		Rect2(0,900,640,124), Rect2(896,900,640,124), Rect2(640,1010,256,14),
		Rect2(510,418,510,205), Rect2(88,380,85,302),
		Rect2(1270,560,156,240), Rect2(1426,573,40,60),
		Rect2(1370,489,58,71), Rect2(1400,804,64,76),
		Rect2(74,706,64,110), Rect2(90,185,62,57),
		Rect2(174,196,58,44), Rect2(1302,191,55,52), Rect2(1382,188,65,55),
		Rect2(536,873,65,103), Rect2(925,873,65,103),
		Rect2(594,840,46,154), Rect2(896,840,46,154)
	]
	for x in [575,683,793,903]:
		blocks.append(Rect2(x,356,59,62))
		blocks.append(Rect2(x,578,59,94))
	for rect in blocks:
		add_wall(Rect2(rect.position*MAP_SCALE,rect.size*MAP_SCALE))
	player = load("res://scripts/player.gd").new()
	player.position = point(768,735)
	add_child(player)
	setup_people()
	camera = Camera2D.new()
	camera.position.y = -155.0
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = roundi(1536*MAP_SCALE)
	camera.limit_bottom = roundi(1024*MAP_SCALE)
	player.add_child(camera)
	camera.make_current()
	targets = [{"id":"meeting_archive","pos":point(768,705),"label":"E · 整理线索 / 继续会谈"}]

func setup_people() -> void:
	var positions := {
		"沈知":Vector2(600,330), "林梢":Vector2(770,330), "小鹿":Vector2(940,330),
		"晚晚":Vector2(565,735), "阿野":Vector2(970,735),
		"老周":Vector2(1140,560), "代行者":Vector2(405,540)
	}
	for person in positions:
		if character_nodes.has(person): continue
		var node := Node2D.new()
		node.position = positions[person]*MAP_SCALE
		node.scale = Vector2(1.8,1.8)
		var visual := preload("res://scripts/character_visual.gd").new()
		visual.character_id = CHARACTER_IDS[person]
		visual.facing = 0 if positions[person].y<400 else 3
		if person=="代行者": visual.facing=2
		if person=="老周": visual.facing=1
		add_child(node)
		node.add_child(visual)
		character_nodes[person]=node

func _draw() -> void: pass
