extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_new_game()
	assert(app.dialogues.intro[5].speaker == "旁白")
	assert(app.dialogues.intro[5].text.contains("人物介绍"))
	assert(app.screen.get_child(app.screen.get_child_count()-1) is Button)
	app.toggle_pause()
	var menu = app.pause_layer
	assert(app.paused)
	var identities = load("res://scripts/dialogue_portraits.gd").new()
	for entry in menu.PROFILES:
		menu.select_profile(entry.id)
		assert(menu.profile_title.text == entry.name.replace(" · ","\n"))
		assert(menu.portrait.texture != null)
		if entry.id != "daixingzhe":
			assert(identities.identify(entry.name) == entry.id)
			assert(menu.portrait.texture.resource_path == "res://assets/portraits/%s.png" % entry.id)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/output/profile_%s.png" % entry.id)
	menu.show_history()
	assert(menu.content.visible and not menu.profile_view.visible)
	menu.show_profiles()
	assert(not menu.content.visible and menu.profile_view.visible)
	menu.select_profile("laozhou")
	assert(not menu.profile_title.text.contains("律师"))
	app.meeting_done = true
	menu.select_profile("laozhou")
	assert(menu.profile_title.text.contains("律师"))
	identities.free()
	print("PASS: intro narrator and settings access; eight portraits and identities; history switching; lawyer identity unlocked after meeting")
	quit()
