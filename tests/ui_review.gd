extends SceneTree
## Development-only entry point for testing native mouse selection in the archive.

func _initialize() -> void:
	call_deferred("start_review")

func start_review() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.group_id = 0
	game.acquired = true
	game.notes = "林梢的门外口述：施工时间是她父亲催着改的。家属反被判赔偿公司，工人的妻子随后自杀。"
	game.enter_meeting()
	game.close_archive()
	game.finish_meeting()
	game.close_archive()
	game.set_meta("battle_started",true)
	game.open_archive()
