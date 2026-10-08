extends Control

const Checkpoint = preload("res://scripts/checkpoint.gd")
var checkpoint_path := Checkpoint.PATH
var checkpoint_stage := ""
var save_enabled := true

const UI = preload("res://scripts/ui.gd")
const Battle = preload("res://scripts/persuasion.gd")
const EvidenceView = preload("res://scripts/evidence_panel.gd")

var stage := "title"
var player_name := "未命名"
var hall_intro_seen := false
var group_id := -1
var pending_group := -1
var group_confirmation: Control
var screen: Control
var world: Node2D
var archive: Control
var overlay_layer: CanvasLayer
var portraits: Control
var dialog: Control
var pause_layer: Control
var dialogue_active := false
var paused := false
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_callback: Callable
var speaker_label: Label
var speech_label: Label
var page_label: Label
var hint_label: Label
var objective_label: Label
var cold_label: Label
var cold_bar: ProgressBar
var notes := ""
var clues: Array = []
var quotes: Array = []
var acquired := false
var meeting_done := false
var persuaded := false
var voted := false
var battle: RefCounted
var dialogues: Dictionary = {}
var elapsed := 0.0
var cold_failures := 0
var brightness := 1.0
var brightness_rect: ColorRect
var story_history: Array = []
var restoring := false

const GROUP_NAMES = ["林梢 ＋ 沈知", "小鹿 ＋ 老周", "阿野 ＋ 晚晚"]

func _ready() -> void:
	save_enabled = not ("--smoke-test" in OS.get_cmdline_user_args() or "--script" in OS.get_cmdline_args())
	var app_theme := Theme.new()
	var terminal_font := SystemFont.new()
	terminal_font.font_names = PackedStringArray(["Menlo", "Consolas", "monospace"])
	var chinese_font := load("res://assets/ui_font.tres").duplicate(true) as FontVariation
	(chinese_font.base_font as FontFile).antialiasing = TextServer.FONT_ANTIALIASING_NONE
	terminal_font.fallbacks = [chinese_font]
	terminal_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	app_theme.default_font = terminal_font
	app_theme.default_font_size = 19
	theme = app_theme
	# Screen overlays must not inherit a world camera's canvas transform.
	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "ScreenOverlays"
	overlay_layer.layer = 10
	add_child(overlay_layer)
	dialogues = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	clues = JSON.parse_string(FileAccess.get_file_as_string("res://data/clues.json"))
	battle = Battle.new()
	setup_brightness()
	show_title()
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("run_smoke_test")

func clear_screen() -> void:
	close_archive()
	if is_instance_valid(world):
		world.active = false
		world.player.active = false
	world = null
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	move_child(screen,0)
	hint_label = null
	objective_label = null
	cold_label = null
	cold_bar = null

func header(title: String, number: String) -> void:
	UI.terminal_panel(screen,Rect2(28,14,1224,70),"四非 / 极点终端                         SESSION 01 · 第一轮投票",true)
	UI.terminal_button(screen,"[ 设置 ]",Rect2(38,47,112,30),toggle_pause)
	var location: String = {"bedroom":"卧室","hallway":"走廊","cold":"冷冻室","meeting":"会客厅","vote":"会客厅"}.get(stage,"四非")
	UI.label(screen,"> LOC / "+location,Rect2(172,47,420,30),20,UI.INK)
	UI.label(screen,"[ "+number+" ]  "+title+"  _",Rect2(850,47,380,30),18,UI.TEAL)
	UI.terminal_button(screen,"[ 暂停 ]",Rect2(1150,744,102,40),toggle_pause)

func show_title() -> void:
	stage = "title"
	clear_screen()
	var cover := preload("res://scripts/cover.gd").new()
	cover.can_continue = not latest_save().is_empty()
	cover.start_requested.connect(start_new_game)
	cover.continue_requested.connect(continue_game)
	screen.add_child(cover)

