extends "res://scripts/world.gd"

const ART_WIDTH := 864.0
const PERIOD := ART_WIDTH * 2.0
const HOME_X := 158.0
const DOORS := [158.0, 412.0, 669.0]
var camera: Camera2D
var sections: Array[Node2D] = []

func _ready() -> void:
	room = "hallway"
	y_sort_enabled = true
	font = load("res://assets/ui_font.tres")
	# A repeating strip has north/south boundaries but no east/west walls.
	for i in range(3):
		var section := Node2D.new()
		section.y_sort_enabled = true
		add_child(section)
		sections.append(section)
		for panel in range(2):
			var art := Sprite2D.new()
			art.texture = load("res://assets/hallway_loop.png")
			art.position.x = panel * ART_WIDTH
			art.centered = false
			art.scale = Vector2(864.0/1536.0,624.0/1024.0)
			art.z_index = -5
			section.add_child(art)
			var shader := Shader.new()
			shader.code = """shader_type canvas_item;
	void fragment(){
	 vec4 base=texture(TEXTURE,UV);
	 float edge=min(UV.x,1.0-UV.x);
	 vec4 opposite=texture(TEXTURE,vec2(1.0-UV.x,UV.y));
	 COLOR=mix(base,opposite,0.5*(1.0-smoothstep(0.0,0.012,edge)));
	}"""
			var material_resource := ShaderMaterial.new()
			material_resource.shader = shader
			art.material = material_resource
			var lights := preload("res://scripts/ambient_effects.gd").new()
			lights.world = self
			lights.position.x = panel * ART_WIDTH
			lights.scale = art.scale
			lights.time = panel * 1.3
			lights.lights = [{"pos":Vector2(516,182),"radius":92.0},{"pos":Vector2(961,182),"radius":92.0}]
			section.add_child(lights)
		for rect in [Rect2(0,-100,PERIOD,315),Rect2(0,560,PERIOD,200)]:
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 2
			var collider := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = rect.size
			collider.shape = shape
			collider.position = rect.get_center()
			body.add_child(collider)
			section.add_child(body)
		var positions := {"林梢":Vector2(243,365),"沈知":Vector2(287,365),"小鹿":Vector2(448,365),"老周":Vector2(492,365),"阿野":Vector2(653,365),"晚晚":Vector2(697,365)}
		for person in positions:
			var node := Node2D.new()
			node.position = positions[person]
			node.scale = Vector2(1.8,1.8)
			var visual := preload("res://scripts/character_visual.gd").new()
			visual.character_id = CHARACTER_IDS[person]
			section.add_child(node)
			node.add_child(visual)
			if i==1: character_nodes[person]=node
	player = load("res://scripts/player.gd").new()
	player.position = Vector2(HOME_X,246)
	add_child(player)
	camera = Camera2D.new()
	camera.position.x = 160.0
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = -10000000
	camera.limit_right = 10000000
	camera.limit_top = 0
	camera.limit_bottom = 624
	player.add_child(camera)
	camera.make_current()
	update_sections()

func setup_people() -> void: pass
func _draw() -> void: pass

func update_sections() -> void:
	var cycle := floori(player.position.x/PERIOD)
	targets.clear()
	for i in range(3):
		var offset := (cycle+i-1)*PERIOD
		sections[i].position.x = offset
		for panel in range(2):
			for door in range(DOORS.size()):
				var is_home := panel==0 and door==0
				targets.append({"id":"home_door" if is_home else "locked_door","pos":Vector2(DOORS[door]+panel*ART_WIDTH+offset,246),"label":"E · 返回卧室" if is_home else "E · 查看房门"})
		for group in range(3):
			targets.append({"id":"group_%d"%group,"pos":Vector2(265+group*205+offset,390),"label":"E · 选择同行者"})

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	update_sections()
	super._physics_process(delta)
	camera.offset.x = lerpf(camera.offset.x,player.velocity.normalized().x*28,1.0-exp(-delta*4))
