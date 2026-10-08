extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle = load("res://scripts/persuasion.gd").new()
	var panel = load("res://scripts/evidence_panel.gd").new()
	panel.battle = battle
	panel.mode = "battle"
	panel.clues = JSON.parse_string(FileAccess.get_file_as_string("res://data/clues.json"))
	panel.notes = "林梢说：“他是我父亲请的律师。”"
	root.add_child(panel)
	await process_frame
	for i in range(3): battle.submit("book","错误信息。")
	assert(battle.errors[0] == 3)
	panel.refresh()
	var hint: Array = panel.exact_hint()
	assert(hint[1].contains("警方尚未公布三人的具体死因"))
	panel.show_exact_hint()
	assert(is_instance_valid(panel.hint_popup))
	battle.submit("fire",hint[1])
	assert(battle.errors[0] == 0)
	for round_id in range(3):
		battle.round_index = round_id
		battle.skip_round_for_evaluation()
		assert(battle.gate_complete())
	assert(battle.won())
	print("PASS: third-error exact sentence, success resets streak, skip satisfies all gates and final vote threshold")
	quit()