func start_new_game() -> void:
	story_history.clear()
	checkpoint_stage = ""
	set_meta("battle_started",false)
	group_id = -1
	hall_intro_seen = false
	acquired = false
	meeting_done = false
	persuaded = false
	voted = false
	notes = ""
	quotes.clear()
	battle = Battle.new()
	elapsed = 0.0
	cold_failures = 0
	stage = "intro"
	clear_screen()
	var terminal := preload("res://scripts/intro_terminal.gd").new()
	player_name = "未命名"
	terminal.lines = dialogues.intro.duplicate(true)
	terminal.lines.insert(1,{"speaker":"我的回忆","text":"你的名字叫：","style":"name"})
	terminal.name_confirmed.connect(func(value: String):
		player_name = value
		story_history.append("你的名字叫："+value)
	)
	terminal.finished.connect(func():
		for line in dialogues.intro: story_history.append(line.text)
		enter_bedroom())
	screen.add_child(terminal)
	UI.button(screen,"设置",Rect2(28,19,76,40),toggle_pause)

func load_world(scene_name: String) -> void:
	world = load("res://scenes/%s.tscn" % scene_name).instantiate()
	if scene_name in ["cold_room","hallway","meeting"]:
		var container := SubViewportContainer.new()
		container.position = Vector2(28,110)
		container.size = Vector2(864,624)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var viewport := SubViewport.new()
		viewport.size = Vector2i(864,624)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		container.add_child(viewport)
		screen.add_child(container)
		viewport.add_child(world)
		if scene_name == "cold_room":
			world.message.connect(show_search_message)
			world.story.connect(func(lines: Array, completion: Callable): play_dialogue(lines,completion))
			world.objective.connect(set_objective)
	else:
		world.position = Vector2(28,110)
		screen.add_child(world)
	world.interaction.connect(on_interaction)
	UI.panel(screen,Rect2(916,110,336,624),Color("172623"))
	objective_label = UI.label(screen,"",Rect2(940,179,286,121),24)
	hint_label = UI.label(screen,"靠近目标后按 E",Rect2(940,659,288,55),18,UI.GOLD)
	call_deferred("style_exploration_windows",screen)

