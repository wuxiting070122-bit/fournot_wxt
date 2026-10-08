extends SceneTree
var app
var world
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: failures.append(text); push_error(text)
func walk(source: Vector2) -> void:
	var to: Vector2 = source*world.MAP_SCALE
	var steps := 0
	while world.player.position.distance_to(to)>3 and steps<500:
		world.player.move_and_collide((to-world.player.position).limit_length(4))
		await physics_frame
		steps+=1
	check(steps<500,"reachable "+str(source))
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.save_enabled=false
	app.enter_meeting()
	app.close_archive()
	world=app.world
	for i in range(20): await physics_frame
	check(world.character_nodes.size()==7,"all six companions plus manager")
	check(is_equal_approx(72.0*world.MAP_SCALE,64.0),"floor tile scale matches bedroom")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/output/meeting_v1_integrated.png")
	await walk(Vector2(1100,735))
	await walk(Vector2(1100,330))
	await walk(Vector2(400,330))
	await walk(Vector2(400,735))
	await walk(Vector2(768,735))
	check(world.player.test_move(world.player.transform,Vector2(0,-300)),"table blocks passage")
	await walk(Vector2(768,970))
	await walk(Vector2(768,735))
	world.nearest="meeting_archive"
	world.interact_nearest()
	check(is_instance_valid(app.archive),"meeting archive interaction works")
	print("MEETING_MAP_REVIEW ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
