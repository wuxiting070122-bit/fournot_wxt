extends Node2D

signal interaction(action: String)
signal cold_changed(value: float, in_warmth: bool, on_ice: bool)
signal frozen

@export_enum("bedroom", "hallway", "cold", "meeting") var room := "bedroom"
@export var normal_cold_rate := 7.5
@export var ice_cold_rate := 15.0
@export var warmth_rate := 24.0
var player: CharacterBody2D
var active := true
var cold := 0.0
var lights_on := false
var case_taken := false
var failed := false
var font: Font
var dark: ColorRect
var targets: Array = []
var obstacles: Array[Rect2] = []
var ice: Array[Rect2] = [Rect2(365, 345, 215, 95), Rect2(600, 200, 154, 135)]
var furnace := Vector2(135, 490)
var hint := ""
var nearest := ""
var companions: Array = []
const BEDROOM_SCALE := 1.0
const CHARACTER_IDS := {"林梢":"linshao","沈知":"shenzhi","晚晚":"wanwan","阿野":"aye","小鹿":"xiaolu","老周":"laozhou","代行者":"daixingzhe"}
var character_nodes: Dictionary = {}

func _ready() -> void:
	# Player and NPC roots use their ground contact point for draw order.
	y_sort_enabled = true
	font = load("res://assets/ui_font.tres")
	if (room == "bedroom" or room == "hallway") and not has_node("Background"):
		var art := Sprite2D.new()
		art.texture = load("res://assets/%s.png" % room)
		art.centered = false
		art.show_behind_parent = true
		add_child(art)
		move_child(art, 0)
	if room in ["bedroom", "hallway"]:
		var layouts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_collisions.json"))
		for rect in layouts[room]:
			add_wall(Rect2(rect[0], rect[1], rect[2], rect[3]))
	else:
		add_wall(Rect2(-20, -20, 904, 58))
		add_wall(Rect2(-20, 595, 904, 40))
		add_wall(Rect2(-20, 0, 74, 624))
		add_wall(Rect2(812, 0, 72, 624))
	# Pixel-art walls do not align with the old 48px passability grid.
	# These continuous inner edges also close gaps between imported tiles.
	var floor_rect := Rect2(60,218,744,344) if room in ["bedroom","hallway"] else Rect2(54,140,758,453)
	add_wall(Rect2(-100,-100,1064,floor_rect.position.y+100))
	add_wall(Rect2(-100,floor_rect.end.y,1064,200))
	add_wall(Rect2(-100,-100,floor_rect.position.x+100,924))
	add_wall(Rect2(floor_rect.end.x,-100,200,924))
	match room:
		"bedroom":
			targets = [{"id":"bedroom_exit","pos":Vector2(130, 246),"label":"E · 推门出去"}]
		"hallway":
			for i in range(3):
				targets.append({"id":"group_%d" % i,"pos":Vector2(265+i*205, 355),"label":"E · 选择同行者"})
		"cold":
			for rect in [Rect2(285, 72, 150, 170),Rect2(295, 478, 220, 75),Rect2(545, 100, 65, 190)]:
				obstacles.append(rect)
				add_wall(rect)
			targets = [{"id":"switch","pos":Vector2(220, 375),"label":"E · 打开照明"},{"id":"case","pos":Vector2(727, 136),"label":"E · 取走案卷"},{"id":"cold_exit","pos":Vector2(76, 527),"label":"E · 返回门外"}]
		"meeting":
			add_wall(Rect2(264, 224, 340, 210))
	player = load("res://scripts/player.gd").new()
	player.position = Vector2(235, 450) if room == "bedroom" else Vector2(130, 490)
	if room == "cold": player.position = Vector2(150, 545)
	if room == "meeting": player.position = Vector2(435, 530)
	add_child(player)
	setup_people()
	if room == "cold": setup_darkness()
	queue_redraw()

func add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func setup_darkness() -> void:
	dark = ColorRect.new()
	dark.size = Vector2(864, 624)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.z_index = 10
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec2 player_pos; uniform bool lit = false; void fragment(){vec2 p=UV*vec2(864.0,624.0); float a=1.0-smoothstep(36.0,148.0,distance(p,player_pos)); float b=1.0-smoothstep(45.0,170.0,distance(p,vec2(135.0,490.0))); float alpha=(lit ? 0.24 : 0.97)*(1.0-max(a,b)*0.92); COLOR=vec4(0.012,0.025,0.035,alpha);}"
	var material_resource := ShaderMaterial.new()
	material_resource.shader = shader
	dark.material = material_resource
	add_child(dark)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	setup_people()
	player.active = active and not failed
	nearest = ""
	hint = ""
	var best := 90.0
	for target in targets:
		if target.id == "case" and case_taken: continue
		if target.id == "switch" and lights_on: continue
		var distance := player.position.distance_to(target.pos)
		if distance < best:
			best = distance
			nearest = target.id
			hint = target.label
	if room == "cold":
		dark.material.set_shader_parameter("player_pos", player.position)
		dark.material.set_shader_parameter("lit", lights_on)
		if active and not failed: advance_cold(delta)
	queue_redraw()

func is_warm() -> bool:
	return player.position.distance_to(furnace) < 100.0

func is_on_ice() -> bool:
	for rect in ice:
		if rect.has_point(player.position): return true
	return false

