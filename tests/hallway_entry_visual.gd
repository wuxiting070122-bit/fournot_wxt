extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.save_enabled=false
	app.enter_hallway()
	app.finish_dialogue()
	for i in range(45): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/hallway_entry_right.png")
	quit()
