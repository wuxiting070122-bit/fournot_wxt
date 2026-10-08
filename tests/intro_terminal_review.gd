extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_new_game()
	var terminal = app.screen.get_node("IntroTerminal")
	terminal.set_process(false)
	assert(not app.dialogue_active)
	assert(app.dialog == null)
	assert(terminal.find_children("*", "Button", true, false).is_empty())
	terminal._process(0.5)
	assert(terminal.character_count == 1)
	app.toggle_pause()
	terminal._process(10.0)
	assert(terminal.character_count == 1)
	app.toggle_pause()
	var retained := false
	var saw_last := false
	for i in range(4000):
		if app.stage != "intro": break
		terminal._process(0.25)
		if terminal.phase == "name_input":
			terminal.submit_name("   ")
			assert(terminal.phase == "name_input")
			terminal.submit_name("测试画家")
			assert(app.player_name == "测试画家")
		assert(terminal.phase != "erase")
		if app.stage == "intro":
			terminal.update_scroll(0.0)
			var last_center: float = terminal.transcript.position.y + terminal.body.position.y + terminal.body.get_minimum_size().y - terminal.body.get_line_height()*0.5
			assert(absf(last_center - terminal.size.y*0.5) < 1.0)
			if terminal.line_index == 5 and terminal.phase == "hold" and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://tests/output/intro_centered.png")
		if terminal.line_index > 0:
			retained = terminal.history.contains(app.dialogues.intro[0].text)
			assert(retained)
		saw_last = saw_last or terminal.line_index == terminal.lines.size() - 1
	assert(retained and saw_last)
	assert(app.stage == "bedroom")
	assert(is_instance_valid(app.world))
	assert(app.capture_save().player_name == "测试画家")
	print("PASS: terminal typing, no dialogue/buttons, pause, retained terminal history, all recap lines, automatic bedroom transition")
	quit()