func style_exploration_windows(owner_screen: Control) -> void:
	if not is_instance_valid(owner_screen) or owner_screen != screen: return
	# World viewport and artwork retain their exact dimensions and transforms.
	for child in screen.get_children():
		if child is Panel and child.position == Vector2(916,110):
			screen.remove_child(child)
			child.queue_free()
	var windows = preload("res://scripts/terminal_window.gd")
	var task = windows.wrap(screen,Rect2(930,132,310,172),"任务")
	task.position = Vector2(804,100) if stage == "cold" else Vector2(868,100)
	var foreground: Panel
	# The profile overlaps the task's right edge, while task copy stays in its exposed area.
	objective_label.position = Vector2(12,8)
	objective_label.size = Vector2(218,164)
	objective_label.add_theme_font_size_override("font_size",18)
	objective_label.add_theme_constant_override("line_spacing",3)
	var task_scroll := ScrollContainer.new()
	task_scroll.position = Vector2(8,4)
	task_scroll.size = Vector2(222,164)
	task_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	task.content.add_child(task_scroll)
	objective_label.reparent(task_scroll,false)
	objective_label.custom_minimum_size = Vector2(208,0)
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task.content.clip_contents = true
	var profile = windows.wrap(screen,Rect2(-3000,-3000,218,220),"人物")
	profile.position = Vector2(1038,141) if stage == "cold" else Vector2(1028,180)
	var portrait := preload("res://scripts/breathing_portrait.gd").new()
	portrait.name = "BreathingIDPortrait"
	portrait.position = Vector2(49,8)
	portrait.size = Vector2(112,132)
	profile.content.add_child(portrait)
	profile.content.clip_contents = true
	UI.label(profile.content,"姓名："+player_name+"\n身份：画家",Rect2(12,149,195,64),18)
	if stage == "cold":
		var companions = windows.wrap(screen,Rect2(930,305,310,60),"同行者",Vector2(-154,30))
		companions.position = Vector2(834,336)
		companions.content.clip_contents = true
		for child in companions.content.get_children():
			if child is Label:
				child.position = Vector2(10,6)
				child.size = Vector2(188,48)
				child.add_theme_font_size_override("font_size",16)
		var status = windows.wrap(screen,Rect2(930,380,310,255),"状态",Vector2(4,32))
		status.position = Vector2(952,466)
		foreground = status
		cold_label.add_theme_font_size_override("font_size",25)
		cold_bar.size.y = 24
		cold_bar.add_theme_stylebox_override("fill",StyleBoxEmpty.new())
		cold_bar.draw.connect(func():
			var width: float = (cold_bar.size.x-8)/16.0
			for i in range(16):
				var cell := Rect2(4+i*width,4,width-3,cold_bar.size.y-8)
				cold_bar.draw_rect(cell,UI.TEAL if float(i)/16.0 < cold_bar.value/100.0 else Color("395b59"),float(i)/16.0 < cold_bar.value/100.0,1)
		)
		cold_bar.value_changed.connect(func(_value: float): cold_bar.queue_redraw())
		status.bind_controls(status.content)
	else:
		var actions = windows.wrap(screen,Rect2(930,315,310,342),"行动记录",Vector2(0,83))
		actions.position = Vector2(894,350)
		foreground = actions
	# A wide log overlaps the map bottom and the status window, as in the approved sketch.
	hint_label.reparent(screen,false)
	hint_label.hide()
	var log_window = windows.wrap(screen,Rect2(-3000,-3000,930,102),"对话记录")
	log_window.position = Vector2(48,672) if stage == "cold" else Vector2(48,602)
	search_toast = UI.label(log_window.content,"",Rect2(18,12,892,76),22,UI.INK)
	search_toast.name = "ExplorationLog"
	log_window.bind_controls(log_window.content)
	profile.bind_controls(profile.content)
	log_window.raise_window()
	if is_instance_valid(foreground): foreground.raise_window()
	profile.raise_window()
	if stage == "cold" and is_instance_valid(foreground): foreground.raise_window()
	notice_text = ""
	notice_time = 0.0
	exploration_log.clear()
	log_target = ""
	log_count = 0
	log_clock = 0.0

func set_objective(text: String) -> void:
	var entries := PackedStringArray()
	for line in text.split("\n",false):
		entries.append(line if line.begins_with("□ ") else "□ "+line)
	objective_label.text = "\n".join(entries)

func enter_bedroom(returning := false) -> void:
	stage = "bedroom"
	clear_screen()
	header("醒来", "01")
	load_world("bedroom")
	if returning: world.player.position = Vector2(130,255)
	set_objective("走到左上方的房门，\n与门外的人会合。")
	UI.label(screen,"你推门回到自己的房间。\n同伴还在走廊等你。" if returning else "门外传来两声敲门。\n你戴上助听器，起身。",Rect2(940,335,282,93),20,UI.MUTED)
	UI.label(screen,"已有线索 5 / 6",Rect2(940,540,284,31),18,UI.MUTED)

func enter_hallway() -> void:
	stage = "hallway"
	clear_screen()
	header("选择同行者", "02")
	load_world("hallway")
	set_objective("三组人都在等你。\n选择同行的两人。")
	for i in range(3):
		var index := i
		var btn := UI.button(screen,GROUP_NAMES[i],Rect2(940,322+i*72,286,56),func(): choose_group(index))
		btn.name = "Group_%d" % i
	UI.label(screen,"也可走到他们身边按 E。",Rect2(940,560,280,60),17,UI.MUTED)
	if not hall_intro_seen:
		hall_intro_seen = true
		play_dialogue(dialogues.hall,func(): pass)

func choose_group(index: int) -> void:
	if stage != "hallway" or dialogue_active or paused or pending_group >= 0: return
	play_dialogue(dialogues["group_%d" % index],func(): confirm_group(index))

