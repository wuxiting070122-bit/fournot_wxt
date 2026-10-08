extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var portrait = load("res://scripts/breathing_portrait.gd").new()
	portrait.size = Vector2(112,132)
	root.add_child(portrait)
	await process_frame
	portrait.set_process(false)
	portrait.phase = 0
	portrait.update_pose()
	var rest: Vector2 = portrait.pieces[0].polygon[0]
	portrait.phase = PI
	portrait.update_pose()
	assert(is_equal_approx(rest.y-portrait.pieces[0].polygon[0].y,1.25))
	for i in range(2):
		assert(portrait.pieces[i].polygon[3] == portrait.pieces[i+1].polygon[0])
		assert(portrait.pieces[i].polygon[2] == portrait.pieces[i+1].polygon[1])
	portrait.phase = TAU
	portrait.update_pose()
	assert(portrait.pieces[0].polygon[0].is_equal_approx(rest))
	print("PASS: breathing amplitude, shared seams, seamless loop")
	quit()
