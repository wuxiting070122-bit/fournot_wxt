extends "res://scripts/world.gd"

signal message(text: String)
signal story(lines: Array, completion: Callable)
signal objective(text: String)

var navigation = preload("res://scripts/companion_navigation.gd").new()
var navigation_walls: Array = []
var companion_routes: Dictionary = {}
var camera: Camera2D
var gate: StaticBody2D
var hidden_room: ColorRect
var door_seen := false
var recruited := false
var two_tried := false
var furnace_checked := false
var companions_waiting := false
var return_trail: Array[Vector2] = []
var door_open := false
var opening := false
var door_slide := 0.0
var ember_box := false
var ember := false
var second_lit := false
var wind_time := 0.0
var wind_active := false
var search_points: Array[Vector2] = []
var searched: Dictionary = {}
var trail: Array[Vector2] = []
var guide_label: Label
var fx: Node2D
var ambient: Node2D
var detail_material: ShaderMaterial
const SCALE := 2.0
const SECOND := Vector2(2180,740)
const DOOR := Vector2(1910,1130)
const VENT := Rect2(1110,1395,155,100)
const EVIDENCE_INDEX := 10

func point(x: float, y: float) -> Vector2: return Vector2(x,y)*SCALE
func wall(x: float,y: float,w: float,h: float) -> void:
	var rect := Rect2(x*2,y*2,w*2,h*2)
	navigation_walls.append(rect)
	add_wall(rect)

func _ready() -> void:
	room = "cold"
	y_sort_enabled = true
	font = load("res://assets/ui_font.tres")
	normal_cold_rate = 1.6 * 1.4
	ice_cold_rate = 3.4 * 1.4
	warmth_rate = 28.0
	furnace = point(158,718)
	ice = [Rect2(1030,1400,390,90),Rect2(2400,980,380,130),Rect2(2750,650,155,140)]
	var art := Sprite2D.new()
	art.name = "Background"
	art.texture = load("res://assets/cold_large.png")
	art.centered = false
	art.scale = Vector2(2,2)
	art.z_index = -5
	add_child(art)
	detail_material = ShaderMaterial.new()
	detail_material.shader = preload("res://scripts/cold_detail_motion.gdshader")
	art.material = detail_material
	# Trace floor-facing edges of the artwork, in source-image coordinates.
	wall(0,0,990,400)
	# The strip behind the first cabinet row is floor, not wall.
	wall(60,400,45,50)
	wall(205,365,82,79)
	wall(294,407,36,32)
	wall(930,400,45,50)
	wall(56,440,20,172) # Left-wall pipe bends onto the floor.
	wall(436,400,12,22)
	wall(525,400,13,22)
	wall(0,0,60,1024)
	wall(0,750,1536,274)
	wall(1480,0,56,1024)
	wall(990,0,546,320)
	wall(975,320,42,130)
	wall(975,590,42,160)
	wall(238,460,641,92)
	wall(207,480,31,61)
	wall(879,485,21,54)
	wall(290,600,539,96)
	wall(264,619,26,63)
	wall(829,620,22,65)
	wall(60,605,46,116)
	wall(106,648,40,65)
	wall(146,684,42,32)
	wall(1018,320,22,160)
	wall(1020,665,40,80)
	wall(1128,400,240,85)
	wall(1130,544,240,115)
	# Separate drums and crates instead of blocking the entire corner.
	wall(1387,704,32,40)
	wall(1450,634,28,67)
	wall(1420,707,58,37)
	wall(1110,302,37,63)
	wall(1107,438,21,47)
	wall(1368,429,15,59)
	wall(1132,532,28,12)
	wall(1370,577,14,72)
	wall(1060,690,40,54)
	wall(1455,330,25,330)
	wall(1040,320,73,43)
	gate = StaticBody2D.new()
	gate.collision_layer = 1
	gate.collision_mask = 2
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = point(42,140)
	collider.shape = shape
	collider.position = point(996,520)
	gate.add_child(collider)
	add_child(gate)
	rebuild_navigation()
	player = load("res://scripts/player.gd").new()
	player.position = point(210,735)
	player.speed = 240
	add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	camera.limit_left = 60
	camera.limit_right = 1980
	camera.limit_top = 620
	camera.limit_bottom = 1536
	player.add_child(camera)
	camera.make_current()
	search_points = [point(280,576),point(450,576),point(650,576),point(820,576),point(360,725),point(740,725),point(1180,510),point(1320,510),point(1200,690),point(1320,690),point(1420,349)]
	setup_darkness()
	hidden_room = ColorRect.new()
	hidden_room.position = point(1000,190)
	hidden_room.size = point(505,580)
	hidden_room.color = Color("071113")
	hidden_room.z_index = 11
	hidden_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hidden_room)
	fx = Node2D.new()
	fx.z_index = 3
	fx.draw.connect(draw_effects)
	add_child(fx)
	ambient = preload("res://scripts/ambient_effects.gd").new()
	ambient.name = "FurnaceFlame"
	ambient.world = self
	ambient.scale = Vector2(2,2)
	ambient.lights = [
		{"pos":Vector2(124,702),"flame":true,"size":6.0,"radius":75.0},
		{"pos":Vector2(1080,337),"flame":true,"size":10.0,"radius":95.0,"gate":"second"},
		{"pos":Vector2(78,646),"radius":50.0},
		{"pos":Vector2(413,355),"radius":65.0,"gate":"electric"},
		{"pos":Vector2(567,355),"radius":65.0,"gate":"electric"},
		{"pos":Vector2(802,355),"radius":65.0,"gate":"electric"}
	]
	add_child(ambient)

