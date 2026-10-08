extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	var cover = load("res://scripts/cover.gd").new()
	root.add_child(cover)
	await process_frame
	assert(not cover.revealed and cover.intact.visible)
	assert(is_equal_approx(cover.art.scale.x,cover.art.scale.y))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/cover-original-intact.png")
	cover.reveal()
	assert(cover.break_glitch.visible)
	await create_timer(1.5).timeout
	assert(cover.revealed and not cover.intact.visible)
	assert(not cover.break_glitch.visible)
	for i in range(3):
		assert(cover.menu_letters[i].modulate.a > .99)
		var letters = cover.menu_letters[i]
		var source = letters.texture.get_image()
		var a: Vector2 = letters.uv[1]-letters.uv[0]
		var b: Vector2 = letters.polygon[1]-letters.polygon[0]
		for y in range(0,source.get_height(),4):
			for x in range(0,source.get_width(),4):
				var uv := Vector2(x,y)
				if source.get_pixel(x,y).a < 0.1 or not Geometry2D.is_point_in_polygon(uv,letters.uv): continue
				var mapped: Vector2 = (uv-letters.uv[0]).rotated(a.angle_to(b))*(b.length()/a.length())+letters.polygon[0]
				assert(Geometry2D.is_point_in_polygon(mapped,cover.polygons[i]),"Letter fog outside shard %d" % i)
		var point = Vector2(1250,[350,700,1010][i])*cover.art.scale+cover.art.position
		assert(cover.hit_test(point)==i)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/cover-original-restored.png")
	cover.keyboard_focus = true
	cover._process(0.4)
	assert(cover.shards[0].position.x < -5)
	print("PASS: original aspect ratio, intact start, reveal, menu regions and hover")
	quit()
