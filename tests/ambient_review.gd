extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(12): await process_frame
func snapshot(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/"+filename+".png")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id = 0
	app.enter_cold(false)
	await settle()
	var ambient = app.world.ambient
	assert(not ambient.enabled(ambient.lights[1]))
	assert(not ambient.enabled(ambient.lights[3]))
	assert(ambient.z_index < app.world.player.z_index)
	var prior: float = ambient.time
	ambient._process(0.25)
	assert(ambient.time > prior)
	app.world.active = false
	prior = ambient.time
	ambient._process(0.25)
	assert(ambient.time == prior)
	app.world.active = true
	app.world.lights_on = true
	app.world.second_lit = true
	assert(ambient.enabled(ambient.lights[1]) and ambient.enabled(ambient.lights[3]))
	app.world.door_open = true
	app.world.hidden_room.hide()
	app.world.camera.limit_right = 3000
	app.world.camera.limit_top = 380
	app.world.player.position = Vector2(2160,740)
	app.world.camera.reset_smoothing()
	await settle()
	await snapshot("ambient_furnace")
	app.world.player.position = Vector2(1180,1430)
	app.world.camera.reset_smoothing()
	app.world.wind_time = 0.4
	await settle()
	await snapshot("ambient_wind")
	app.enter_hallway()
	app.finish_dialogue()
	await settle()
	await snapshot("ambient_hallway")
	app.enter_meeting()
	app.finish_dialogue()
	app.close_archive()
	await settle()
	assert(app.world.get_node("AmbientLights").lights.size()==11)
	await snapshot("ambient_meeting")
	print("PASS: stepped animation, pause, light/fire activation gates, actor layering, hallway/meeting render")
	quit()