func confirm_group(index: int) -> void:
	pending_group = index
	world.active = false
	world.player.active = false
	group_confirmation = Control.new()
	group_confirmation.theme = theme
	group_confirmation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(group_confirmation)
	UI.panel(group_confirmation,Rect2(0,0,1280,800),Color(0.02,0.04,0.04,0.8))
	UI.panel(group_confirmation,Rect2(330,270,620,250))
	UI.label(group_confirmation,"选择「%s」成为同行者？" % GROUP_NAMES[index],Rect2(365,300,550,70),25)
	UI.button(group_confirmation,"再和其他人聊聊",Rect2(365,415,245,58),cancel_group)
	UI.button(group_confirmation,"确认，进入冷冻室",Rect2(665,415,245,58),accept_group,true)

func cancel_group() -> void:
	if is_instance_valid(group_confirmation):
		group_confirmation.queue_free()
	group_confirmation = null
	pending_group = -1
	if is_instance_valid(world): world.active = true

func accept_group() -> void:
	if pending_group < 0: return
	group_id = pending_group
	cancel_group()
	enter_cold(true)

func enter_cold(with_intro := true) -> void:
	stage = "cold"
	clear_screen()
	header("最后的房间", "03")
	load_world("cold_room")
	world.companions = Array(GROUP_NAMES[group_id].split(" ＋ "))
	acquired = false
	world.cold_changed.connect(update_cold)
	world.frozen.connect(on_frozen)
	set_objective("找到入口火炉旁的灯开关\n和同伴搜索冷藏柜")
	UI.label(screen,"同行者 / "+GROUP_NAMES[group_id],Rect2(940,307,281,50),18,UI.MUTED)
	cold_label = UI.label(screen,"寒冷 0 / 100 · 炉边回暖",Rect2(940,383,285,62),19,UI.TEAL)
	cold_bar = UI.bar(screen,Rect2(940,454,286,17),Color("8db2b9"))
	UI.label(screen,"离开火炉会积寒。\n踩上冰面，寒冷上升更快。\n满值后从门口重试。",Rect2(940,505,280,119),18,UI.MUTED)
	if with_intro:
		play_dialogue(dialogues["cold_%d" % group_id],func(): pass)

func update_cold(value: float, warm: bool, icy: bool) -> void:
	if cold_bar == null: return
	cold_bar.value = value
	var situation := "炉边回暖" if warm else ("冰面 · 加速积寒" if icy else "离炉 · 持续积寒")
	cold_label.text = "寒冷 %d / 100\n%s" % [int(value),situation]
	cold_label.add_theme_color_override("font_color",Color("e3957c") if value>=70 else UI.TEAL)

func on_frozen() -> void:
	cold_failures += 1
	acquired = false
	play_dialogue([{"speaker":"这次没能回到火炉","text":"寒意让你失去了知觉。可以从入室前重新尝试：找灯后规划路线，带着案卷及时返回炉边。"}],func(): enter_cold(false))

func on_interaction(action: String) -> void:
	if dialogue_active or paused or pending_group >= 0 or is_instance_valid(archive): return
	match action:
		"bedroom_exit": enter_hallway()
		"meeting_archive": open_archive()
		"home_door": enter_bedroom(true)
		"locked_door": show_search_message("这不是你的房间，没有进入权限。")
		"group_0": choose_group(0)
		"group_1": choose_group(1)
		"group_2": choose_group(2)
		"switch":
			world.lights_on = true
			set_objective("和同伴一起搜索冷藏柜。\n记住入口火炉的位置。")
			play_dialogue([{"speaker":"你（心想）","text":"手指已经僵了。地上还有冰，回来的时间也得算上。"}],func(): pass)
		"case":
			world.case_taken = true
			acquired = true
			set_objective("案卷已收录 6 / 6。\n回到左下方火炉，\n从门口离开。")
			play_dialogue([{"speaker":"取得线索 · 律师遇害案","text":"一份讯问笔录，夹着关联核查页。这份材料，得带出去给他们看。"}],func(): pass)
		"cold_exit":
			if acquired:
				enter_reunion()
			else:
				play_dialogue([{"speaker":"你（心想）","text":"这是最后一次调查机会。先在炉边暖一会，再去看看深处。"}],func(): pass)

