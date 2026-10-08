extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for room in ["bedroom","hallway","cold","meeting"]:
		var world = load("res://scripts/world.gd").new()
		world.room = room
		root.add_child(world)
		world.active = false
		await physics_frame
		await physics_frame
		assert(world.y_sort_enabled)
		var player = world.player
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			player.position = Vector2(400,570) if room == "cold" else Vector2(400,520)
			player.move_and_collide(direction*2000)
			var art: bool = room in ["bedroom","hallway"]
			assert(player.position.x >= (82 if art else 76)-0.1)
			assert(player.position.x <= (782 if art else 790)+0.1)
			assert(player.position.y >= (236 if art else 158)-0.1)
			assert(player.position.y <= (560 if art else 591)+0.1)
		world.queue_free()
		await process_frame
	print("BOUNDARY_REVIEW PASS: four maps, four boundary sweeps each, ground-position sorting enabled")
	quit()
