extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	var cover = load("res://scripts/cover.gd").new()
	root.add_child(cover)
	await process_frame
	assert(not cover.revealed and not cover.final_menu.visible)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/cover-combined-intact.png")
	cover.reveal()
	assert(cover.animating and not cover.final_menu.visible)
	await create_timer(2.0).timeout
	assert(not cover.animating and cover.final_menu.visible)
	assert(cover.final_menu.revealed)
	assert(cover.final_menu.hit_test(Vector2(1100,300)) == 0)
	assert(cover.final_menu.hit_test(Vector2(1100,450)) == 1)
	assert(cover.final_menu.hit_test(Vector2(1100,610)) == 2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/cover-combined-menu.png")
	print("PASS: intact original -> original break -> approved menu; all menu hit regions")
	quit()