func enter_reunion() -> void:
	stage = "reunion"
	clear_screen()
	header("门外汇合", "04")
	load_world("hallway")
	set_objective("把案卷递给林梢。\n她这次看了很久。")
	play_dialogue(dialogues.reunion,func():
		notes = "林梢的口述\n施工时间是她父亲催着改的。工人死后，家属反被判赔偿公司；工人的妻子随后自杀。林梢说，她当时什么也没做。"
		enter_meeting()
	)

func enter_meeting() -> void:
	stage = "meeting"
	clear_screen()
	header("证据与会谈", "05")
	load_world("meeting")
	set_objective("整理六份线索，\n听清每个人的判断。")
	UI.label(screen,"你保留什么，\n就将用什么说服别人。",Rect2(940,335,283,89),21,UI.MUTED)
	var open_btn := UI.button(screen,"打开档案 / 继续会谈",Rect2(940,520,286,61),open_archive,true)
	open_btn.name = "OpenArchive"
	UI.label(screen,"原文、引用和会议记录\n都可在档案里回看。",Rect2(940,597,285,60),17,UI.MUTED)
	# Collect testimony first, then offer one complete preparation screen.
	if restoring: return
	if meeting_done:
		open_archive()
	else:
		play_dialogue(dialogues.meeting,finish_meeting)

func open_archive() -> void:
	if dialogue_active or paused or is_instance_valid(archive) or stage != "meeting": return
	archive = EvidenceView.new()
	archive.theme = theme
	archive.z_index = 100
	archive.clues = clues.duplicate(true)
	if not notes.is_empty():
		for clue in archive.clues:
			if clue.id == "lawyer":
				clue.body += "\n\n【门外补充】\n" + notes.split("\n\n阿野的供述")[0]
	archive.quotes = quotes
	# Before the confrontation only Linshao's outside remarks are available.
	archive.notes = notes if meeting_done else ""
	archive.mode = "battle" if meeting_done and battle.round_index>0 else "prepare"
	if meeting_done and get_meta("battle_started",false): archive.mode = "battle"
	archive.battle = battle
	archive.settings_requested.connect(toggle_pause)
	archive.closed.connect(close_archive)
	archive.continue_requested.connect(on_archive_continue)
	archive.round_finished.connect(on_round_finished)
	overlay_layer.add_child(archive)
	world.active = false
	world.player.active = false

func close_archive() -> void:
	if is_instance_valid(archive):
		archive.get_parent().remove_child(archive)
		archive.queue_free()
	archive = null
	if is_instance_valid(world): world.active = not dialogue_active and not paused

func on_archive_continue() -> void:
	close_archive()
	if not meeting_done:
		play_dialogue(dialogues.meeting,finish_meeting)
	else:
		set_meta("battle_started",true)
		open_archive()

func finish_meeting() -> void:
	meeting_done = true
	notes += "\n\n阿野的供述\n“我爸那天又想打我妈。我跟他抢刀，刀进了他肚子。我没放火！”\n阿野说母亲随后打伤了他，并在屋内点火。他没有提供父亲确切的死亡时间。\n\n老周的否认\n“我没替你父亲做过这些事。你和她串通好了，是不是？”\n\n林梢的指认\n“他是我父亲请的律师。我拿到材料时就认出来了。”"
	set_objective("老周的身份已被揭开。\n用证据说服众人投票。")
	open_archive()

func on_round_finished(index: int) -> void:
	close_archive()
	var after := func():
		if index < 2:
			battle.advance()
			open_archive()
		else:
			persuaded = battle.won()
			play_dialogue(dialogues.persuaded,enter_vote)
	play_dialogue(dialogues["round_%d" % index],after)

