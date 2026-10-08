extends Control
const UI = preload("res://scripts/ui.gd")
var app: Control
var content: TextEdit
var status: Label
var profile_view: Control
var portrait: TextureRect
var profile_title: Label
var profile_info: Label
var selected_character := "heroine"
var profile_buttons: Dictionary = {}
const PROFILES = [{"id": "heroine", "name": "画家（你）", "info": "在家接绘画委托。戴着助听器，醒来后与其他人一起调查极点。"}, {"id": "linshao", "name": "林梢 · 大小姐", "info": "父亲经营公司。说话简短，对自己的家庭不愿多谈。"}, {"id": "shenzhi", "name": "沈知 · 作家", "info": "悬疑小说作家。愿意与人交谈，常用玩笑缓和气氛。"}, {"id": "xiaolu", "name": "小鹿（鹿雯雯）· 女主播", "info": "吃播博主。习惯面对镜头，和大家相处时比较活跃。"}, {"id": "laozhou", "name": "老周", "info": "自称被辞退后待在家中。其他经历仍待调查。"}, {"id": "aye", "name": "阿野（云野）· 男学生", "info": "大学生。说话直接，与晚晚一起等在走廊。"}, {"id": "wanwan", "name": "晚晚（陈晚）· 女学生", "info": "看起来还是学生。待人客气，会关心同伴的情况。"}, {"id": "daixingzhe", "name": "代行者", "info": "戴着面具，负责宣布极点的规则。"}]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = app.theme
	z_index = 300
	UI.panel(self,Rect2(0,0,1280,800),Color(0.01,0.015,0.015,0.99))
	UI.terminal_panel(self,Rect2(28,14,1224,70),"四非 / 系统终端                         SESSION PAUSED",true)
	UI.label(self,"> 设置与记录  /  SYSTEM CONFIG",Rect2(48,49,900,28),20,UI.TEAL)
	UI.terminal_panel(self,Rect2(48,97,314,635),"控制面板 / CONFIG")
	UI.terminal_panel(self,Rect2(405,97,805,635),"档案与记录 / DATABASE",true)
	UI.label(self,"// 画面亮度",Rect2(65,125,240,35),22)
	var brightness := HSlider.new()
	brightness.position = Vector2(65,180)
	brightness.size = Vector2(280,32)
	brightness.min_value = 0.7
	brightness.max_value = 1.5
	brightness.step = 0.05
	brightness.value = app.brightness
	brightness.add_theme_stylebox_override("slider",UI.box(Color("080808"),Color("59726e")))
	brightness.add_theme_stylebox_override("grabber_area",UI.box(UI.TEAL,UI.TEAL))
	brightness.value_changed.connect(app.set_brightness)
	add_child(brightness)
	UI.terminal_button(self,"[ 保存当前进度 ]",Rect2(65,250,280,55),func(): status.text = app.manual_save())
	UI.terminal_button(self,"[ 人物介绍 ]",Rect2(65,325,280,55),show_profiles)
	UI.terminal_button(self,"[ 剧情回顾 ]",Rect2(65,400,280,55),show_history)
	UI.terminal_button(self,"[ 回到主页面 ]",Rect2(65,475,280,55),app.return_to_title)
	UI.terminal_button(self,"[ 返回游戏 > ]",Rect2(65,650,280,60),app.toggle_pause)
	status = UI.label(self,"探索与计时已暂停。\n对话结束后可保存进度。\n可保存时，回主页也会自动保存。",Rect2(65,550,280,85),17,UI.MUTED)
	content = TextEdit.new()
	content.position = Vector2(405,125)
	content.size = Vector2(805,585)
	content.editable = false
	content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_theme_font_size_override("font_size",22)
	content.add_theme_color_override("font_readonly_color",UI.INK)
	content.add_theme_stylebox_override("read_only",UI.box(Color("10161c")))
	content.text = ""
	add_child(content)

	build_profiles()
	show_profiles()

func build_profiles() -> void:
	profile_view = Control.new()
	profile_view.position = Vector2(405,125)
	profile_view.size = Vector2(805,585)
	add_child(profile_view)
	UI.panel(profile_view,Rect2(0,0,805,585))
	UI.label(profile_view,"// 身份档案 / PERSONNEL",Rect2(545,12,240,28),16,UI.TEAL)
	for i in range(PROFILES.size()):
		var entry: Dictionary = PROFILES[i]
		var button := UI.terminal_button(profile_view,entry.name,Rect2(15,15+i*68,235,56),func(): select_profile(entry.id))
		button.add_theme_font_size_override("font_size",17)
		profile_buttons[entry.id] = button
	portrait = TextureRect.new()
	portrait.name = "ProfilePortrait"
	portrait.position = Vector2(265,20)
	portrait.size = Vector2(270,545)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_view.add_child(portrait)
	profile_title = UI.label(profile_view,"",Rect2(545,50,240,85),25,UI.GOLD)
	profile_info = UI.label(profile_view,"",Rect2(545,160,240,370),21)

func show_profiles() -> void:
	content.hide()
	profile_view.show()
	select_profile(selected_character)

func show_history() -> void:
	profile_view.hide()
	content.show()
	content.text = "> " + "\n\n> ".join(app.story_history) if not app.story_history.is_empty() else "// 还没有已读剧情。"
	content.scroll_vertical = 0

func select_profile(id: String) -> void:
	selected_character = id
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits.json"))
	for entry in PROFILES:
		if entry.id != id: continue
		profile_title.text = entry.name.replace(" · ","\n")
		profile_info.text = entry.info
		if id == "laozhou" and app.meeting_done:
			profile_title.text = "老周 · 律师"
			profile_info.text = "曾代理林梢父亲公司的工地赔偿案。林梢已当面指认他的身份；他否认相关行为，并指责画家引导众人针对自己。"
		if id == "daixingzhe":
			var texture := AtlasTexture.new()
			texture.atlas = load("res://assets/characters/daixingzhe.png")
			texture.region = Rect2(192,0,64,64)
			portrait.texture = texture
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			portrait.texture = load(definitions[id].texture)
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for key in profile_buttons:
		profile_buttons[key].add_theme_color_override("font_color",UI.TEAL if key == id else UI.INK)
