extends SceneTree
var app
var world
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func settle() -> void:
	for i in range(5): await physics_frame
func walk(to: Vector2) -> void:
	var ticks := 0
	while world.player.position.distance_to(to)>3 and ticks<900:
		var step: Vector2 = (to-world.player.position).limit_length(4)
		world.player.move_and_collide(step)
		await physics_frame
		ticks+=1
	check(ticks<900,"reachable %s from %s" % [to,world.player.position])
	if ticks>=900: quit(1)
	await settle()
func interact(id: String) -> void:
	world.nearest=id
	world.interact_nearest()
	if app.dialogue_active: app.finish_dialogue()
	await settle()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/"+name+".png")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id=0
	app.enter_cold(false)
	world=app.world
	await settle()
	check(world.hidden_room.visible,"deep room starts hidden")
	await interact("switch")
	await shot("cold_large_entry")
	await walk(Vector2(440,1440))
	await walk(Vector2(440,1152))
	await walk(Vector2(360,1152))
	await walk(Vector2(360,910))
	await walk(Vector2(620,910))
	await interact("ember_box")
	await walk(Vector2(885,910))
	check(world.player.test_move(world.player.transform,Vector2(0,-180)),"wall pipe blocks upward movement")
	await walk(Vector2(1840,910))
	await walk(Vector2(1840,1152))
	await walk(Vector2(620,1152))
	await interact("search_0")
	check(not app.dialogue_active and not app.acquired,"empty search does not open dialogue")
	await walk(Vector2(1870,1152))
	world.player.move_and_collide(Vector2(500,0))
	check(world.player.position.x<1950,"closed gate blocks movement")
	await interact("heavy_door")
	check(world.door_seen and not world.door_open,"first attempt needs companions")
	await walk(Vector2(440,1152))
	await walk(Vector2(440,1440))
	await interact("recruit")
	check(world.recruited,"companions recruited")
	await walk(Vector2(400,1460))
	await interact("take_ember")
	await walk(Vector2(440,1440))
	await walk(Vector2(440,1152))
	await walk(Vector2(1870,1152))
	await interact("heavy_door")
	for i in range(100): await physics_frame
	check(world.door_open and not world.hidden_room.visible,"cooperative push reveals room")
	check(world.camera.limit_right==3000,"camera unlocks deep room")
	check(app.dialogue_active,"post-door conversation starts")
	app.finish_dialogue()
	await settle()
	check("带着火种" in str(world.door_open_dialogue()),"carried ember dialogue")
	world.ember = false
	check("回入口" in str(world.door_open_dialogue()),"missing ember dialogue")
	world.ember = true
	await walk(Vector2(2130,1152))
	await walk(Vector2(2130,760))
	await walk(Vector2(2180,760))
	await interact("second_furnace")
	check(world.second_lit and world.is_warm(),"ember ignites second furnace")
	await shot("cold_large_second_furnace")
	await walk(Vector2(2240,760))
	check(world.player.test_move(world.player.transform,Vector2(0,-100)),"crate beside second furnace blocks feet")
	await walk(Vector2(2840,760))
	await walk(Vector2(2840,698))
	await interact("search_10")
	check(app.acquired and world.case_taken,"hidden cabinet awards case")
	await shot("cold_large_search")
	check(not world.failed,"route survives cold")
	await walk(Vector2(2840,980))
	await walk(Vector2(2840,1350))
	check(world.player.test_move(world.player.transform,Vector2(160,0)),"corner drums block feet")
	await walk(Vector2(2760,1350))
	await walk(Vector2(2720,1350))
	await walk(Vector2(2720,1470))
	await walk(Vector2(2280,1470))
	app.show_search_message("没有有用的信息。")
	app.update_top_notice(0)
	check(app.search_toast.text=="没有有用的信息。","search result takes priority in top notice")
	world.hint = "E · 调查柜子"
	app.update_top_notice(4.0)
	check(app.search_toast.text==world.hint,"top notice restores interaction hint")
	world.nearest="search_10"
	world.interact_nearest()
	check(not app.dialogue_active,"repeated successful cabinet only gives toast")
	world.player.position = Vector2(1180,1450)
	world.ember=true
	world.wind_time=0.0
	await settle()
	check(not world.ember,"active cold-air vent extinguishes ember")
	app.toggle_pause()
	var temperature: float = world.cold
	await settle()
	check(world.cold==temperature,"pause freezes temperature")
	app.toggle_pause()

	print("COLD_LARGE_REVIEW ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