func enter_vote() -> void:
	if not persuaded: return
	stage = "vote"
	clear_screen()
	header("第一轮投票", "06")
	var voting := preload("res://scripts/vote_terminal.gd").new()
	voting.confirmed.connect(confirm_vote)
	screen.add_child(voting)

func confirm_vote() -> void:
	if not persuaded or voted or stage != "vote": return
	voted = true
	play_dialogue(dialogues.ending,show_ending)

func show_ending() -> void:
	stage = "ending"
	clear_screen()
	UI.panel(screen,Rect2(0,0,1280,800),Color("090f10"))
	UI.label(screen,"第一轮 · 结束",Rect2(117,137,1030,67),43,UI.GOLD)
	UI.label(screen,"老周的座位空了。\n代行者没有说，谁被判为了罪人。",Rect2(119,259,1010,105),29,UI.MUTED)
	UI.label(screen,"我投出的那一票，\n究竟把谁变成了罪人？",Rect2(118,409,1055,130),44,UI.INK)
	UI.button(screen,"重新开始",Rect2(119,624,275,61),func(): set_meta("battle_started",false); show_title(),true)
	UI.label(screen,"第一轮投票 Demo · 完",Rect2(426,639,700,38),20,UI.MUTED)

func play_dialogue(lines: Array, callback: Callable) -> void:
	if lines.is_empty():
		callback.call()
		return
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_callback = callback
	dialogue_active = true
	if is_instance_valid(world):
		world.active = false
		world.player.active = false
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = Control.new()
	dialog.theme = theme
	dialog.z_index = 200
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# This full-screen blocker keeps background choices from activating mid-dialogue.
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(dialog)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 800)
	shade.color = Color(0.02, 0.04, 0.04, 0.48)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(shade)
	portraits = preload("res://scripts/dialogue_portraits.gd").new()
	dialog.add_child(portraits)
	UI.terminal_button(dialog,"[ 设置 ]",Rect2(38,47,112,30),toggle_pause)
	UI.terminal_panel(dialog,Rect2(69,523,1142,225),"对话记录 / LIVE TRANSMISSION",true)
	speaker_label = UI.label(dialog,"",Rect2(97,558,750,30),20,UI.TEAL)
	speech_label = UI.label(dialog,"",Rect2(97,601,1087,93),22,UI.INK)
	page_label = UI.label(dialog,"",Rect2(96,705,290,28),15,UI.MUTED)
	var skip := UI.terminal_button(dialog,"[ 跳过本段 ]",Rect2(1035,560,148,34),finish_dialogue)
	skip.name = "SkipDialogue"
	UI.terminal_button(dialog,"[ 继续 > ]",Rect2(1035,704,148,34),next_dialogue)
	update_dialogue()

func update_dialogue() -> void:
	var line: Dictionary = dialogue_lines[dialogue_index]
	var entry: String = str(line.speaker) + "：" + str(line.text)
	if story_history.is_empty() or story_history.back() != entry: story_history.append(entry)
	portraits.show_speaker(line.speaker, is_instance_valid(world))
	speaker_label.text = "// " + str(line.speaker)
	speech_label.text = "> " + str(line.text)
	page_label.text = "%d / %d   ·   Enter / Space 继续" % [dialogue_index+1,dialogue_lines.size()]

func next_dialogue() -> void:
	if not dialogue_active or paused: return
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size(): finish_dialogue()
	else: update_dialogue()

func finish_dialogue() -> void:
	if not dialogue_active or paused: return
	for index in range(dialogue_index+1,dialogue_lines.size()):
		var line: Dictionary = dialogue_lines[index]
		story_history.append(str(line.speaker)+"："+str(line.text))
	dialogue_active = false
	if is_instance_valid(dialog):
		dialog.get_parent().remove_child(dialog)
		dialog.queue_free()
	dialog = null
	if is_instance_valid(world): world.active = true
	var callback := dialogue_callback
	dialogue_callback = Callable()
	if callback.is_valid(): callback.call()

