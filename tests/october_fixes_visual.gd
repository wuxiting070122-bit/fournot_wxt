extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id = 0
	app.enter_cold(false)
	await process_frame
	await process_frame
	app.set_objective("带留守同伴回到冷库门，与另一人会合。\n靠近门后按 E 合力推开。")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-task-fixed.png")
	var world = app.world
	world.door_open = true
	world.hidden_room.hide()
	world.camera.limit_right = 3000
	world.camera.limit_top = 380
	world.player.position = Vector2(1860,1010)
	world.camera.reset_smoothing()
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-door-fixed.png")
	print("PASS: task and door screenshots")
	quit()
