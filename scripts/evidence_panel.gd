extends Control

signal settings_requested
signal closed
signal continue_requested
signal round_finished(index: int)

const Sentences = preload("res://scripts/sentence_selection.gd")
const UI = preload("res://scripts/ui.gd")
var clues: Array = []
var notes := ""
var quotes: Array = []
var mode := "prepare"
var battle: RefCounted
var reader: TextEdit
var source_id := "fire"
var title_label: Label
var feedback: Label
var thought_label: Label
var next_button: Button
var quote_area: VBoxContainer
var phase_label: Label
var claim_label: Label
var resistance_label: Label
var resistance_bar: ProgressBar
var slots_label: Label
var selected_label: Label
var finalized := false
var hint_popup: Control
var source_buttons: Dictionary = {}
static var auto_sentence := true
var selection_anchor := -1
var font_size_label: Label
static var reading_size := 20

func set_reading_size(value: float) -> void:
	reading_size = int(value)
	reader.add_theme_font_size_override("font_size", reading_size)
	font_size_label.text = "字号 %d" % reading_size
	refresh_quotes()

func reader_input(event: InputEvent) -> void:
	if not auto_sentence: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var point := reader.get_line_column_at_pos(event.position)
			if point.x < 0 or point.y < 0: return
			selection_anchor = Sentences.offset(reader.text, point.y, point.x)
		else:
			select_sentence_at.call_deferred(selection_anchor)

