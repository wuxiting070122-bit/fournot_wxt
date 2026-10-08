extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id = 0
	app.enter_cold(false)
	var cold = app.world
	cold.setup_people()
	cold.active = false
	assert(not app.objective_label.text.contains("门"))
	cold.lights_on = true
	app.on_interaction("switch")
	app.finish_dialogue()
	assert(not app.objective_label.text.contains("门"))
	cold.active = false
	cold.active = true
	for index in [0,0,1]:
		cold.nearest = "search_%d" % index
		cold.interact_nearest()
	await physics_frame
	assert(cold.empty_outer_cabinets() == 2 and not cold.door_seen)
	cold.nearest = "search_2"
	cold.interact_nearest()
	for tick in range(3): await physics_frame
	assert(cold.door_seen and app.dialogue_active)
	assert(app.dialogue_lines[0].text.contains("跟我来"))
	assert(not app.objective_label.text.contains("异常") and not app.objective_label.text.contains("门"))
	app.finish_dialogue()
	cold.active = false
	var person = cold.character_nodes[cold.companions[0]]
	var target = cold.DOOR+Vector2(-55,-45)
	for tick in range(1000):
		await physics_frame
		cold.move_companion(person,target,1.0/60)
		var footprint = Rect2(person.position-Vector2(21,17),Vector2(42,18))
		for wall in cold.navigation_walls: assert(not footprint.intersects(wall),"Companion crossed furniture")
		if person.position.distance_to(target)<24: break
	assert(person.position.distance_to(target)<24,"Companion did not reach door")
	cold.door_seen = true
	cold.two_tried = true
	cold.active = true
	cold.nearest = "recruit"
	cold.interact_nearest()
	for line in app.dialogue_lines: assert(line.speaker != cold.companions[0])
	app.finish_dialogue()
	cold.active = false
	var waiting_position: Vector2 = person.position
	cold.player.position = Vector2(480,1440)
	for tick in range(20):
		await physics_frame
		cold.update_followers(1.0/60)
	assert(person.position.distance_to(waiting_position)<24,"Door companion followed player back")
	var other = cold.character_nodes[cold.companions[1]]
	for tick in range(1000):
		await physics_frame
		cold.move_companion(other,cold.DOOR-Vector2(80,0),1.0/60)
		if other.position.distance_to(cold.DOOR-Vector2(80,0))<24: break
	assert(other.position.distance_to(cold.DOOR-Vector2(80,0))<24)
	cold.active = true
	cold.nearest = "heavy_door"
	cold.interact_nearest()
	app.finish_dialogue()
	for tick in range(360):
		await physics_frame
		if cold.door_open: break
	assert(cold.door_open,"Door opening blocked")
	assert(cold.player.sprite.material == null)
	print("PASS: hidden objective; two companions navigate cabinet collision; absent companion excluded from recruitment and stays at door; cooperative opening; unwarped walk frames")
	quit()