func setup_darkness() -> void:
	dark = ColorRect.new()
	dark.size = Vector2(3072,2048)
	dark.z_index = 10
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec2 player_pos;
uniform bool lit=false;
uniform bool second=false;
uniform float flame_time=0.0;
void fragment(){
 vec2 p=UV*vec2(3072.0,2048.0);
 float personal=1.0-smoothstep(65.0,220.0,distance(p,player_pos));
 float flicker=sin(flame_time*2.1)*7.0+sin(flame_time*5.7)*3.0;
 float warm=1.0-smoothstep(80.0,260.0+flicker,distance(p,vec2(316.0+sin(flame_time*1.9)*3.0,1436.0)));
 float warm2=second?1.0-smoothstep(80.0,270.0+flicker,distance(p,vec2(2180.0,740.0))):0.0;
 float base=(lit && p.x<1980.0)?0.12:0.97;
 COLOR=vec4(0.015,0.025,0.03,base*(1.0-max(personal,max(warm,warm2))*0.94));
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	dark.material = mat
	add_child(dark)

func setup_people() -> void:
	if companions.size()!=2: return
	for i in range(2):
		var person: String = str(companions[i])
		if character_nodes.has(person): continue
		var node := CharacterBody2D.new()
		node.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		node.collision_layer = 2
		node.collision_mask = 1
		node.position = point(210+i*40,720)
		node.scale = Vector2(1.8,1.8)
		var visual := preload("res://scripts/character_visual.gd").new()
		visual.character_id = CHARACTER_IDS[person]
		add_child(node)
		node.add_child(visual)
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(44,20)/1.8
		collider.shape = shape
		collider.position = Vector2(0,-8)/1.8
		node.add_child(collider)
		character_nodes[person] = node

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	setup_people()
	player.active = active and not failed and not opening
	if active and not failed and not opening:
		wind_time += delta
		wind_active = fmod(wind_time,6.0)<2.0
		if ember and wind_active and VENT.has_point(player.position):
			ember = false
			message.emit("冷风吹灭了火种。回入口火炉旁按 E，重新装入火种。")
			update_fire_objective()
		if not door_seen and empty_outer_cabinets() >= 3:
			discover_door()
		advance_cold(delta)
		update_followers(delta)
	camera.offset = camera.offset.lerp(player.velocity.normalized()*42,1.0-exp(-delta*3))
	dark.material.set_shader_parameter("player_pos",player.position)
	dark.material.set_shader_parameter("lit",lights_on)
	dark.material.set_shader_parameter("second",second_lit)
	dark.material.set_shader_parameter("flame_time",floor(ambient.time*10.0)/10.0)
	detail_material.set_shader_parameter("phase",floor(ambient.time*10.0)/10.0)
	detail_material.set_shader_parameter("gust",1.0 if wind_active else 0.0)
	refresh_targets()
	nearest = ""
	hint = ""
	var best := 95.0
	for target in targets:
		var distance: float = player.position.distance_to(target.pos)
		if distance<best:
			best=distance
			nearest=target.id
			hint=target.label
	if ember and hint.is_empty(): hint = "已携带火种 · 避开喷出的冷风"
	fx.queue_redraw()

func update_followers(delta: float) -> void:
	if companions.size()!=2 or opening: return
	if trail.is_empty() or trail.back().distance_to(player.position)>5:
		trail.append(player.position)
	while trail.size()>180: trail.pop_front()
	for i in range(2):
		var node: Node2D = character_nodes[str(companions[i])]
		var target := node.position
		if companions_waiting:
			target = point(935,490+i*45)
		elif i == 0 and door_seen and not door_open:
			target = DOOR + Vector2(-55,-45)
		elif recruited or (i == 0 and not door_seen):
			target = trail[maxi(0,trail.size()-1-(i+1)*13)]
		move_companion(node,target,delta)

func rebuild_navigation() -> void:
	var rectangles := navigation_walls.duplicate()
	if not door_open: rectangles.append(Rect2(1950,900,84,280))
	navigation.rebuild(rectangles)
	companion_routes.clear()

func move_companion(node: CharacterBody2D, target: Vector2, delta: float) -> void:
	var key := node.get_instance_id()
	var route: Dictionary = companion_routes.get(key,{"goal":Vector2.INF,"points":PackedVector2Array(),"time":0.0})
	route.time -= delta
	if route.goal.distance_to(target)>32 or (route.points.is_empty() and node.position.distance_to(target)>24 and route.time<=0):
		route.goal = target
		route.points = navigation.route(node.position,target)
		route.time = 0.5
	while not route.points.is_empty() and node.position.distance_to(route.points[0])<3:
		route.points.remove_at(0)
	var before := node.position
	if not route.points.is_empty():
		var direction: Vector2 = route.points[0]-node.position
		node.move_and_collide(direction.normalized()*minf(player.speed*delta,direction.length()))
	var movement := node.position-before
	node.get_child(0).set_motion(movement,movement.length_squared()>0.01)
	companion_routes[key] = route

func refresh_targets() -> void:
	targets = [{"id":"cold_exit","pos":point(98,733),"label":"E · 返回门外"}]
	if not lights_on: targets.append({"id":"switch","pos":point(152,668),"label":"E · 打开冷藏区照明"})
	if not ember_box: targets.append({"id":"ember_box","pos":point(310,450),"label":"E · 查看金属盒"})
	if ember_box and not second_lit: targets.append({"id":"take_ember","pos":furnace,"label":"E · 从火炉取火"})
	if not door_open: targets.append({"id":"heavy_door","pos":DOOR,"label":"E · 推冷库门"})
	if door_seen and not recruited and companions.size()==2:
		if not two_tried and character_nodes[str(companions[0])].position.distance_to(DOOR) < 100:
			targets.append({"id":"inspect_door","pos":character_nodes[str(companions[0])].position,"label":"E · 和同伴查看异常"})
		elif two_tried:
			targets.append({"id":"recruit","pos":character_nodes[str(companions[1])].position,"label":"E · 请留守的同伴帮忙"})
	if door_open and not second_lit: targets.append({"id":"second_furnace","pos":SECOND,"label":"E · 检查火炉"})
	for i in range(search_points.size()):
		if i>=6 and not door_open: continue
		targets.append({"id":"search_%d" % i,"pos":search_points[i],"label":"E · 调查柜子"})

func interact_nearest() -> void:
	if not active or failed or opening or nearest.is_empty(): return
	if nearest.begins_with("search_"):
		var index := int(nearest.trim_prefix("search_"))
		if index==EVIDENCE_INDEX and not case_taken:
			case_taken=true
			interaction.emit("case")
		else:
			var responses := ["什么都没有。","只有冷藏的鲜肉，没有有用的信息。","空罐与结霜的托盘，没有有用的信息。","柜门内侧覆满冰霜，没有发现线索。"]
			message.emit("已经检查过，没有其他有用的信息。" if searched.has(index) else responses[index%responses.size()])
		searched[index]=true
		return
	match nearest:
		"ember_box":
			ember_box=true
			message.emit("已取得火种盒。回入口火炉旁按 E 装入火种。")
			update_fire_objective()
		"take_ember":
			ember=true
			message.emit("火种已装入盒中，会随你携带。注意避开冷风。")
			update_fire_objective()
		"heavy_door", "inspect_door":
			if recruited:
				open_with_companions()
			elif not door_seen:
				discover_door()
			elif not two_tried:
				two_tried = true
				objective.emit("两个人推不开门。\n回入口找留守的同伴，一起过来。")
				story.emit([{"speaker":str(companions[0]),"text":"门缝后面还有空间。来，我们一起推一下。"},{"speaker":"你","text":"还是卡着……两个人也不够。得回入口叫上另一位。"}],func(): pass)
			else:
				message.emit("两个人推不开，回入口叫上留守的同伴。")
		"recruit":
			story.emit([{"speaker":"你","text":"我们两个人试过了，深处的门还是推不开。一起过去帮把手吧。"},{"speaker":str(companions[1]),"text":"好，我跟你过去。先在炉边缓一缓。"}],func():
				recruited=true
				trail.clear()
				# Seed the trail through their starting positions, then the player's path.
				trail.append(character_nodes[str(companions[1])].position)
				trail.append(player.position)
				objective.emit("带留守同伴回到冷库门，与另一人会合。\n靠近门后按 E 合力推开。"))
		"second_furnace":
			var first_check := not furnace_checked
			furnace_checked = true
			if ember:
				second_lit=true
				ember=false
				message.emit("第二个火炉燃起了。可以在这里回暖。")
				objective.emit("搜索深冷库里的柜子。\n寒冷时回到第二个火炉。")
			else:
				message.emit("炉内已有燃料，但缺少火种。需要从入口火炉运来。")
				update_fire_objective()
			if first_check:
				story.emit([{"speaker":str(companions[0]),"text":"这里太冷了，我们去外面再找找有没有遗漏的东西。"},{"speaker":str(companions[1]),"text":"我们就在冷库门外等你。要是没火种，记得回入口的火炉取。"}],func():
					companions_waiting = true
					return_trail.clear()
					for at in range(trail.size()-1,-1,-1):
						return_trail.append(trail[at])
						if trail[at].x < DOOR.x: break)
		_:
			interaction.emit(nearest)

func open_with_companions() -> void:
	opening=true
	story.emit([{"speaker":"你","text":"来，一起用力。三、二、一——"}],func(): animate_door())

func animate_door() -> void:
	# Walk to push positions with the same collision rules as exploration.
	for step in range(1200):
		await get_tree().physics_frame
		var arrived := true
		for i in range(companions.size()):
			var person: CharacterBody2D = character_nodes[str(companions[i])]
			var destination := point(940,505+i*45)
			move_companion(person,destination,get_physics_process_delta_time())
			if person.position.distance_to(destination)>24: arrived=false
		if arrived: break
		if step == 1199:
			opening=false
			message.emit("同伴还没走到门边，靠近同伴后再一起过来。")
			return
	var slide := create_tween()
	slide.tween_property(self,"door_slide",1.0,0.7)
	await slide.finished
	gate.collision_layer=0
	door_open=true
	rebuild_navigation()
	hidden_room.hide()
	camera.limit_right=3000
	camera.limit_top=380
	opening=false
	story.emit(door_open_dialogue(),func():
		update_fire_objective())

func update_fire_objective() -> void:
	if not door_seen:
		objective.emit("和同伴一起搜索冷藏柜。\n记住入口火炉的位置。")
	elif second_lit:
		objective.emit("搜索深冷库里的柜子。\n寒冷时回到第二个火炉。")
	elif door_seen and not door_open:
		objective.emit("带同伴到门边合力推门。" if recruited else ("回入口叫上留守同伴，再来推门。" if two_tried else "和同伴一起搜索冷藏柜。\n记住入口火炉的位置。"))
	elif door_open and not furnace_checked:
		objective.emit("和同伴一起进入深冷库。\n检查并点燃左上方的内部火炉。")
	elif not ember_box:
		objective.emit("找到火种盒：第一排冷冻柜上方、靠墙置物架右边。\n靠近金属盒按 E 拿取。")
	elif not ember:
		objective.emit("回到入口左下方的火炉。\n靠近后按 E，将火种装进盒子。")
	elif not door_open:
		objective.emit("火种已携带。\n带同伴合力推开深处的门。")
	else:
		objective.emit("穿过门，沿左侧通路向上走。\n到第二个火炉旁按 E 点燃。\n避开正在喷出的冷风。")

func door_open_dialogue() -> Array:
	return [{"speaker":"你","text":"终于开了。里面没有灯，先一起进去看看。"},{"speaker":str(companions[0]),"text":"左上方像是个火炉。我们靠近看看，能点燃就有地方取暖了。"}]

func empty_outer_cabinets() -> int:
	var count := 0
	for index in searched:
		if int(index) >= 0 and int(index) < 6: count += 1
	return count

func discover_door() -> void:
	if door_seen or companions.size()!=2: return
	door_seen = true
	story.emit([{"speaker":str(companions[0]),"text":"这几个柜子里都没找到线索。那边好像有些异常，跟我来看看。"}],func(): pass)

func capture_state() -> Dictionary:
	var state := {}
	for key in ["door_seen","two_tried","recruited","door_open","ember_box","ember","second_lit","furnace_checked","companions_waiting","lights_on","case_taken","cold","wind_time"]:
		state[key] = get(key)
	state.searched = searched.keys()
	state.people = {}
	for person in character_nodes:
		state.people[person] = [character_nodes[person].position.x,character_nodes[person].position.y]
	state.trail = []
	for p in trail: state.trail.append([p.x,p.y])
	state.return_trail = []
	for p in return_trail: state.return_trail.append([p.x,p.y])
	return state

func restore_state(state: Dictionary) -> void:
	for key in ["door_seen","two_tried","recruited","door_open","ember_box","ember","second_lit","furnace_checked","companions_waiting","lights_on","case_taken","cold","wind_time"]:
		if state.has(key): set(key,state[key])
	for index in state.get("searched",[]): searched[int(index)] = true
	setup_people()
	for person in state.get("people",{}):
		if character_nodes.has(person): character_nodes[person].position = Vector2(state.people[person][0],state.people[person][1])
	trail.clear()
	for p in state.get("trail",[]): trail.append(Vector2(p[0],p[1]))
	return_trail.clear()
	for p in state.get("return_trail",[]): return_trail.append(Vector2(p[0],p[1]))
	if door_open:
		gate.collision_layer = 0
		hidden_room.hide()
		camera.limit_right = 3000
		camera.limit_top = 380
	rebuild_navigation()

func is_warm() -> bool:
	return player.position.distance_to(furnace)<145 or (second_lit and player.position.distance_to(SECOND)<145)

func _draw() -> void: pass

func draw_effects() -> void:
	if door_open or door_slide>0:
		var floor_texture: Texture2D = load("res://assets/cold_large.png")
		# Recessed steel threshold, not a vertically stretched floor tile.
		fx.draw_rect(Rect2(1950,900,85,280),Color("263d48"))
		fx.draw_rect(Rect2(1955,900,75,280),Color("334e59"))
		for speck in range(100):
			var sx := 1957+(speck*37)%70
			var sy := 903+(speck*61)%274
			fx.draw_rect(Rect2(sx,sy,2+(speck%3),2),Color(0.46,0.61,0.64,0.10))
		for bolt_y in [908,1170]:
			for bolt_x in [1959,2024]:
				fx.draw_rect(Rect2(bolt_x,bolt_y,4,4),Color("789096"))
		for seam_y in range(916,1180,24):
			fx.draw_line(Vector2(1957,seam_y),Vector2(2028,seam_y),Color("233641"),2)
		fx.draw_line(Vector2(1953,900),Vector2(1953,1180),Color("6b858b"),3)
		fx.draw_line(Vector2(2032,900),Vector2(2032,1180),Color("152931"),4)
		if not door_open:
			fx.draw_texture_rect_region(floor_texture,Rect2(1950,900-door_slide*280,85,280),Rect2(975,450,42,140))