func select_sentence_at(at: int) -> void:
	if not auto_sentence or at < 0: return
	for sentence in Sentences.spans(reader.text):
		if at >= sentence.start and at < sentence.end:
			var first := Sentences.coordinates(reader.text, sentence.start)
			var last := Sentences.coordinates(reader.text, sentence.end)
			reader.select(first.x, first.y, last.x, last.y)
			update_selected()
			return
	reader.deselect()
	update_selected()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.panel(self,Rect2(0,0,1280,800),Color("080e14"))
	UI.button(self,"设置",Rect2(28,15,76,35),func(): settings_requested.emit())
	UI.label(self,"⌖ 会客厅 / 会谈档案",Rect2(120,15,700,40),26,UI.GOLD)
	thought_label = UI.label(self,"",Rect2(28,56,1220,23),16,UI.TEAL)
	var skip := UI.button(self,"评测：跳过本关 F8",Rect2(1030,15,220,35),skip_round)
	skip.name = "EvaluationSkip"
	var skip_key := InputEventKey.new()
	skip_key.keycode = KEY_F8
	skip.shortcut = Shortcut.new()
	skip.shortcut.events = [skip_key]
	UI.panel(self,Rect2(20,108,236,623))
	UI.label(self,"六份线索",Rect2(38,123,195,30),20,UI.GOLD)
	var short_titles := {"book":"01  《灰烬》", "fire":"02  火灾报纸", "letter":"03  情书", "lawyer":"04  讯问笔录 / 附页", "social":"05  热搜页面", "soul":"06  《衡魂录》"}
	for i in range(clues.size()):
		var clue: Dictionary = clues[i]
		var btn := UI.button(self,short_titles.get(clue.id,clue.title),Rect2(32,167+i*58,212,48),func(): show_source(clue.id))
		btn.name = "Clue_" + clue.id
		source_buttons[clue.id] = btn
	if not notes.is_empty():
		UI.label(self,"会谈补充 · 不占线索位",Rect2(38,537,210,30),16,UI.MUTED)
		var btn := UI.button(self,"会议记录",Rect2(32,578,212,48),func(): show_source("notes"))
		btn.name = "Clue_notes"
		source_buttons["notes"] = btn
	UI.label(self,"原文可滚动阅读。\n保留否定词与完整句意。\n每次一句，最多 180 字。",Rect2(38,646,199,75),15,UI.MUTED)
	UI.panel(self,Rect2(270,108,565,623),Color("080808"))
	title_label = UI.label(self,"",Rect2(289,123,525,61),20,UI.GOLD)
	reader = TextEdit.new()
	reader.name = "ClueReader"
	reader.position = Vector2(287,235)
	reader.size = Vector2(531,404)
	reader.editable = false
	reader.selecting_enabled = true
	reader.deselect_on_focus_loss_enabled = false
	reader.context_menu_enabled = false
	reader.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	reader.add_theme_font_size_override("font_size",reading_size)
	reader.add_theme_color_override("font_color",UI.INK)
	reader.add_theme_color_override("font_readonly_color",UI.INK)
	reader.add_theme_color_override("selection_color",Color("466579"))
	reader.add_theme_constant_override("line_spacing",7)
	reader.add_theme_stylebox_override("normal",UI.box(Color("080808"),Color("080808"),0))
	reader.add_theme_stylebox_override("read_only",UI.box(Color("080808"),Color("080808"),0))
	reader.caret_changed.connect(update_selected)
	add_child(reader)
	reader.gui_input.connect(reader_input)
	font_size_label = UI.label(self,"字号 %d" % reading_size,Rect2(289,192,75,30),16,UI.MUTED)
	var font_slider := HSlider.new()
	font_slider.name = "ReadingFontSize"
	font_slider.position = Vector2(366,195)
	font_slider.size = Vector2(145,25)
	font_slider.min_value = 16
	font_slider.max_value = 30
	font_slider.step = 1
	font_slider.value = reading_size
	font_slider.value_changed.connect(set_reading_size)
	add_child(font_slider)
	var auto_toggle := CheckButton.new()
	auto_toggle.name = "AutoSentence"
	auto_toggle.text = "自动选择整句"
	auto_toggle.position = Vector2(555,189)
	auto_toggle.size = Vector2(260,36)
	auto_toggle.button_pressed = auto_sentence
	auto_toggle.add_theme_font_size_override("font_size",18)
	auto_toggle.toggled.connect(func(enabled: bool): auto_sentence = enabled; selection_anchor = -1; reader.deselect(); update_selected())
	add_child(auto_toggle)
	selected_label = UI.label(self,"拖选句内文字，收录时自动补全整句",Rect2(291,648,510,25),15,UI.MUTED)
	var capture := UI.button(self,"＋ 勾画并收录",Rect2(288,677,529,40),capture_selection,true)
	capture.name = "Capture"
	capture.focus_mode = Control.FOCUS_NONE
	UI.panel(self,Rect2(849,108,411,623))
	phase_label = UI.label(self,"",Rect2(870,121,368,30),19,UI.GOLD)
	claim_label = UI.label(self,"",Rect2(870,157,368,95),19)
	resistance_label = UI.label(self,"",Rect2(870,256,366,28),17,UI.MUTED)
	resistance_bar = UI.bar(self,Rect2(870,291,365,11),UI.GOLD)
	slots_label = UI.label(self,"",Rect2(870,316,365,25),16,UI.MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(868,350)
	scroll.size = Vector2(374,257)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	quote_area = VBoxContainer.new()
	quote_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quote_area.add_theme_constant_override("separation",8)
	scroll.add_child(quote_area)
	feedback = UI.label(self,"",Rect2(870,617,363,98),16,UI.TEAL)
	next_button = UI.button(self,"",Rect2(850,747,410,40),on_next,true)
	next_button.name = "NextPhase"
	UI.button(self,"返回场景",Rect2(20,747,160,40),func(): closed.emit())
	UI.label(self,"引用最多保留 6 句；可随时删除并重新勾画。",Rect2(201,752,626,30),16,UI.MUTED)
	show_source(source_id)
	refresh()
	# Keep all original control sizes and content; rearrange only UI window depth.
	var windows = preload("res://scripts/terminal_window.gd")
	windows.wrap(self,Rect2(20,108,236,623),"档案目录",Vector2(0,0))
	windows.wrap(self,Rect2(270,108,565,623),"原文阅读",Vector2(-28,14))
	var evidence = windows.wrap(self,Rect2(849,108,411,623),"有效信息",Vector2(-58,0))
	evidence.raise_window()
	update_window_title()

func show_source(id: String) -> void:
	source_id = id
	reader.deselect()
	reader.scroll_vertical = 0
	if id == "notes":
		title_label.text = "会议记录 · 已公开的口述"
		reader.text = notes
	else:
		for clue in clues:
			if clue.id == id:
				title_label.text = clue.title
				reader.text = clue.body
	update_window_title()
	for key in source_buttons:
		source_buttons[key].add_theme_color_override("font_color",UI.GOLD if key==id else UI.INK)
	update_selected()

func update_window_title() -> void:
	var window := get_node_or_null("Terminal_原文阅读")
	if window != null:
		window.caption = title_label.text
		window.queue_redraw()

func update_selected() -> void:
	if selected_label != null:
		selected_label.text = "已选 %d 字 / 最多 180 字" % reader.get_selected_text().length() if reader.has_selection() else ("点击句中的字即可选中整句，再点勾画收录" if auto_sentence else "拖选句内文字，收录时自动补全整句")

func capture_selection() -> void:
	if not reader.has_selection():
		feedback.text = "先在原文中拖选一句话内的文字。"
		return
	var start := Sentences.offset(reader.text, reader.get_selection_from_line(), reader.get_selection_from_column())
	var end := Sentences.offset(reader.text, reader.get_selection_to_line(), reader.get_selection_to_column())
	var sentence := Sentences.resolve(reader.text, start, end)
	if sentence.has("error"):
		feedback.text = sentence.error
		return
	var text: String = sentence.text
	var from := Sentences.coordinates(reader.text, sentence.start)
	var to := Sentences.coordinates(reader.text, sentence.end)
	reader.select(from.x, from.y, to.x, to.y)
	if quotes.size() >= 6:
		feedback.text = "引用位已满。删除一段后可以继续勾画；已提交的效果会保留。"
		return
	for quote in quotes:
		if quote.source == source_id and quote.text == text:
			feedback.text = "这段已经收录。"
			return
	quotes.append({"source":source_id,"text":text,"from_line":reader.get_selection_from_line(),"from_column":reader.get_selection_from_column(),"to_line":reader.get_selection_to_line(),"to_column":reader.get_selection_to_column()})
	feedback.text = "已补全并收录一句话。%s" % ("点击引用卡上的“提交”回应当前质疑。" if mode=="battle" else "可以继续整理，也可以开始会谈。")
	refresh_quotes()

func refresh_quotes() -> void:
	for child in quote_area.get_children():
		quote_area.remove_child(child)
		child.queue_free()
	slots_label.text = "我的引用  %d / 6" % quotes.size()
	for i in range(quotes.size()):
		var quote: Dictionary = quotes[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(353,110)
		card.add_theme_stylebox_override("panel",UI.box(Color("202b34")))
		quote_area.add_child(card)
		var column := VBoxContainer.new()
		card.add_child(column)
		var text := Label.new()
		text.text = quote.text
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 310
		text.add_theme_font_size_override("font_size",maxi(16,reading_size-4))
		column.add_child(text)
		var actions := HBoxContainer.new()
		column.add_child(actions)
		var index := i
		if mode == "battle":
			var send := Button.new()
			send.text = "提交"
			send.name = "QuoteSubmit_%d" % i
			send.custom_minimum_size = Vector2(130,32)
			send.focus_mode = Control.FOCUS_NONE
			send.pressed.connect(func(): submit_quote(index))
			actions.add_child(send)
		var remove := Button.new()
		remove.text = "删除引用"
		remove.focus_mode = Control.FOCUS_NONE
		remove.pressed.connect(func(): quotes.remove_at(index); refresh_quotes())
		actions.add_child(remove)

func submit_quote(index: int) -> void:
	if finalized or index < 0 or index >= quotes.size(): return
	var quote: Dictionary = quotes[index]
	var result: Dictionary = battle.submit(quote.source,quote.text)
	feedback.text = result.message
	refresh()
	if int(battle.errors[battle.round_index]) >= 3: show_exact_hint()

func refresh() -> void:
	refresh_quotes()
	thought_label.text = battle.painter_hint()
	if mode == "battle" and int(battle.errors[battle.round_index]) >= 3:
		thought_label.text = "画家（心想）：请在%s勾画并提交：%s" % exact_hint()
	thought_label.tooltip_text = thought_label.text
	thought_label.clip_text = true
	thought_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if mode == "prepare":
		phase_label.text = "整理证据"
		claim_label.text = "勾画你认为有用的信息。\n会谈揭开的身份细节，稍后会记入会议记录。" if notes.is_empty() else "勾画有用的线索与会议记录。\n选中句子后点「勾画并收录」，准备好后进入说服。"
		resistance_label.text = "线索 6 / 6 · 记录可随时回看"
		resistance_bar.value = 0
		next_button.text = "开始会谈" if notes.is_empty() else "进入说服战斗"
		next_button.disabled = false
	else:
		phase_label.text = battle.TITLES[battle.round_index]
		claim_label.text = "老周：“%s”" % battle.CLAIMS[battle.round_index]
		resistance_label.text = "群体抵触  %d / 100 · 目标低于 40" % battle.resistance
		resistance_bar.value = battle.resistance
		next_button.text = "完成说服" if battle.round_index==2 else "回应下一条质疑"
		next_button.disabled = not (battle.won() if battle.round_index==2 else battle.gate_complete())

func on_next() -> void:
	if finalized: return
	if mode == "prepare":
		continue_requested.emit()
		return
	if not battle.gate_complete(): return
	if battle.round_index == 2 and not battle.won(): return
	finalized = true
	round_finished.emit(battle.round_index)

func exact_hint() -> Array:
	var groups: Array = [["A1"],["B1","B5"],["C3","C4"]][battle.round_index]
	for id in groups:
		if battle.accepted.has(id): continue
		if id == "B1" and battle.has_any(["B1","B2","B3"]): continue
		if id == "C4" and battle.has_any(["C4","C5"]): continue
		for item in battle.evidence:
			if item.id != id: continue
			var body: String = notes if item.source == "notes" else ""
			var title := "会议记录"
			for clue in clues:
				if clue.id == item.source:
					body = clue.body
					title = clue.title
			for sentence in Sentences.spans(body):
				if sentence.text.contains(item.quote): return [title,sentence.text]
	# When required relations are complete but resistance remains, supply unused evidence.
	for item in battle.evidence:
		if int(item.round) != battle.round_index or battle.accepted.has(item.id): continue
		for clue in clues:
			if clue.id != item.source: continue
			for sentence in Sentences.spans(clue.body):
				if sentence.text.contains(item.quote): return [clue.title,sentence.text]
	return ["当前页面","本轮证据已足够，点击下方按钮继续。"]

func skip_round() -> void:
	if finalized: return
	if mode == "prepare":
		continue_requested.emit()
		return
	battle.skip_round_for_evaluation()
	refresh()
	on_next()

func show_exact_hint() -> void:
	if is_instance_valid(hint_popup): return
	hint_popup = Control.new()
	hint_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hint_popup)
	var veil := UI.panel(hint_popup,Rect2(0,0,1280,800),Color(0.01,0.02,0.03,0.94))
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.panel(hint_popup,Rect2(210,175,860,420),Color("101b23"))
	UI.label(hint_popup,"画家（心想） · 具体提示",Rect2(238,194,800,35),24,UI.TEAL)
	var hint := exact_hint()
	UI.label(hint_popup,"在「%s」中勾画以下完整原句，再收录并提交：" % hint[0],Rect2(238,244,800,65),20)
	UI.label(hint_popup,str(hint[1]),Rect2(238,319,800,175),22,UI.INK)
	UI.button(hint_popup,"知道了，返回勾画",Rect2(680,525,355,44),func(): hint_popup.queue_free(); hint_popup=null,true)
