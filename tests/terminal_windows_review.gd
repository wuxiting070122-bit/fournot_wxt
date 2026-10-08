extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.enter_bedroom()
	await process_frame
	assert(app.world.position == Vector2(28,110))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-terminal-bedroom.png")
	app.group_id = 0
	app.enter_cold(false)
	await process_frame
	await process_frame
	assert(app.world.get_viewport().size == Vector2i(864,624))
	print("PROFILE ",app.screen.get_node("Terminal_人物").content.get_child(0).size)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-terminal-cold.png")
	app.show_search_message("柜子里只有冷藏的鲜肉。没有有用的信息。")
	app.update_top_notice(0.035)
	assert(app.log_count > 0 and app.log_count < app.log_target.length())
	app.update_top_notice(5.0)
	assert(app.log_count == app.log_target.length())
	app.restoring = true
	app.enter_meeting()
	app.close_archive()
	app.finish_meeting()
	await process_frame
	var archive = app.archive
	var reader_window = archive.get_node("Terminal_原文阅读")
	var quote_window = archive.get_node("Terminal_有效信息")
	assert(archive.reader.size == Vector2(531,404))
	assert(archive.get_child(archive.get_child_count()-1) == quote_window)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	archive.reader.gui_input.emit(event)
	assert(archive.get_child(archive.get_child_count()-1) == reader_window)
	assert(reader_window.active and not quote_window.active)
	quote_window._gui_input(event)
	assert(archive.get_child(archive.get_child_count()-1) == quote_window)
	var initial_font: int = archive.reader.get_theme_font_size("font_size")
	reader_window.start_manipulation(Vector2.ZERO)
	reader_window.apply_pointer(reader_window.start_pointer+Vector2(-10000,-10000))
	assert(reader_window.position == Vector2.ZERO)
	reader_window.manipulating = false
	for edge in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		reader_window.start_manipulation(edge)
		reader_window.apply_pointer(reader_window.start_pointer+edge*2000)
		assert(reader_window.size.x >= reader_window.minimum_size.x)
		assert(reader_window.size.y >= reader_window.minimum_size.y)
		assert(reader_window.position.x >= 0 and reader_window.position.y >= 0)
		assert(reader_window.position.x+reader_window.size.x <= 1280)
		assert(reader_window.position.y+reader_window.size.y <= 800)
		reader_window.manipulating = false
	reader_window.start_manipulation(Vector2.ONE)
	reader_window.apply_pointer(reader_window.start_pointer-Vector2(10000,10000))
	assert(reader_window.size.is_equal_approx(reader_window.minimum_size))
	assert(reader_window.content.scale == Vector2.ONE)
	assert(archive.reader.get_theme_font_size("font_size") == initial_font)
	assert(archive.reader.size.x < 531)
	reader_window.manipulating = false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/sifei-terminal-evidence.png")
	print("PASS: viewport unchanged, click to front, dragging bounds, corner resize bounds, minimum size and proportional content")
	quit()
