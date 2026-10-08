extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.enter_hallway()
	app.finish_dialogue()
	for i in range(5): await process_frame
	assert(app.world.character_nodes.size()==6)
	var visuals: Array = [app.world.player.sprite]
	for node in app.world.character_nodes.values(): visuals.append(node.get_child(0))
	for visual in visuals:
		if visual.character_id in ["shenzhi","linshao"]:
			for side in [1,2]:
				var animation := "walk_%d" % side
				var contact_time := {0:0.0,2:0.0}
				var passing_count := 0
				for index in range(8):
					var texture = visual.sprite_frames.get_frame_texture(animation,index)
					var column := int(texture.region.position.x/64)
					assert(column != 1,"Side walk must not turn frontward")
					if contact_time.has(column): contact_time[column] += visual.sprite_frames.get_frame_duration(animation,index)
					if column == 3: passing_count += 1
				assert(contact_time[0] == contact_time[2] and contact_time[0] > 0,"Uneven foot timing")
				assert(passing_count == 4,"Both steps need a passing phase")
		for direction in range(4):
			assert(visual.sprite_frames.has_animation("walk_%d" % direction))
			assert(visual.sprite_frames.get_frame_count("walk_%d" % direction)==8)
			assert(visual.sprite_frames.has_animation("idle_%d" % direction))
		visual.set_motion(Vector2.RIGHT,true)
		assert(visual.animation=="walk_2")
		visual.set_motion(Vector2.ZERO,false)
		assert(visual.animation=="idle_2")
		assert(is_equal_approx(visual.position.y+62*visual.scale.y,0))
	var old: float = visuals[0].scale.y
	for i in range(35): await process_frame
	assert(not is_equal_approx(old,visuals[0].scale.y))
	for visual in visuals:
		assert(is_equal_approx(visual.position.y+62*visual.scale.y,0))
		assert(visual.is_playing())
	for id in ["heroine","linshao","shenzhi","wanwan","aye","xiaolu","laozhou","daixingzhe"]:
		var im := Image.load_from_file("res://assets/characters/%s.png" % id)
		assert(im.get_size()==Vector2i(384,256))
		for row in range(4):
			for col in range(6):
				var bounds := im.get_region(Rect2i(col*64,row*64,64,64)).get_used_rect()
				assert(bounds.end.y==62 and bounds.position.y>=6)
	app.enter_meeting()
	app.close_archive()
	app.finish_dialogue()
	for tick in range(10): await process_frame
	assert(app.world.character_nodes.has("代行者"))
	assert(app.world.character_nodes["代行者"].get_child(0).animation=="idle_2")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/meeting_daixingzhe.png")
	print("CHARACTER_ANIMATION PASS: 192 frames, four directional walk/idle sets, NPCs installed, feet pinned while breathing")
	quit()
