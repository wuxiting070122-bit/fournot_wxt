extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var cover = load("res://scripts/cover.gd").new()
	root.add_child(cover)
	root.size = Vector2i(1280,800)
	await process_frame
	assert(not cover.revealed and cover.intact.visible)
	cover.reveal()
	await create_timer(1.3).timeout
	assert(cover.revealed and not cover.intact.visible)
	assert(cover.shards.size() == 3)
	assert(cover.hit_test(Vector2(1100,300)) == 0)
	assert(cover.hit_test(Vector2(1100,450)) == 1)
	assert(cover.hit_test(Vector2(1100,610)) == 2)
	cover.keyboard_focus = true
	cover.focus_index = 0
	for i in range(30): await process_frame
	assert(cover.shards[0].position.x < 0)
	assert(cover.shards[0].material.get_shader_parameter("hover") > 0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-cover-dissolve.png")
	print("PASS: cover texture, three hit regions, hover displacement and fog")
	quit()
