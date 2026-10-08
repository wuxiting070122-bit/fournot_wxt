extends Control
## Terminal recap: append typed paragraphs, retaining the previous output.
signal finished
signal name_confirmed(value: String)
var name_input: LineEdit

var lines: Array = []
var playback_paused := false
var line_index := 0
var character_count := 0
var phase := "typing"
var clock := 0.0
var blink := 0.0
var target := ""
var history := ""
var line_prefix := "> "
var body: Label
var speaker: Label
var transcript: Control
var scroll_initialized := false

func _ready() -> void:
	name = "IntroTerminal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	speaker = Label.new()
	speaker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speaker.anchor_left = 0.16
	speaker.anchor_right = 0.84
	speaker.anchor_top = 0.10
	speaker.anchor_bottom = 0.16
	speaker.add_theme_font_size_override("font_size", 19)
	speaker.add_theme_color_override("font_color", Color("8b9b98"))
	add_child(speaker)
	transcript = Control.new()
	transcript.name = "TranscriptWindow"
	transcript.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transcript.anchor_left = 0.16
	transcript.anchor_right = 0.84
	transcript.anchor_top = 0.20
	transcript.anchor_bottom = 0.86
	transcript.clip_contents = true
	transcript.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transcript)
	body = Label.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 26)
	body.add_theme_color_override("font_color", Color("e6eeeb"))
	body.add_theme_constant_override("line_spacing", 8)
	transcript.add_child(body)
	begin_line()
	call_deferred("update_scroll", 0.0)

func begin_line() -> void:
	if line_index >= lines.size():
		phase = "done"
		finished.emit()
		return
	target = str(lines[line_index].text)
	line_prefix = "// " if lines[line_index].get("style", "") == "comment" else "> "
	speaker.text = "// 系统注释" if line_prefix == "// " else "> " + str(lines[line_index].speaker)
	character_count = 0
	phase = "typing"
	clock = 0.12
	refresh_text()

func request_name() -> void:
	phase = "name_input"
	name_input = LineEdit.new()
	name_input.name = "PlayerNameInput"
	name_input.position = Vector2(size.x*0.16,size.y*0.5+36)
	name_input.size = Vector2(size.x*0.68,48)
	name_input.max_length = 12
	name_input.placeholder_text = "输入姓名，按 Enter 确认"
	name_input.add_theme_font_size_override("font_size",26)
	add_child(name_input)
	name_input.text_submitted.connect(submit_name)
	name_input.grab_focus()

func submit_name(value: String) -> void:
	if playback_paused: return
	var clean := value.strip_edges().left(12)
	if clean.is_empty():
		name_input.placeholder_text = "姓名不能为空，请输入后按 Enter"
		return
	name_confirmed.emit(clean)
	history += "> 你的名字叫："+clean+"\n\n"
	name_input.queue_free()
	line_index += 1
	begin_line()

func refresh_text() -> void:
	body.text = history + line_prefix + target.left(character_count) + ("▏" if fmod(blink, 0.9) < 0.55 else " ")

func update_scroll(delta: float) -> void:
	# Label minimum height includes soft wrapping and paragraph spacing.
	# Keep the latest rendered line centered in the viewport, not at the bottom.
	body.size.x = transcript.size.x
	var height := body.get_minimum_size().y
	body.size.y = height
	var line_height := float(body.get_line_height())
	var center_y := size.y * 0.5 - transcript.position.y
	var destination := center_y - height + line_height * 0.5
	if not scroll_initialized or delta <= 0.0:
		body.position.y = destination
		scroll_initialized = true
	else:
		body.position.y = lerpf(body.position.y, destination, 1.0-exp(-delta*16.0))

func _process(delta: float) -> void:
	if playback_paused or phase == "done": return
	blink += delta
	clock -= delta
	if clock <= 0.0:
		match phase:
			"typing":
				character_count += 1
				clock = 0.025
				if target.substr(character_count - 1, 1) in ["，", "。", "！", "？", "…", "："]:
					clock = 0.10
				if character_count >= target.length():
					if lines[line_index].get("style", "") == "name":
						request_name()
						return
					phase = "hold"
					clock = 1.5 if line_index == lines.size() - 1 else 0.55
			"hold":
				history += line_prefix + target + "\n\n"
				line_index += 1
				begin_line()
	if phase != "done":
		refresh_text()
		update_scroll(delta)
