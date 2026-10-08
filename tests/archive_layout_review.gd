extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.enter_hallway()
	app.finish_dialogue()
	for i in range(5): await physics_frame
	app.group_id = 0
	app.enter_cold(false)
	for i in range(5): await physics_frame
	app.enter_reunion()
	app.finish_dialogue()
	for i in range(30): await physics_frame
	print("ROOT ",root.canvas_transform," ARCHIVE ",app.archive.get_global_transform_with_canvas()," WORLD VIEWPORT ",app.world.get_viewport().get_path()," CAMERA VIEWPORT ",app.world.camera.get_viewport().get_path())
	assert(app.archive.get_global_transform_with_canvas().origin.is_equal_approx(Vector2.ZERO))
	# Reproduce a leaked world-camera translation and verify UI isolation.
	root.canvas_transform = Transform2D(0.0, Vector2(-74,-114))
	assert(app.archive.get_global_transform_with_canvas().origin.is_equal_approx(Vector2.ZERO))
	app.toggle_pause()
	assert(app.pause_layer.get_parent() == app.archive.get_parent())
	assert(app.pause_layer.z_index > app.archive.z_index)
	app.toggle_pause()
	root.canvas_transform = Transform2D.IDENTITY
	print("PASS: archive fixed at screen origin despite camera translation; pause above archive")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/output/archive_layout.png")
	quit()