func advance_cold(delta: float) -> void:
	var warm := is_warm()
	var icy := is_on_ice()
	var rate := -warmth_rate if warm else (ice_cold_rate if icy else normal_cold_rate)
	cold = clampf(cold + rate * delta, 0.0, 100.0)
	cold_changed.emit(cold, warm, icy)
	if cold >= 100.0:
		failed = true
		active = false
		frozen.emit()

func interact_nearest() -> void:
	if active and not failed and not nearest.is_empty(): interaction.emit(nearest)

func _draw() -> void:
	if font == null: return
	if room == "cold" or room == "meeting":
		draw_rect(Rect2(0,0,864,624), Color("152329"))
		draw_rect(Rect2(29,39,806,558), Color("293b3d"))
		for x in range(30,835,52): draw_line(Vector2(x,40),Vector2(x,598),Color("33464a"),1)
		for y in range(40,598,52): draw_line(Vector2(30,y),Vector2(835,y),Color("33464a"),1)
		draw_rect(Rect2(29,39,806,558),Color("84918a"),false,3)
	if room == "cold":
		for rect in ice:
			draw_rect(rect,Color("61878f"))
			for i in range(4):
				var start := rect.position + Vector2(10+i*30,12)
				draw_line(start,start+Vector2(35,rect.size.y-20),Color("8db1b6"),2)
		for rect in obstacles:
			draw_rect(rect,Color("142126"))
			draw_rect(rect.grow(-5),Color("425458"),false,2)
			draw_string(font,rect.position+Vector2(13,35),"冷藏柜",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("9ba6a1"))
		draw_circle(furnace,100,Color(0.7,0.38,0.15,0.1))
		draw_circle(furnace,58,Color(0.9,0.53,0.19,0.14))
		draw_rect(Rect2(furnace-Vector2(23,25),Vector2(46,43)),Color("432e25"))
		draw_circle(furnace-Vector2(0,7),13,Color("e3a461"))
		draw_circle(furnace-Vector2(0,11),7,Color("ffe7a4"))
		draw_string(font,Vector2(102,544),"火炉",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e6bb7e"))
		draw_rect(Rect2(58,513,36,58),Color("907657"),false,2)
		draw_rect(Rect2(209,362,23,27),Color("dfa85c") if not lights_on else Color("79b49e"))
		if lights_on: draw_string(font,Vector2(198,349),"照明",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("bbccca"))
		if not case_taken:
			draw_rect(Rect2(703,114,48,38),Color("ccb98d"))
			draw_line(Vector2(711,126),Vector2(741,126),Color("675945"),2)
			if lights_on: draw_string(font,Vector2(682,99),"密封案卷",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e7d7b0"))
		if companions.size()==2:
			draw_person(Vector2(85,425),str(companions[0]),Color("829b92"))
			draw_person(Vector2(220,535),str(companions[1]),Color("829b92"))
	elif room == "hallway":
		var names := [["林梢","沈知"],["小鹿","老周"],["阿野","晚晚"]]
		for i in range(3):
			for j in range(2): draw_person(Vector2(243+i*205+j*44,330),names[i][j],Color("9da99a"))
	elif room == "meeting":
		draw_rect(Rect2(257,216,354,223),Color("162428"))
		draw_rect(Rect2(264,224,340,210),Color("5e6357"))
		draw_rect(Rect2(278,238,312,182),Color("8c9076"),false,2)
		draw_string(font,Vector2(344,332),"第一轮 · 三次机会",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("dce0c8"))
		var people := ["沈知","林梢","小鹿","老周","阿野","晚晚"]
		var points := [Vector2(245,185),Vector2(435,180),Vector2(625,185),Vector2(672,330),Vector2(630,475),Vector2(230,475)]
		for i in range(6): draw_person(points[i],people[i],Color("bf8c72") if i==3 else Color("a4b9b0"))
		draw_person(Vector2(150,330),"代行者",Color("a4b9b0"))

func draw_person(point: Vector2, person_name: String, color: Color) -> void:
	if not CHARACTER_IDS.has(person_name):
		draw_circle(point-Vector2(0,29),10,color)
		draw_style_box(person_style(color),Rect2(point-Vector2(13,16),Vector2(26,34)))
	draw_string(font,point+Vector2(-28,45),person_name,HORIZONTAL_ALIGNMENT_LEFT,70,17,Color("e1e1ce"))

func person_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.27)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	return style

func setup_people() -> void:
	var positions: Dictionary = {}
	if room == "hallway":
		positions = {"林梢":Vector2(243,330),"沈知":Vector2(287,330),"晚晚":Vector2(697,330),"阿野":Vector2(653,330),"小鹿":Vector2(448,330),"老周":Vector2(492,330)}
	elif room == "meeting":
		positions = {"沈知":Vector2(245,185),"林梢":Vector2(435,180),"晚晚":Vector2(230,475),"阿野":Vector2(630,475),"小鹿":Vector2(625,185),"老周":Vector2(672,330),"代行者":Vector2(150,330)}
	elif room == "cold" and companions.size()==2:
		positions = {str(companions[0]):Vector2(85,425),str(companions[1]):Vector2(220,535)}
	for person in positions:
		if not CHARACTER_IDS.has(person) or character_nodes.has(person): continue
		var root := Node2D.new()
		root.position = positions[person]
		root.scale = Vector2(1.8,1.8)
		var visual := preload("res://scripts/character_visual.gd").new()
		visual.character_id = CHARACTER_IDS[person]
		if room=="meeting": visual.facing=0 if positions[person].y<300 else 3
		if person=="代行者": visual.facing=2
		add_child(root)
		root.add_child(visual)
		character_nodes[person]=root
