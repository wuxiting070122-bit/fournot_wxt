extends SceneTree
var app
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value: failures.append(label); push_error(label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func press(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap() -> void:
	press(KEY_E,true)
	await frames(2)
	press(KEY_E,false)
	await frames(2)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/"+name+".png")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(2)
	app.save_enabled=false
	app.enter_hallway()
	app.finish_dialogue()
	await frames(10)
	check(app.world.player.position==Vector2(158,246),"spawn at own doorway")
	check(app.world.nearest=="home_door","own door is interactable")
	var center: Vector2 = app.world.camera.get_screen_center_position()
	for person in app.world.character_nodes.values():
		check(person.global_position.x>app.world.player.global_position.x,"entry cast is on the right")
		check(person.global_position.x<center.x+432,"entry framing shows all companions")
	check(697-app.world.PERIOD+58<center.x-432,"previous-cycle companions outside entry view")
	await shot("hallway_home_door")
	await tap()
	check(app.stage=="bedroom","home door returns to bedroom")
	check(app.world.player.position.distance_to(Vector2(130,255))<1,"return appears at bedroom door")
	await tap()
	check(app.stage=="hallway" and not app.dialogue_active,"exit returns without replaying introductions")
	app.world.player.position=Vector2(412,246)
	await frames(4)
	await tap()
	check(app.stage=="hallway","other door cannot enter")
	check(app.search_toast.text.contains("没有进入权限"),"locked door gives non-modal top notice")
	app.world.player.position=Vector2(840,450)
	await frames(60)
	var camera_x: float = app.world.camera.get_screen_center_position().x
	press(KEY_D,true)
	var max_jump := 0.0
	for i in range(1250):
		await physics_frame
		var now: float = app.world.camera.get_screen_center_position().x
		max_jump=maxf(max_jump,absf(now-camera_x))
		camera_x=now
	press(KEY_D,false)
	check(app.world.player.position.x>3456,"walk right across two map seams")
	check(max_jump<20,"camera remains continuous across seams")
	var phase: float = floorf(app.world.player.position.x/app.world.PERIOD)*app.world.PERIOD
	app.world.player.position=Vector2(phase+158,246)
	await frames(30)
	check(app.world.nearest=="home_door","own door repeats after loop")
	await shot("hallway_loop_door")
	app.world.player.position=Vector2(20,450)
	await frames(40)
	press(KEY_A,true)
	await frames(630)
	press(KEY_A,false)
	check(app.world.player.position.x < -1728,"walk left across two seams")
	await shot("hallway_left_loop")
	app.world.player.position=Vector2(-1728+158,246)
	await frames(6)
	await tap()
	check(app.stage=="bedroom","looped home door enters same bedroom")
	app.enter_hallway()
	app.world.player.position=Vector2(470,390)
	await frames(5)
	check(app.world.nearest=="group_1","group interactions preserved")
	await tap()
	check(app.dialogue_active,"physical group selection opens dialogue")
	print("HALLWAY_LOOP_REVIEW ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
