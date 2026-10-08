extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var cover = load("res://scripts/cover.gd").new()
	root.add_child(cover)
	root.size = Vector2i(1280,800)
	await process_frame
	assert(not cover.revealed and not cover.menu.visible)
	assert(cover.glass.texture.resource_path == "res://assets/cover/glass.jpg")
	assert(cover.lamp.texture.resource_path == "res://assets/cover/light.jpg")
	cover.reveal()
	assert(cover.animating)
	await create_timer(1.8).timeout
	assert(cover.revealed and not cover.animating and cover.menu.visible)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-original-cover-restored.png")
	print("PASS: original layers and click-to-break sequence restored")
	quit()
