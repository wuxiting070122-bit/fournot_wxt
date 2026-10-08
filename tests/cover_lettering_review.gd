extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var cover = load("res://scripts/cover.gd").new()
	root.add_child(cover)
	cover.reveal()
	await create_timer(1.8).timeout
	assert(cover.menu.get_node("Choice_0") is TextureRect)
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_DOWN
	cover._unhandled_key_input(event)
	assert(cover.focus_index == 2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-cover-lettering.png")
	cover.activate(1)
	assert(not cover.animating)
	cover.activate(2)
	await create_timer(0.4).timeout
	assert(is_instance_valid(cover.about))
	print("PASS: image choices, keyboard navigation, disabled continue and about")
	quit()
