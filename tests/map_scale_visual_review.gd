extends SceneTree
func _initialize() -> void: call_deferred("run")
func screenshot(name: String) -> void:
	for i in range(40): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/"+name+".png")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.enter_bedroom()
	app.finish_dialogue()
	await screenshot("bedroom_fixed")
	app.group_id = 0
	app.enter_cold(false)
	app.finish_dialogue()
	app.world.lights_on = true
	app.world.player.position = Vector2(620,910)
	await screenshot("cold_top_interaction_hint")
	app.world.story.emit(app.world.door_open_dialogue(),func(): pass)
	await screenshot("cold_door_conversation")
	quit()
