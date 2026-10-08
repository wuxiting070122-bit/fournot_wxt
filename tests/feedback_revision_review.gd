extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func settle_dialogue() -> void:
	if app.dialogue_active: app.finish_dialogue()
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.checkpoint_path = "user://feedback_test_save.json"
	app.enter_hallway()
	settle_dialogue()
	for group in range(3):
		app.choose_group(group)
		settle_dialogue()
		assert(app.stage == "hallway" and app.group_id == -1)
		assert(app.pending_group == group)
		app.cancel_group()
	app.choose_group(0)
	settle_dialogue()
	app.accept_group()
	settle_dialogue()
	assert(app.stage == "cold" and app.group_id == 0)
	var cold = app.world
	cold.setup_people()
	assert(is_equal_approx(cold.normal_cold_rate,2.24))
	assert(is_equal_approx(cold.ice_cold_rate,4.76))
	cold.searched[0] = true
	cold.searched[1] = true
	cold.player.position = cold.DOOR-Vector2(200,0)
	await physics_frame
	await physics_frame
	assert(cold.door_seen and app.dialogue_active)
	settle_dialogue()
	cold.nearest = "inspect_door"
	cold.interact_nearest()
	assert(cold.two_tried and not cold.recruited)
	settle_dialogue()
	cold.nearest = "recruit"
	cold.interact_nearest()
	settle_dialogue()
	assert(cold.recruited)
	cold.nearest = "heavy_door"
	cold.interact_nearest()
	settle_dialogue()
	await create_timer(1.6).timeout
	settle_dialogue()
	assert(cold.door_open and not cold.companions_waiting)
	assert(app.objective_label.text.contains("内部火炉"))
	cold.nearest = "second_furnace"
	cold.interact_nearest()
	settle_dialogue()
	assert(cold.furnace_checked and cold.companions_waiting)
	assert(app.objective_label.text.contains("火种盒"))
	cold.nearest = "ember_box"
	cold.interact_nearest()
	assert(app.objective_label.text.contains("入口"))
	cold.nearest = "take_ember"
	cold.interact_nearest()
	cold.nearest = "second_furnace"
	cold.interact_nearest()
	assert(cold.second_lit)
	cold.cold = 42
	cold.player.position = Vector2(2180,800)
	app.toggle_pause()
	assert(app.paused and not cold.active)
	app.set_brightness(1.2)
	assert(app.manual_save().contains("已保存"))
	app.return_to_title()
	assert(app.stage == "title")
	app.continue_game()
	cold = app.world
	assert(cold.door_open and cold.second_lit and cold.companions_waiting)
	assert(cold.cold == 42 and cold.player.position == Vector2(2180,800))
	assert(cold.searched.has(0))
	cold.nearest = "search_10"
	cold.interact_nearest()
	assert(app.acquired and app.stage == "cold")
	settle_dialogue()
	app.on_interaction("cold_exit")
	assert(app.stage == "reunion")
	settle_dialogue()
	assert(app.stage == "meeting")
	settle_dialogue()
	assert(app.archive.mode == "prepare")
	app.archive.on_next()
	assert(app.archive.mode == "battle")
	app.battle.submit("letter","我好喜欢你。")
	app.battle.submit("letter","我好喜欢你。")
	assert(app.battle.errors[0] == 2)
	assert(app.battle.painter_hint().contains("第一段"))
	var sentence = "警方尚未公布三人的具体死因，也未就起火原因作出结论。"
	app.battle.submit("fire",sentence)
	assert(app.battle.advance())
	app.battle.submit("lawyer","曾代理建筑公司处理工地死亡事故。")
	app.battle.submit("notes","他是我父亲请的律师。")
	assert(app.battle.advance())
	app.battle.submit("lawyer","给X顾问公司的咨询费，按我发的账户走，不要写案号。")
	app.battle.submit("lawyer","该法官在另案讯问中承认收受这笔钱，并应请托在工地赔偿案中偏向建筑公司。")
	assert(app.battle.won())
	app.toggle_pause()
	assert(app.manual_save().contains("已保存"))
	app.return_to_title()
	app.continue_game()
	assert(app.battle.won() and app.battle.errors[0] == 2)
	assert(app.archive != null and app.meeting_done)
	for id in ["heroine","linshao","shenzhi","wanwan","aye","xiaolu","laozhou","daixingzhe"]:
		var visual = load("res://scripts/character_visual.gd").new()
		visual.character_id = id
		root.add_child(visual)
		for i in range(4): assert(visual.sprite_frames.get_frame_count("walk_%d" % i)==8)
		visual.queue_free()
	print("PASS: team confirmations, cold x1.4, discovery/two-person/three-person door flow, furnace objectives, companions, exit reunion, manual restores cold and battle, progressive hints, all eight-frame animations")
	for suffix in ["",".bak",".manual",".manual.bak"]:
		DirAccess.remove_absolute(app.checkpoint_path+suffix)
	quit()
