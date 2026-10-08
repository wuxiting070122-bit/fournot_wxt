extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/feedback_"+name+".png")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.enter_hallway()
	app.finish_dialogue()
	app.choose_group(0)
	app.finish_dialogue()
	await shot("team")
	app.cancel_group()
	app.toggle_pause()
	await shot("settings")
	app.toggle_pause()
	app.group_id = 0
	app.enter_meeting()
	app.finish_dialogue()
	app.archive.on_next()
	app.battle.submit("letter","我好喜欢你。")
	app.battle.submit("letter","我好喜欢你。")
	app.archive.refresh()
	await shot("hint")
	app.close_archive()
	app.enter_hallway()
	app.world.player.sprite.set_motion(Vector2.DOWN,true)
	app.world.player.set_physics_process(false)
	for i in range(8):
		app.world.player.sprite.pause()
		app.world.player.sprite.frame = i
		await shot("walk_%d" % i)
	print("PASS: GUI team/settings/hints and eight walk phases rendered")
	quit()