func toggle_pause() -> void:
	if is_instance_valid(world) and world.get("opening") == true: return
	if stage == "title" or stage == "ending" or pending_group >= 0: return
	paused = not paused
	if stage == "intro":
		var terminal := screen.get_node_or_null("IntroTerminal")
		if terminal != null: terminal.playback_paused = paused
	if paused:
		if is_instance_valid(world):
			world.active = false
			world.player.active = false
		pause_layer = preload("res://scripts/game_menu.gd").new()
		pause_layer.app = self
		overlay_layer.add_child(pause_layer)
	else:
		if is_instance_valid(pause_layer):
			pause_layer.get_parent().remove_child(pause_layer)
			pause_layer.queue_free()
		pause_layer = null
		if is_instance_valid(world): world.active = not dialogue_active and not is_instance_valid(archive)

func _process(delta: float) -> void:
	if save_enabled and not restoring and not paused and not dialogue_active and stage in ["bedroom","hallway","cold","meeting"] and checkpoint_stage != stage:
		var saved := Checkpoint.write_save(capture_save(), checkpoint_path)
		if saved: checkpoint_stage = stage

	if stage != "title" and stage != "ending" and not paused: elapsed += delta
	if is_instance_valid(world) and is_instance_valid(hint_label):
		hint_label.text = "WASD 移动 · 靠近后按 E"
		update_top_notice(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if paused: toggle_pause()
		elif pending_group >= 0: cancel_group()
		elif is_instance_valid(archive): close_archive()
		else: toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if paused or pending_group >= 0 or is_instance_valid(archive): return
	if dialogue_active:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			next_dialogue()
			get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_E and is_instance_valid(world):
		world.interact_nearest()
		get_viewport().set_input_as_handled()

func run_smoke_test() -> void:
	var suite = load("res://tests/smoke.gd").new()
	add_child(suite)
	suite.run(self)

func continue_game() -> void:
	var data := latest_save()
	if data.is_empty(): return
	player_name = str(data.get("player_name","未命名"))
	group_id = int(data.group)
	notes = data.notes
	quotes.clear()
	battle = Battle.new()
	meeting_done = false
	persuaded = false
	voted = false
	acquired = data.stage == "meeting"
	paused = false
	set_meta("battle_started",false)
	checkpoint_stage = data.stage
	restoring = true
	if int(data.get("version",1)) == 2:
		restore_snapshot(data)
		restoring = false
		return
	match data.stage:
		"bedroom": enter_bedroom()
		"hallway": enter_hallway()
		"cold": enter_cold(true)
		"meeting": enter_meeting()
	restoring = false

var search_toast: Label
var notice_time := 0.0
var notice_text := ""
var exploration_log := PackedStringArray()
var log_target := ""
var log_count := 0
var log_clock := 0.0
func ensure_top_notice() -> void:
	if not is_instance_valid(search_toast):
		search_toast = UI.label(screen,"",Rect2(48,118,824,56),20,UI.INK)
		search_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		search_toast.add_theme_stylebox_override("normal",UI.box(Color(0.03,0.08,0.08,0.94)))
		search_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		search_toast.z_index = 50
		notice_time = 0.0

func show_search_message(text: String) -> void:
	ensure_top_notice()
	notice_text = text
	for line in text.replace("。","。\n").split("\n",false):
		exploration_log.append("> "+line.strip_edges())
	while exploration_log.size()>2: exploration_log.remove_at(0)
	notice_time = 3.5
	search_toast.show()

func update_top_notice(delta: float) -> void:
	ensure_top_notice()
	if not paused and not dialogue_active and log_count >= log_target.length():
		notice_time = maxf(0.0,notice_time-delta)
	var rows := exploration_log.duplicate()
	if notice_time <= 0 and not world.hint.is_empty():
		if rows.size() >= 2: rows.remove_at(0)
		rows.append("> "+world.hint)
	var next_text := "\n".join(rows)
	if next_text != log_target:
		var common := 0
		while common < mini(log_count,next_text.length()) and common < log_target.length() and next_text[common] == log_target[common]: common += 1
		log_target = next_text
		log_count = common
		log_clock = 0.0
	if not paused and not dialogue_active:
		log_clock += delta
		while log_clock >= 0.035 and log_count < log_target.length():
			log_count += 1
			log_clock -= 0.035
	search_toast.text = log_target.left(log_count) + (" █" if fmod(elapsed,1.0)<0.55 else " ")
	search_toast.visible = not search_toast.text.is_empty() and not dialogue_active and not paused and not is_instance_valid(archive)

func setup_brightness() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	brightness_rect = ColorRect.new()
	brightness_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/brightness.gdshader")
	brightness_rect.material = material
	layer.add_child(brightness_rect)
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK: brightness = float(config.get_value("display","brightness",1.0))
	set_brightness(brightness)

func set_brightness(value: float) -> void:
	brightness = clampf(value,0.7,1.5)
	brightness_rect.material.set_shader_parameter("brightness",brightness)
	if not save_enabled: return
	var config := ConfigFile.new()
	config.set_value("display","brightness",brightness)
	config.save("user://settings.cfg")

func manual_save() -> String:
	if dialogue_active or pending_group >= 0 or stage == "intro" or (is_instance_valid(world) and world.get("opening") == true):
		return "请在这段剧情或动画结束后保存。"
	if not stage in ["bedroom","hallway","cold","meeting","vote"]: return "当前页面无法保存。"
	return "进度已保存。主页的继续游戏会读取最新存档。" if Checkpoint.write_save(capture_save(),checkpoint_path+".manual") else "保存失败，请检查磁盘空间。"

func latest_save() -> Dictionary:
	var automatic := Checkpoint.read_save(checkpoint_path)
	var manual := Checkpoint.read_save(checkpoint_path+".manual")
	return manual if float(manual.get("time",0)) > float(automatic.get("time",0)) else automatic

func capture_save() -> Dictionary:
	var data := {"version":2,"time":Time.get_unix_time_from_system(),"stage":stage,"group":group_id,"notes":notes,"quotes":quotes.duplicate(true),"history":story_history.duplicate(),"acquired":acquired,"meeting_done":meeting_done,"persuaded":persuaded,"battle_started":get_meta("battle_started",false),"hall_intro_seen":hall_intro_seen}
	data.player_name = player_name
	data.battle = {}
	for key in ["round_index","resistance","round_damage","accepted","concept_best","errors"]: data.battle[key] = battle.get(key)
	if is_instance_valid(world):
		data.position = [world.player.position.x,world.player.position.y]
		data.objective = objective_label.text
		if stage == "cold": data.cold = world.capture_state()
	return data

func restore_snapshot(data: Dictionary) -> void:
	player_name = str(data.get("player_name","未命名"))
	hall_intro_seen = bool(data.get("hall_intro_seen",true))
	meeting_done = bool(data.get("meeting_done",false))
	persuaded = bool(data.get("persuaded",false))
	quotes = data.get("quotes",[])
	story_history = data.get("history",[])
	set_meta("battle_started",data.get("battle_started",false))
	for key in data.get("battle",{}):
		if data.battle[key] != null: battle.set(key,data.battle[key])
	match data.stage:
		"bedroom": enter_bedroom()
		"hallway": enter_hallway()
		"cold": enter_cold(false); world.restore_state(data.get("cold",{}))
		"meeting": enter_meeting()
		"vote": enter_vote()
	acquired = bool(data.get("acquired",false))
	if is_instance_valid(world) and data.has("position"):
		world.player.position = Vector2(data.position[0],data.position[1])
		if world.get("camera") != null: world.camera.reset_smoothing()
		set_objective(data.get("objective",objective_label.text))
	if data.stage == "meeting" and meeting_done: open_archive()

func return_to_title() -> void:
	manual_save()
	if paused: toggle_pause()
	dialogue_active = false
	dialogue_callback = Callable()
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = null
	show_title()
