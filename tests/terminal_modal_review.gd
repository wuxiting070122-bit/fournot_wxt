extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.save_enabled = false
	app.enter_hallway()
	await process_frame
	app.play_dialogue([{"speaker":"小鹿","text":"选我们？有眼光。外头要是真有什么东西扑出来，我负责喊，老周负责挡。"}],func(): pass)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-dialogue-terminal.png")
	assert(app.speech_label.text.begins_with("> "))
	app.toggle_pause()
	await process_frame
	var menu = app.pause_layer
	for entry in menu.PROFILES:
		menu.select_profile(entry.id)
		assert(menu.portrait.texture != null)
	menu.select_profile("heroine")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-settings-terminal.png")
	menu.show_history()
	assert(menu.content.visible and not menu.profile_view.visible)
	menu.show_profiles()
	assert(menu.profile_view.visible and not menu.content.visible)
	app.toggle_pause()
	assert(not app.paused and app.dialogue_active)
	app.finish_dialogue()
	assert(not app.dialogue_active)
	print("PASS: terminal dialogue, settings profiles/history, pause/resume")
	quit()
