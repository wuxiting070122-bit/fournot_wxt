extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.enter_meeting()
	app.finish_dialogue()
	app.open_archive()
	var panel = app.archive
	panel.reader.text = "第一句没有确定死因。第二句需要继续调查！第三句。"
	await process_frame
	var rect: Rect2i = panel.reader.get_rect_at_line_column(0, 13)
	var point: Vector2 = panel.reader.global_position + Vector2(rect.position) + Vector2(2, 5)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event)
		await process_frame
	await process_frame
	assert(panel.reader.get_selected_text() == "第二句需要继续调查！")
	var capture = panel.find_child("Capture",true,false)
	for pressed in [true,false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = capture.global_position+capture.size*0.5
		root.push_input(click)
		await process_frame
	assert(panel.quotes.back().text == "第二句需要继续调查！")
	panel.set_reading_size(30)
	assert(panel.reader.get_theme_font_size("font_size") == 30)
	panel.find_child("AutoSentence",true,false).button_pressed = false
	panel.reader.select(0,0,0,15)
	var count: int = panel.quotes.size()
	panel.capture_selection()
	assert(panel.quotes.size() == count)
	panel.find_child("AutoSentence",true,false).button_pressed = true
	panel.select_sentence_at(2)
	assert(panel.reader.get_selected_text() == "第一句没有确定死因。")
	panel.show_source("fire")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/selection_controls.png")
	print("SELECTION_CONTROLS PASS: mouse click, complete sentence capture, font size, manual crossing rejection")
	quit()
