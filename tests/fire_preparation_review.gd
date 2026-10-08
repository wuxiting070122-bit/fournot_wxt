extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id = 0
	app.enter_cold(false)
	var fire = app.world.get_node("FurnaceFlame")
	assert(fire.z_index < app.world.player.z_index)
	assert(fire.z_index > -5)
	app.world.second_lit = true
	app.enter_meeting()
	assert(app.dialogue_active and app.archive == null)
	assert(app.dialogue_lines == app.dialogues.meeting)
	app.finish_dialogue()
	assert(app.meeting_done and app.archive.mode == "prepare")
	assert(app.archive.notes.contains("他是我父亲请的律师"))
	assert(app.archive.clues.size() == 6)
	app.archive.on_next()
	assert(app.archive.mode == "battle")
	assert(not app.dialogue_active)
	print("PASS: furnace behind actors, unchanged confrontation, one preparation with six clues and testimony, direct battle entry")
	quit()
